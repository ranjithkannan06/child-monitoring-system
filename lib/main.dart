import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/auth/auth_wrapper.dart';
import 'services/auth_service.dart';
import 'services/esp32_service.dart';
import 'services/notification_service.dart';
import 'config/firebase_config.dart';
import 'config/env_config.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await EnvConfig.load();
  } catch (e) {
    print('Warning: Could not load .env file: $e');
    // Continue with hardcoded values for now
  }
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: EnvConfig.firebaseApiKey.isNotEmpty ? EnvConfig.firebaseApiKey : 'AIzaSyA6V4YX8qABZEt3Hm_zS89frxUnSJ55pIM',
      authDomain: EnvConfig.firebaseAuthDomain.isNotEmpty ? EnvConfig.firebaseAuthDomain : 'child-monitering-system.firebaseapp.com',
      projectId: EnvConfig.firebaseProjectId.isNotEmpty ? EnvConfig.firebaseProjectId : 'child-monitering-system',
      storageBucket: EnvConfig.firebaseStorageBucket.isNotEmpty ? EnvConfig.firebaseStorageBucket : 'child-monitering-system.firebasestorage.app',
      messagingSenderId: EnvConfig.firebaseMessagingSenderId.isNotEmpty ? EnvConfig.firebaseMessagingSenderId : '217976487619',
      appId: EnvConfig.firebaseAppId.isNotEmpty ? EnvConfig.firebaseAppId : '1:217976487619:web:71c35d59ee11f17ac22c76',
      measurementId: EnvConfig.firebaseMeasurementId.isNotEmpty ? EnvConfig.firebaseMeasurementId : 'G-0JPZ16DQSK',
      databaseURL: EnvConfig.firebaseDatabaseUrl.isNotEmpty ? EnvConfig.firebaseDatabaseUrl : 'https://child-monitering-system-default-rtdb.firebaseio.com/',
    ),
  );

  // Initialize services
  final authService = AuthService();
  final notificationService = NotificationService();
  
  // Initialize notification service with error handling
  try {
    await notificationService.initialize();
    print('NotificationService initialized successfully');
  } catch (e) {
    print('Warning: NotificationService failed to initialize: $e');
    // Continue without notifications for now
  }
  
  // Initialize ESP32 service when user is authenticated
  late ESP32Service esp32Service;
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authService),
        Provider(create: (_) => notificationService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        ProxyProvider<AuthService, ESP32Service?>(
          update: (_, authService, __) {
            if (authService.currentUser != null) {
              esp32Service = ESP32Service(
                userId: authService.currentUser!.uid,
                notificationService: notificationService,
              );
              esp32Service.initialize();
              return esp32Service;
            }
            return null;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return MaterialApp(
      title: 'Child Safety Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const AuthWrapper(),
    );
  }
}