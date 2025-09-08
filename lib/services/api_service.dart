import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';

class ApiService {
  // Update this with your ESP32's IP address and port
  static const String baseUrl = 'http://YOUR_ESP32_IP';
  static const String apiPath = '/update';
  
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
