class AppConfig {
  // WiFi Configuration
  static const String wifiSSID = 'Redmi note 13 pro';
  static const String wifiPassword = 'your_wifi_password';
  
  // Firebase Configuration (for Flutter app)
  static const String firebaseWebApiKey = 'your_firebase_web_api_key';
  static const String firebaseDatabaseUrl = 'your_firebase_database_url';
  static const String firebaseProjectId = 'your_firebase_project_id';
  static const String firebaseMessagingSenderId = 'your_firebase_sender_id';
  static const String firebaseAppId = 'your_firebase_app_id';
  
  // Roboflow Configuration
  static const String roboflowApiKey = 'your_roboflow_api_key';
  static const String roboflowModelUrl = 'https://detect.roboflow.com/child-monitoring/1';
  
  // Server API Endpoint
  static const String serverApiUrl = 'https://your-server.com/update';
  
  // GSM Configuration
  static const int gsmRxPin = 16;
  static const int gsmTxPin = 17;
  
  // Other Hardware Pins
  static const int dhtPin = 4;      // Example DHT sensor pin
  static const int loadCellDoutPin = 5;
  static const int loadCellSckPin = 18;
  
  // Calibration factor for load cell (adjust based on your calibration)
  static const double loadCellCalibrationFactor = 1.0;
  
  // Threshold values for alerts
  static const double temperatureAlertThreshold = 35.0; // °C
  static const double weightAlertThreshold = 10.0;      // kg
  
  // Phone numbers for emergency alerts (with country code, no + or 00)
  static const List<String> emergencyPhoneNumbers = [
    '911',  // Example emergency number
    '1234567890'  // Parent/guardian number
  ];
  
  // SMS message templates
  static const String alertMessage = 'ALERT: Child may be in danger in vehicle! ';
  static const String temperatureAlert = 'High temperature detected: ';
  static const String weightAlert = 'Unexpected weight detected: ';
  static const String motionAlert = 'Motion detected in vehicle! ';
  static const String locationMessage = 'Last known location: ';
}
