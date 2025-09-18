import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/firebase_config.dart';
import 'notification_service.dart';

class ESP32Service with ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final String userId;
  final NotificationService notificationService;
  
  late DatabaseReference _sensorDataRef;
  late StreamSubscription<DatabaseEvent> _sensorDataSubscription;
  
  // Current sensor values
  double _temperature = 0.0;
  double _humidity = 0.0;
  double _gasLevel = 0.0;
  double _weight = 0.0;
  bool _isConnected = false;
  DateTime? _lastUpdateTime;
  String? _lastError;
  
  // Thresholds for notifications
  static const double _highTempThreshold = 35.0; // °C
  static const double _lowTempThreshold = 10.0;  // °C
  static const double _highHumidityThreshold = 80.0; // %
  static const double _highGasThreshold = 1000.0; // PPM
  
  // Cooldown period to prevent notification spam (1 hour)
  static const Duration _notificationCooldown = Duration(hours: 1);
  
  // Track last notification time for each alert type
  final Map<String, DateTime> _lastNotificationTimes = {};
  
  // Getters
  double get temperature => _temperature;
  double get humidity => _humidity;
  double get gasLevel => _gasLevel;
  double get weight => _weight;
  bool get isConnected => _isConnected;
  DateTime? get lastUpdateTime => _lastUpdateTime;
  String? get lastError => _lastError;
  
  // Stream controllers for real-time updates
  final _sensorDataController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Get sensor data stream
  Stream<Map<String, dynamic>> get getSensorDataStream => _sensorDataController.stream;
  Stream<Map<String, dynamic>> get sensorDataStream => _sensorDataController.stream;
  
  ESP32Service({
    required this.userId,
    required this.notificationService,
  }) {
    _sensorDataRef = _database.child('${FirebaseConfig.getSensorDataPath(userId)}/latest');
  }
  
  // Initialize the service
  Future<void> initialize() async {
    try {
      await _loadLastKnownState();
      _setupRealtimeUpdates();
      await _checkConnectionStatus();
      debugPrint('ESP32Service initialized for user: $userId');
    } catch (e) {
      _lastError = 'Initialization failed: $e';
      debugPrint('Error initializing ESP32Service: $e');
      rethrow;
    }
  }
  
  // Set up real-time updates from Firebase
  void _setupRealtimeUpdates() {
    _sensorDataSubscription = _sensorDataRef.onValue.listen(
      (event) => _handleSensorDataUpdate(event),
      onError: (error) {
        _lastError = 'Sensor data error: $error';
        _isConnected = false;
        notifyListeners();
        debugPrint('Error in sensor data stream: $error');
      },
    );
  }
  
  // Handle incoming sensor data updates
  void _handleSensorDataUpdate(DatabaseEvent event) {
    try {
      if (event.snapshot.value == null) {
        _isConnected = false;
        _lastError = 'No sensor data available';
        notifyListeners();
        return;
      }
      
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      
      // Update sensor values
      _temperature = _parseDouble(data['temperature']) ?? _temperature;
      _humidity = _parseDouble(data['humidity']) ?? _humidity;
      _gasLevel = _parseDouble(data['gas']) ?? _gasLevel;
      _weight = _parseDouble(data['weight']) ?? _weight;
      _isConnected = true;
      _lastUpdateTime = DateTime.now();
      _lastError = null;
      
      // Broadcast update to stream
      _sensorDataController.add({
        'temperature': _temperature,
        'humidity': _humidity,
        'gas': _gasLevel,
        'weight': _weight,
        'timestamp': _lastUpdateTime!.millisecondsSinceEpoch,
      });
      
      // Check for threshold alerts
      _checkThresholds();
      
      notifyListeners();
    } catch (e) {
      _lastError = 'Error processing sensor data: $e';
      debugPrint('Error in _handleSensorDataUpdate: $e');
      notifyListeners();
    }
  }
  
  // Check sensor values against thresholds and trigger notifications (KEEP ONLY THIS ONE)
  void _checkThresholds() {
    final now = DateTime.now();
    
    // Temperature checks
    if (_temperature > _highTempThreshold) {
      _maybeSendNotification(
        type: 'high_temperature',
        title: '🌡️ High Temperature Alert',
        body: 'Temperature is high: ${_temperature.toStringAsFixed(1)}°C',
        lastNotificationTime: _lastNotificationTimes['high_temperature'],
        now: now,
      );
    } else if (_temperature < _lowTempThreshold) {
      _maybeSendNotification(
        type: 'low_temperature',
        title: '❄️ Low Temperature Alert',
        body: 'Temperature is low: ${_temperature.toStringAsFixed(1)}°C',
        lastNotificationTime: _lastNotificationTimes['low_temperature'],
        now: now,
      );
    }
    
    // Humidity check
    if (_humidity > _highHumidityThreshold) {
      _maybeSendNotification(
        type: 'high_humidity',
        title: '💧 High Humidity Alert',
        body: 'Humidity is high: ${_humidity.toStringAsFixed(1)}%',
        lastNotificationTime: _lastNotificationTimes['high_humidity'],
        now: now,
      );
    }
    
    // Gas level check
    if (_gasLevel > _highGasThreshold) {
      _maybeSendNotification(
        type: 'high_gas',
        title: '⚠️ Gas Leak Detected!',
        body: 'Dangerous gas level: ${_gasLevel.toStringAsFixed(0)} PPM',
        lastNotificationTime: _lastNotificationTimes['high_gas'],
        now: now,
        isCritical: true,
      );
    }
  }
  
  // Send notification if cooldown period has passed (KEEP ONLY THIS ONE)
  void _maybeSendNotification({
    required String type,
    required String title,
    required String body,
    required DateTime? lastNotificationTime,
    required DateTime now,
    bool isCritical = false,
  }) {
    // Skip if we've sent a notification recently for this alert type
    if (lastNotificationTime != null && 
        now.difference(lastNotificationTime) < _notificationCooldown) {
      return;
    }
    
    // Update last notification time
    _lastNotificationTimes[type] = now;
    
    // Send notification
    notificationService.showNotification(
      title: title,
      body: body,
      payload: 'sensor_alert:$type',
      isCritical: isCritical,
    );
  }
  
  // Helper to parse double values from various types
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  // Load last known state from local storage
  Future<void> _loadLastKnownState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Load any persisted state if needed
    } catch (e) {
      debugPrint('Error loading last known state: $e');
    }
  }
  
  // Check device connection status
  Future<void> _checkConnectionStatus() async {
    try {
      final snapshot = await _sensorDataRef.once();
      _isConnected = snapshot.snapshot.value != null;
      notifyListeners();
    } catch (e) {
      _isConnected = false;
      _lastError = 'Connection check failed: $e';
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _sensorDataSubscription.cancel();
    _sensorDataController.close();
    super.dispose();
  }
  
  // Get current sensor data
  Future<Map<String, dynamic>> getSensorData() async {
    final snapshot = await _sensorDataRef.get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return {};
  }
}
