class SensorData {
  final double temperature;
  final double humidity;
  final double weight;
  final String prediction;
  final bool alert;
  final DateTime timestamp;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.weight,
    required this.prediction,
    required this.alert,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      prediction: json['prediction'] as String,
      alert: json['alert'] as bool,
    );
  }

  SensorData copyWith({
    double? temperature,
    double? humidity,
    double? weight,
    String? prediction,
    bool? alert,
    DateTime? timestamp,
  }) {
    return SensorData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      weight: weight ?? this.weight,
      prediction: prediction ?? this.prediction,
      alert: alert ?? this.alert,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
