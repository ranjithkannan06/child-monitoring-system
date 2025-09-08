import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';

class FirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  // Reference to the 'car_monitoring' node in the database
  DatabaseReference get carMonitoringRef => _database.child('car_monitoring');
  
  // Get a stream of sensor data updates
  Stream<DatabaseEvent> getSensorDataStream() {
    return carMonitoringRef.limitToLast(1).onValue;
  }
  
  // Convert database snapshot to SensorData model
  SensorData? parseSensorData(DataSnapshot snapshot) {
    try {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      
      return SensorData(
        temperature: (data['temperature'] as num?)?.toDouble() ?? 0.0,
        humidity: (data['humidity'] as num?)?.toDouble() ?? 0.0,
        weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
        prediction: data['ai_result']?.toString() ?? 'no_child',
        alert: data['alert'] == true,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          (data['timestamp'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } catch (e) {
      print('Error parsing sensor data: $e');
      return null;
    }
  }
  
  // Get the latest sensor data
  Future<SensorData?> getLatestSensorData() async {
    try {
      final snapshot = await carMonitoringRef.limitToLast(1).get();
      
      if (snapshot.exists) {
        // Get the first (and only) child
        final data = snapshot.children.first;
        return parseSensorData(data);
      }
      return null;
    } catch (e) {
      print('Error getting latest sensor data: $e');
      return null;
    }
  }
}
