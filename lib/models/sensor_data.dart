// lib/models/sensor_data.dart
class SensorData {
  final double temperature;
  final double humidity;
  final double weight;
  final String prediction;
  final DateTime timestamp;
  final bool alert;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.weight,
    required this.prediction,
    required this.timestamp,
    required this.alert,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    DateTime _toDate(dynamic v) {
      if (v is DateTime) return v;
      if (v is int) {
        // support epoch ms or s
        return DateTime.fromMillisecondsSinceEpoch(v > 2000000000 ? v : v * 1000);
      }
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return SensorData(
      temperature: _toDouble(json['temperature']),
      humidity: _toDouble(json['humidity']),
      weight: _toDouble(json['weight']),
      prediction: (json['prediction'] ?? 'unknown').toString(),
      timestamp: _toDate(json['timestamp']),
      alert: json['alert'] == true || json['alert'] == 1 || json['alert'] == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'weight': weight,
      'prediction': prediction,
      'timestamp': timestamp.toIso8601String(),
      'alert': alert,
    };
  }
}