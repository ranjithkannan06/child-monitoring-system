import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../models/sensor_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("car_monitoring");
  final _dateFormat = DateFormat('MMM d, y HH:mm:ss');
  bool _showAlertDialog = false;

  @override
  void dispose() {
    // Clean up any listeners if needed
    super.dispose();
  }
  }

  Widget _buildSensorCard(String title, String value, String unit, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '$value $unit',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Safety Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {}); // Force rebuild
            },
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _databaseRef.limitToLast(1).onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text('No data available. Waiting for sensor data...'),
            );
          }

          try {
            final data = Map<String, dynamic>.from(
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>,
            );
            
            // Show alert if needed
            final bool isAlert = data['alert'] == true;
            if (isAlert && !_showAlertDialog) {
              _showAlertDialog = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showAlertDialog(context, data);
              });
            } else if (!isAlert) {
              _showAlertDialog = false;
            }
            
            // Main content with sensor data
            return _buildDashboardContent(context, data);
          } catch (e) {
            return Center(
              child: Text('Error displaying data: $e'),
            );
          }
        },
      ),
    );
  }

  // Build the main dashboard content
  Widget _buildDashboardContent(BuildContext context, Map<String, dynamic> data) {
    return StreamBuilder<DatabaseEvent>(
      stream: _databaseRef.limitToLast(1).onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(
            child: Text('No data available. Waiting for sensor data...'),
          );
        }

        try {
          final data = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map<dynamic, dynamic>,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alert Banner
                if (data['alert'] == true)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.red.shade400),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ALERT: Child detected with high temperature!',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Sensor Data List
                Card(
                  child: ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.thermostat),
                        title: const Text('Temperature'),
                        trailing: Text(
                          '${(data['temperature'] as num?)?.toStringAsFixed(1) ?? 'N/A'} °C',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.water_drop),
                        title: const Text('Humidity'),
                        trailing: Text(
                          '${(data['humidity'] as num?)?.toStringAsFixed(1) ?? 'N/A'} %',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.monitor_weight),
                        title: const Text('Weight'),
                        trailing: Text(
                          '${(data['weight'] as num?)?.toStringAsFixed(2) ?? 'N/A'} kg',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          data['ai_result'] == 'child' 
                              ? Icons.child_care 
                              : Icons.person_off,
                          color: data['ai_result'] == 'child' ? Colors.blue : Colors.grey,
                        ),
                        title: const Text('Status'),
                        trailing: data['alert'] == true
                            ? const Icon(Icons.warning, color: Colors.red)
                            : null,
                        subtitle: Text(
                          data['ai_result'] == 'child' 
                              ? 'Child Detected' 
                              : 'No Child',
                        ),
                      ),
                    ],
                  ),
                ),

                // Last Updated
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Last updated: ${_dateFormat.format(DateTime.now())}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
  Widget _buildDashboardContent(BuildContext context, Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alert Banner
          if (data['alert'] == true)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.red.shade400),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ALERT: Child detected with high temperature!',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Sensor Data List
          Card(
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ListTile(
                  leading: const Icon(Icons.thermostat),
                  title: const Text('Temperature'),
                  trailing: Text(
                    '${(data['temperature'] as num?)?.toStringAsFixed(1) ?? 'N/A'} °C',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.water_drop),
                  title: const Text('Humidity'),
                  trailing: Text(
                    '${(data['humidity'] as num?)?.toStringAsFixed(1) ?? 'N/A'} %',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.monitor_weight),
                  title: const Text('Weight'),
                  trailing: Text(
                    '${(data['weight'] as num?)?.toStringAsFixed(2) ?? 'N/A'} kg',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    data['ai_result'] == 'child' 
                        ? Icons.child_care 
                        : Icons.person_off,
                    color: data['ai_result'] == 'child' ? Colors.blue : Colors.grey,
                  ),
                  title: const Text('Status'),
                  trailing: data['alert'] == true
                      ? const Icon(Icons.warning, color: Colors.red)
                      : null,
                  subtitle: Text(
                    data['ai_result'] == 'child' 
                        ? 'Child Detected' 
                        : 'No Child',
                  ),
                ),
              ],
            ),
          ),

          // Last Updated
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              'Last updated: ${_dateFormat.format(DateTime.now())}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build the main dashboard content
  Widget _buildDashboardContent(BuildContext context, Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alert Banner
          if (data['alert'] == true)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.red.shade400),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ALERT: Child detected with high temperature!',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Sensor Data List
          Card(
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ListTile(
                  leading: const Icon(Icons.thermostat),
                  title: const Text('Temperature'),
                  trailing: Text(
                    '${(data['temperature'] as num?)?.toStringAsFixed(1) ?? 'N/A'} °C',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.water_drop),
                  title: const Text('Humidity'),
                  trailing: Text(
                    '${(data['humidity'] as num?)?.toStringAsFixed(1) ?? 'N/A'} %',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.monitor_weight),
                  title: const Text('Weight'),
                  trailing: Text(
                    '${(data['weight'] as num?)?.toStringAsFixed(2) ?? 'N/A'} kg',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    data['ai_result'] == 'child' 
                        ? Icons.child_care 
                        : Icons.person_off,
                    color: data['ai_result'] == 'child' ? Colors.blue : Colors.grey,
                  ),
                  title: const Text('Status'),
                  trailing: data['alert'] == true
                      ? const Icon(Icons.warning, color: Colors.red)
                      : null,
                  subtitle: Text(
                    data['ai_result'] == 'child' 
                        ? 'Child Detected' 
                        : 'No Child',
                  ),
                ),
              ],
            ),
          ),

          // Last Updated
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              'Last updated: ${_dateFormat.format(DateTime.now())}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAlertDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ ALERT!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Child detected with high temperature!'),
            const SizedBox(height: 8),
            Text('Temperature: ${(data['temperature'] as num?)?.toStringAsFixed(1) ?? 'N/A'}°C'),
            Text('Humidity: ${(data['humidity'] as num?)?.toStringAsFixed(1) ?? 'N/A'}%'),
            Text('Weight: ${(data['weight'] as num?)?.toStringAsFixed(2) ?? 'N/A'} kg'),
            const SizedBox(height: 8),
            const Text('Please check the vehicle immediately!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
