import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';
import '../config/env_config.dart';

class ApiService {
  // ESP32 configuration from environment variables
  static String get baseUrl => EnvConfig.esp32BaseUrl;
  static String get apiPath => EnvConfig.esp32ApiPath;
  
  final http.Client _client = http.Client();
  
  Future<SensorData> fetchSensorData() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl$apiPath'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return SensorData.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load sensor data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching sensor data: $e');
    }
  }
  
  // Close the HTTP client when done
  void dispose() {
    _client.close();
  }
}
