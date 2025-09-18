import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sensor_data.dart';

enum DatabaseStatus {
  connected,
  disconnected,
  error,
  loading,
}

class FirebaseService extends ChangeNotifier {
  late DatabaseReference _database;
  StreamSubscription<DatabaseEvent>? _dataSubscription;
  
  DatabaseStatus _status = DatabaseStatus.disconnected;
  SensorData? _latestData;
  String? _error;

  // Getters
  DatabaseStatus get status => _status;
  SensorData? get latestData => _latestData;
  String? get error => _error;
  static const _prefsKeyActiveGsm = 'active_gsm';
  String? _activeGsm;
  String? get activeGsm => _activeGsm;
  DatabaseReference? get _gsmRef =>
      (_activeGsm == null) ? null : _database.child('sensor_data').child(_activeGsm!).child('latest');

  // Initialize the service
  Future<void> initialize() async {
    try {
      _database = FirebaseDatabase.instance.ref();
      _status = DatabaseStatus.loading;
      // Load last selected GSM
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKeyActiveGsm);
      if (saved != null && saved.isNotEmpty) {
        _activeGsm = saved;
      }
      _subscribeToDataChanges();
    } catch (e) {
      _status = DatabaseStatus.error;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Parse sensor data from Firebase
  SensorData _parseSensorData(Map<dynamic, dynamic> data) {
    return SensorData(
      temperature: (data['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (data['humidity'] as num?)?.toDouble() ?? 0.0,
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
      prediction: data['prediction']?.toString() ?? 'unknown',
      timestamp: data['timestamp'] != null
          ? DateTime.tryParse(data['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      alert: data['alert'] == true,
    );
  }

  // Subscribe to data changes
  void _subscribeToDataChanges() {
    _dataSubscription?.cancel();
    final ref = _gsmRef;
    if (ref == null) {
      _status = DatabaseStatus.disconnected;
      notifyListeners();
      return;
    }

    _dataSubscription = ref.onValue.listen(
          (event) {
            try {
              if (event.snapshot.value != null) {
                final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
                _latestData = _parseSensorData(data);
                _status = DatabaseStatus.connected;
                _error = null;
                notifyListeners();
              }
            } catch (e) {
              _status = DatabaseStatus.error;
              _error = 'Error parsing sensor data: $e';
              notifyListeners();
            }
          },
          onError: (error) {
            _status = DatabaseStatus.error;
            _error = 'Error: $error';
            notifyListeners();
          },
        );
  }

  // Add new sensor data to Firebase
  Future<void> addSensorData(SensorData data) async {
    try {
      final ref = _gsmRef;
      if (ref == null) throw Exception('No active GSM selected');
      await ref.set({
        'temperature': data.temperature,
        'humidity': data.humidity,
        'weight': data.weight,
        'prediction': data.prediction,
        'timestamp': data.timestamp.toIso8601String(),
        'alert': data.alert,
      });
    } catch (e) {
      _status = DatabaseStatus.error;
      _error = 'Failed to save data: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Get stream of sensor data
  Stream<SensorData> getSensorDataStream() {
    final ref = _gsmRef;
    if (ref == null) {
      return const Stream.empty();
    }
    return ref.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        throw Exception('No data available');
      }
      return _parseSensorData(data);
    });
  }

  // Handle errors
  void _handleError(dynamic error) {
    _status = DatabaseStatus.error;
    _error = error.toString();
    notifyListeners();
    Future.delayed(const Duration(seconds: 5), _subscribeToDataChanges);
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  Future<void> setActiveGsm(String gsm) async {
    _activeGsm = gsm.replaceAll(RegExp(r'\D'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyActiveGsm, _activeGsm!);
    _subscribeToDataChanges();
    notifyListeners();
  }
}