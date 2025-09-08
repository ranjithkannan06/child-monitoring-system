import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase/firebase_config.dart';
import 'screens/dashboard_screen.dart';
import 'services/firebase_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize the listener
    _initializeFirebaseListener();
    
    runApp(
      MultiProvider(
        providers: [
          Provider<FirebaseService>(
            create: (_) => FirebaseService(),
          ),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    print('Error initializing Firebase: $e');
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Failed to initialize Firebase. Please check your configuration.'),
        ),
      ),
    ));
  }
}

// Initialize Firebase Realtime Database listener
void _initializeFirebaseListener() {
  final databaseRef = FirebaseDatabase.instance.ref("car_monitoring");
  
  databaseRef.onChildAdded.listen((event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>?;
    if (data != null) {
      print("=== New Data Received ===");
      print("Temperature: ${data['temperature']}°C");
      print("Humidity: ${data['humidity']}%");
      print("Weight: ${data['weight']}g");
      print("AI Result: ${data['ai_result']}");
      print("Alert: ${data['alert']}");
      print("Timestamp: ${DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0)}");
      print("=========================");
    }
  }, onError: (error) {
    print("Firebase Database Error: $error");
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Child Safety Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}