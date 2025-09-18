class FirebaseConfig {
  // Firebase Web Configuration
  static const Map<String, dynamic> webConfig = {
    'apiKey': 'AIzaSyA6V4YX8qABZEt3Hm_zS89frxUnSJ55pIM',
    'authDomain': 'child-monitering-system.firebaseapp.com',
    'projectId': 'child-monitering-system',
    'storageBucket': 'child-monitering-system.firebasestorage.app',
    'messagingSenderId': '217976487619',
    'appId': '1:217976487619:web:71c35d59ee11f17ac22c76',
    'measurementId': 'G-0JPZ16DQSK',
    'databaseURL': 'https://child-monitering-system-default-rtdb.firebaseio.com/',
  };

  // Notification Channel Configuration
  static const String notificationChannelId = 'high_importance_channel';
  static const String notificationChannelName = 'High Importance Notifications';
  static const String notificationChannelDescription = 
      'This channel is used for important notifications from the Child Safety Monitor app.';

  // Database Paths
  static String getSensorDataPath(String userId) => 'users/$userId/sensor_data';
  static String getAlertsPath(String userId) => 'users/$userId/alerts';
  
  // Notification Topics
  static const String alertTopic = 'alerts';
  
  // FCM Configuration
  static const String fcmServerKey = 'YOUR_FCM_SERVER_KEY'; // Add your FCM server key here
}
