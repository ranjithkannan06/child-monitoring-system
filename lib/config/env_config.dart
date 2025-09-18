import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // Firebase Configuration
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  static String get firebaseAuthDomain => dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseStorageBucket => dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  static String get firebaseMessagingSenderId => dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';
  static String get firebaseMeasurementId => dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '';
  static String get firebaseDatabaseUrl => dotenv.env['FIREBASE_DATABASE_URL'] ?? '';

  // Google Sign-In Configuration
  static String get googleSignInClientId => dotenv.env['GOOGLE_SIGN_IN_CLIENT_ID'] ?? '';

  // ESP32 Configuration
  static String get esp32BaseUrl => dotenv.env['ESP32_BASE_URL'] ?? 'http://YOUR_ESP32_IP';
  static String get esp32ApiPath => dotenv.env['ESP32_API_PATH'] ?? '/update';

  // App Configuration
  static String get appTitle => dotenv.env['APP_TITLE'] ?? 'Child Safety Monitor';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0+1';

  // Initialize environment variables
  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
  }
}
