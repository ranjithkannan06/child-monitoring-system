import 'dart:async';
import 'package:flutter/foundation.dart' show ChangeNotifier, kIsWeb, debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';

// Enum to handle different auth states
enum AuthStatus {
  uninitialized,
  authenticated,
  authenticating,
  unauthenticated,
  verifyPhoneNumber,
  codeSent,
  codeAutoRetrievalTimeout,
  verificationFailed,
  error,
}

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? EnvConfig.googleSignInClientId : null,
    scopes: ['email', 'profile'],
    signInOption: kIsWeb ? SignInOption.standard : SignInOption.standard,
  );
  
  // User state
  User? _user;
  String? _verificationId;
  int? _resendToken;
  AuthStatus _status = AuthStatus.uninitialized;
  String? _email;
  String? _displayName;
  String? _photoUrl;
  String? _accessToken;
  String? _idToken;
  
  // Add SharedPreferences import at the top if not already present

  // Getters
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  AuthStatus get status => _status;
  String? get verificationId => _verificationId;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get email => _email;
  String? get displayName => _displayName;
  String? get photoUrl => _photoUrl;
  String? get accessToken => _accessToken;
  String? get idToken => _idToken;

  AuthService() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    // Check if user is already signed in
    _user = _auth.currentUser;
    if (_user != null) {
      _status = AuthStatus.authenticated;
      await _updateUserData();
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();

    // Listen to auth state changes
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
      _email = null;
      _displayName = null;
      _photoUrl = null;
      await _clearAuthData();
    } else {
      _user = user;
      _email = user.email;
      _displayName = user.displayName;
      _photoUrl = user.photoURL;
      _status = AuthStatus.authenticated;
      await _saveAuthData();
    }
    notifyListeners();
  }

  Future<void> _saveAuthData() async {
    if (_user == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', _user!.uid);
    await prefs.setString('email', _email ?? '');
    await prefs.setString('display_name', _displayName ?? '');
    await prefs.setString('photo_url', _photoUrl ?? '');
    await prefs.setString('access_token', _accessToken ?? '');
    await prefs.setString('id_token', _idToken ?? '');
  }

  Future<void> _saveUserToDatabase() async {
    if (_user == null) return;
    
    try {
      await _db.child('users').child(_user!.uid).set({
        'uid': _user!.uid,
        'email': _email ?? _user!.email,
        'displayName': _displayName ?? _user!.displayName ?? 'User',
        'photoURL': _photoUrl ?? _user!.photoURL ?? '',
        'createdAt': DateTime.now().toIso8601String(),
        'lastLoginAt': DateTime.now().toIso8601String(),
        'provider': _user!.providerData.isNotEmpty ? _user!.providerData.first.providerId : 'email',
      });
      debugPrint('User data saved to database: ${_user!.uid}');
    } catch (e) {
      debugPrint('Error saving user to database: $e');
    }
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('email');
    await prefs.remove('display_name');
    await prefs.remove('photo_url');
    await prefs.remove('access_token');
    await prefs.remove('id_token');
  }

  Future<void> _updateUserData() async {
    if (_user == null) return;
    
    _email = _user!.email;
    _displayName = _user!.displayName;
    _photoUrl = _user!.photoURL;
    
    // Get ID token
    try {
      _idToken = await _user!.getIdToken();
    } catch (e) {
      debugPrint('Error getting ID token: $e');
    }
    
    // For Google Sign-In, we can get the access token
    if (_user!.providerData.any((userInfo) => userInfo.providerId == 'google.com')) {
      try {
        final googleAuth = await _user!.getIdToken();
        _accessToken = googleAuth;
      } catch (e) {
        debugPrint('Error getting Google access token: $e');
      }
    }
    
    await _saveAuthData();
  }

  // Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      _status = AuthStatus.authenticating;
      notifyListeners();
      
      // For web, we'll handle the auth flow through the button click
      if (kIsWeb) {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
        if (googleUser == null) {
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          return null;
        }
      }

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      await _ensureUserProfile();
      await _updateUserData();
      _status = AuthStatus.authenticated;
      notifyListeners();
      
      return userCredential;
    } catch (e) {
      _status = AuthStatus.error;
      notifyListeners();
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  // Phone Number Authentication
  Future<void> verifyPhoneNumber(String phoneNumber) async {
    try {
      _status = AuthStatus.verifyPhoneNumber;
      notifyListeners();

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          _status = AuthStatus.authenticated;
          notifyListeners();
        },
        verificationFailed: (FirebaseAuthException e) {
          _status = AuthStatus.verificationFailed;
          notifyListeners();
          debugPrint('Phone verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _status = AuthStatus.codeSent;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          _status = AuthStatus.codeAutoRetrievalTimeout;
          notifyListeners();
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      _status = AuthStatus.error;
      notifyListeners();
      debugPrint('Phone verification error: $e');
      rethrow;
    }
  }

  // Verify SMS code
  Future<UserCredential?> verifySMSCode(String smsCode) async {
    try {
      if (_verificationId == null) {
        throw Exception('No verification ID available');
      }
      
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      await _ensureUserProfile();
      _status = AuthStatus.authenticated;
      notifyListeners();
      
      return userCredential;
    } catch (e) {
      _status = AuthStatus.error;
      notifyListeners();
      debugPrint('SMS verification error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _verificationId = null;
      _resendToken = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      notifyListeners();
      debugPrint('Error during sign out: $e');
      rethrow;
    }
  }

  Future<void> _ensureUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final userRef = _db.child('users').child(user.uid);
    final snap = await userRef.get();
    if (!snap.exists) {
      await userRef.update({
        'displayName': user.displayName,
        'email': user.email,
        'photoURL': user.photoURL,
        'createdAt': ServerValue.timestamp,
      });
    }
  }

  Future<List<String>> getUserGsms() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final snap = await _db.child('users').child(user.uid).child('gsms').get();
    if (!snap.exists || snap.value == null) return [];
    final map = Map<String, dynamic>.from(snap.value as Map);
    return map.entries.where((e) => e.value == true).map((e) => e.key).toList()..sort();
  }

  Future<void> addGsm(String gsm) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');
    await _db.child('users').child(user.uid).child('gsms').child(_normalizeGsm(gsm)).set(true);
  }

  Future<void> removeGsm(String gsm) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');
    await _db.child('users').child(user.uid).child('gsms').child(_normalizeGsm(gsm)).remove();
  }

  String _normalizeGsm(String gsm) {
    // Keep digits only; you can adapt to allow +country
    return gsm.replaceAll(RegExp(r'\D'), '');
  }

  // Email/Password Sign-Up method
  Future<void> signUpWithEmail(String email, String password, String displayName) async {
    try {
      _status = AuthStatus.authenticating;
      notifyListeners();

      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;
      _email = _user?.email;
      _displayName = displayName;

      if (_user != null) {
        // Update display name
        await _user!.updateDisplayName(displayName);
        
        // Save user to database
        await _saveUserToDatabase();
        
        _status = AuthStatus.authenticated;
        debugPrint('Email Sign-Up successful: ${_user!.email}');
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('Email Sign-Up error: $e');
      _status = AuthStatus.error;
      rethrow; // Re-throw to handle in UI
    } finally {
      notifyListeners();
    }
  }

  // Email/Password Sign-In method
  Future<void> signInWithEmail(String email, String password) async {
    try {
      _status = AuthStatus.authenticating;
      notifyListeners();

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;
      _email = _user?.email;
      _displayName = _user?.displayName;
      _photoUrl = _user?.photoURL;

      if (_user != null) {
        await _saveUserToDatabase();
        _status = AuthStatus.authenticated;
        debugPrint('Email Sign-In successful: ${_user!.email}');
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('Email Sign-In error: $e');
      _status = AuthStatus.error;
      rethrow; // Re-throw to handle in UI
    } finally {
      notifyListeners();
    }
  }

  // Password Reset method
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent to: $email');
    } catch (e) {
      debugPrint('Password reset error: $e');
      rethrow; // Re-throw to handle in UI
    }
  }
}
