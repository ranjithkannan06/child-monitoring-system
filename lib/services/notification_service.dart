import 'dart:async';
// Remove: import 'dart:io'; // This causes web crashes
import 'package:flutter/foundation.dart' show kIsWeb; // Add this

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/firebase_config.dart';

class NotificationService with ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Notification channels
  static const String _channelId = 'high_importance_channel';
  static const String _channelName = 'High Importance Notifications';
  static const String _channelDescription = 'This channel is used for important notifications from the Child Safety Monitor app.';

  // Notification settings
  bool _isInitialized = false;
  bool _notificationsEnabled = true;
  String? _fcmToken;
  final List<Map<String, dynamic>> _notifications = [];
  final int _maxNotifications = 100;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get notificationsEnabled => _notificationsEnabled;
  String? get fcmToken => _fcmToken;
  List<Map<String, dynamic>> get notifications => List.unmodifiable(_notifications);

  // Platform detection helpers
  bool get isWeb => kIsWeb;
  bool get isMobile => !kIsWeb;

  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications (only for mobile)
      if (!isWeb) {
        await _initializeLocalNotifications();
      }
      
      // Request permissions and configure FCM
      await _requestPermissions();
      await _configureFirebaseMessaging();
      
      // Load saved notifications
      await _loadNotifications();
      
      _isInitialized = true;
      notifyListeners();
      
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
      rethrow;
    }
  }

  // Initialize local notifications plugin (Mobile only)
  Future<void> _initializeLocalNotifications() async {
    if (isWeb) return; // Skip for web
    
    try {
      // Initialize timezone data
      tz.initializeTimeZones();
      
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: DarwinInitializationSettings(),
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _onNotificationTap(response);
        },
      );

      // Create notification channel for Android (only if not web)
      await _createNotificationChannel();
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
      rethrow;
    }
  }
  
  // Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    try {
      debugPrint('Notification tapped: ${response.payload}');
      
      final payload = response.payload;
      if (payload != null) {
        if (payload.startsWith('sensor_alert:')) {
          final alertType = payload.replaceFirst('sensor_alert:', '');
          debugPrint('Sensor alert tapped: $alertType');
        } else if (payload.startsWith('notification_')) {
          final notificationId = payload.replaceFirst('notification_', '');
          markAsRead(notificationId);
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }
  
  // Create notification channel for Android 8.0+ (Mobile only)
  Future<void> _createNotificationChannel() async {
    if (isWeb) return; // Skip for web
    
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint('Error creating notification channel: $e');
    }
  }
  
  // Request notification permissions - WEB COMPATIBLE VERSION
  Future<bool> _requestPermissions() async {
    try {
      if (isWeb) {
        // For web, use FCM permissions directly
        final settings = await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        
        _notificationsEnabled = settings.authorizationStatus == AuthorizationStatus.authorized;
        notifyListeners();
        return _notificationsEnabled;
      } else {
        // For mobile platforms
        final settings = await _firebaseMessaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        
        _notificationsEnabled = settings.authorizationStatus == AuthorizationStatus.authorized;
        notifyListeners();
        return _notificationsEnabled;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      _notificationsEnabled = false;
      notifyListeners();
      return false;
    }
  }
  
  // Configure Firebase Messaging
  Future<void> _configureFirebaseMessaging() async {
    try {
      // Request FCM token
      if (isWeb) {
        // For web, you might need to provide VAPID key
        _fcmToken = await _firebaseMessaging.getToken(
          // vapidKey: "YOUR_VAPID_KEY_HERE", // Uncomment and add your VAPID key
        );
      } else {
        _fcmToken = await _firebaseMessaging.getToken();
      }
      
      debugPrint('FCM Token: $_fcmToken');
      
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
        _updateTokenOnServer(newToken);
      });
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
          
          if (isWeb) {
            // For web, show browser notification
            _showWebNotification(
              message.notification?.title ?? 'New Notification',
              message.notification?.body ?? '',
              message.data,
            );
          } else {
            // For mobile, use local notifications
            _showLocalNotification(
              message.notification?.title ?? 'New Notification',
              message.notification?.body ?? '',
              message.data,
              payload: message.data.toString(),
            );
          }
        }
      });
      
      // Handle when the app is in the background but opened from a notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        _handleIncomingMessage(message, wasTapped: true);
      });
      
      // Get any messages which caused the application to open from a terminated state
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleIncomingMessage(initialMessage, wasTapped: true);
      }
      
    } catch (e) {
      debugPrint('Error configuring Firebase Messaging: $e');
      rethrow;
    }
  }
  
  // Handle incoming message
  void _handleIncomingMessage(RemoteMessage message, {bool wasTapped = false}) {
    try {
      final notification = message.notification;
      final data = message.data;
      
      if (notification != null) {
        if (isWeb) {
          _showWebNotification(
            notification.title ?? 'New Notification',
            notification.body ?? '',
            data,
          );
        } else {
          _showLocalNotification(
            notification.title ?? 'New Notification',
            notification.body ?? '',
            data,
            payload: data.toString(),
          );
        }
        
        if (wasTapped) {
          debugPrint('Notification tapped with data: $data');
        }
      }
    } catch (e) {
      debugPrint('Error handling incoming message: $e');
    }
  }
  
  // ADD THIS METHOD - This was missing and causing the error
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    bool isCritical = false,
  }) async {
    try {
      if (isWeb) {
        await _showWebNotification(title, body, {});
      } else {
        await _showLocalNotification(title, body, {}, payload: payload);
      }
    } catch (e) {
      debugPrint('Error in showNotification: $e');
    }
  }
  
  // Show web notification (for web platform)
  Future<void> _showWebNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      // Add to notifications list
      _addNotification({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'body': body,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      });
      
      debugPrint('Web notification shown: $title - $body');
      // Note: Actual web notifications are handled by Firebase FCM automatically
      
    } catch (e) {
      debugPrint('Error showing web notification: $e');
    }
  }
  
  // Show a local notification (Mobile only)
  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data, {
    String? payload,
  }) async {
    if (isWeb) return; // Skip for web
    
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );
      
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );
      
      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformChannelSpecifics,
        payload: payload ?? data.toString(),
      );
      
      // Add to notifications list
      _addNotification({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'body': body,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      });
      
      debugPrint('Local notification shown: $title - $body');
      
    } catch (e) {
      debugPrint('Error showing local notification: $e');
      rethrow;
    }
  }

  // Add notification to the list and save to storage
  void _addNotification(Map<String, dynamic> notification) {
    _notifications.insert(0, notification);
    
    if (_notifications.length > _maxNotifications) {
      _notifications.removeLast();
    }
    
    _saveNotifications();
    notifyListeners();
  }
  
  // Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n['id'] == notificationId);
    if (index != -1) {
      _notifications[index]['read'] = true;
      _saveNotifications();
      notifyListeners();
    }
  }
  
  // Mark all notifications as read
  void markAllAsRead() {
    for (var notification in _notifications) {
      notification['read'] = true;
    }
    _saveNotifications();
    notifyListeners();
  }
  
  // Clear all notifications
  void clearAll() {
    _notifications.clear();
    _saveNotifications();
    notifyListeners();
  }
  
  // Save notifications to shared preferences
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'notifications',
        _notifications.map((n) => n.toString()).toList(),
      );
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }
  
  // Load notifications from shared preferences
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList('notifications') ?? [];
      
      _notifications.clear();
      for (var n in notifications) {
        try {
          final notification = {
            'raw': n,
            'read': true,
          };
          _notifications.add(notification);
        } catch (e) {
          debugPrint('Error parsing notification: $e');
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }
  
  // Update token on server
  Future<void> _updateTokenOnServer(String token) async {
    debugPrint('Updating token on server: $token');
  }
  
  // Get FCM Token
  Future<String?> getFCMToken() async {
    try {
      if (_fcmToken == null) {
        if (isWeb) {
          _fcmToken = await _firebaseMessaging.getToken();
        } else {
          _fcmToken = await _firebaseMessaging.getToken();
        }
      }
      return _fcmToken;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }
  
  // Request notification permission
  Future<bool> requestNotificationPermission() async {
    return await _requestPermissions();
  }
  
  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
      rethrow;
    }
  }
  
  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
      rethrow;
    }
  }
}
