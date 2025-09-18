import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'welcome_screen.dart';
import 'sign_in_screen.dart';
import '../home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    // Debug output
    print('AuthWrapper: status=${authService.status}, user=${user?.uid}');

    // Show loading screen while checking auth state
    if (authService.status == AuthStatus.authenticating ||
        authService.status == AuthStatus.uninitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If user is logged in, show home screen
    if (user != null) {
      return const HomeScreen();
    }

    // Otherwise, show welcome screen directly
    return const WelcomeScreen();
  }
}
