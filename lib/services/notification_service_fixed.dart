import 'dart:async';
import 'dart:io';

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
  final int _maxNotifications = 100; // Maximum number of notifications to store

  // Getters
  bool get isInitialized => _isInitialized;
  bool get notificationsEnabled => _notificationsEnabled;
  String? get fcmToken => _fcmToken;
  List<Map<String, dynamic>> get notifications => List.unmodifiable(_notifications);

  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

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

  // Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
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
          // Handle notification tap
          _onNotificationTap(response);
        },
      );
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
      rethrow;
    }
  }

  // Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    try {
      debugPrint('Notification tapped: ${response.payload}');

      // Extract payload data
      final payload = response.payload;
      if (payload != null) {
        // Handle different types of notification payloads
        if (payload.startsWith('sensor_alert:')) {
          final alertType = payload.replaceFirst('sensor_alert:', '');
          debugPrint('Sensor alert tapped: $alertType');
          // You can add navigation logic here based on the alert type
        } else if (payload.startsWith('notification_')) {
          final notificationId = payload.replaceFirst('notification_', '');
          markAsRead(notificationId);
        }
      }

      // Notify listeners that a notification was tapped
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  // Create notification channel for Android 8.0+
  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
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
    }
  }

  // Request notification permissions
  Future<bool> _requestPermissions() async {
    try {
      if (Platform.isIOS) {
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
      } else if (Platform.isAndroid) {
        // Android does not require explicit requestPermission call for notifications here
        _notificationsEnabled = true; // Assume enabled on Android by default or implement Android 13+ permission if needed
        notifyListeners();
        return _notificationsEnabled;
      }

      return false;
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
      _fcmToken = await _firebaseMessaging.getToken();
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
          _showLocalNotification(
            message.notification?.title ?? 'New Notification',
            message.notification?.body ?? '',
            message.data,
            payload: message.data.toString(),
          );
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
        _showLocalNotification(
          notification.title ?? 'New Notification',
          notification.body ?? '',
          data,
          payload: data.toString(),
        );

        if (wasTapped) {
          // Handle navigation when notification is tapped
          // You can add your navigation logic here
          debugPrint('Notification tapped with data: $data');
        }
      }
    } catch (e) {
      debugPrint('Error handling incoming message: $e');
    }
  }

  // Add notification to the list and save to storage
  void _addNotification(Map<String, dynamic> notification) {
    _notifications.insert(0, notification);

    // Limit the number of notifications stored
    if (_notifications.length > _maxNotifications) {
      _notifications.removeLast();
    }

    // Save to local storage
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
          // Parse the notification string back to a map
          // This is a simplified version - you might need a more robust parsing solution
          final notification = {
            'raw': n,
            'read': true, // Mark as read by default when loading
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

  // Show a local notification
  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data, {
    String? payload,
  }) async {
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
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // Notification ID
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

  // Show a scheduled notification
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, dynamic>? data,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        scheduledDate.millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload ?? data?.toString(),
      );

      debugPrint('Scheduled notification: $title at $scheduledDate');

    } catch (e) {
      debugPrint('Error scheduling notification: $e');
      rethrow;
    }
  }

  // Cancel a notification by ID
  Future<void> cancelNotification(int notificationId) async {
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Get the current FCM token
  Future<String?> getFCMToken() async {
    try {
      if (_fcmToken == null) {
        _fcmToken = await _firebaseMessaging.getToken();
      }
      return _fcmToken;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  // Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
      rethrow;
    }
  }

  // Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
      rethrow;
    }
  }

  // Update token on server (implement this according to your backend)
  Future<void> _updateTokenOnServer(String token) async {
    // Implement your token update logic here
    // This is where you would send the token to your server
    debugPrint('Updating token on server: $token');
    // Example:
    // await _apiService.updateFCMToken(token);
  }

  // Request permission for notifications
  Future<bool> requestNotificationPermission() async {
    try {
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

      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', _notificationsEnabled);

      return _notificationsEnabled;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      _notificationsEnabled = false;
      notifyListeners();
      return false;
    }
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isIOS) {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } else if (Platform.isAndroid) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('notifications_enabled') ?? true;
    }
    return false;
  }

  // Toggle notifications on/off
  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);

    // If enabling, request permissions
    if (enabled) {
      await requestNotificationPermission();
    }

    notifyListeners();
  }

  // Get the initial notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    return await _firebaseMessaging.getNotificationSettings();
  }

  // Request permission for iOS critical alerts
  Future<bool> requestCriticalAlertPermission() async {
    if (Platform.isIOS) {
      try {
        final settings = await _firebaseMessaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: true, // Request critical alert permission
          provisional: false,
          sound: true,
        );

        return settings.authorizationStatus == AuthorizationStatus.authorized &&
            settings.criticalAlert == AppleNotificationSetting.enabled;
      } catch (e) {
        debugPrint('Error requesting critical alert permission: $e');
        return false;
      }
    }
    return false;
  }
}
