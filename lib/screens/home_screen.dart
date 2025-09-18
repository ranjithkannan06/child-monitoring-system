import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/theme_provider.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          // Theme toggle
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                const Icon(Icons.light_mode, size: 18),
                Switch(
                  value: context.watch<ThemeProvider>().isDark,
                  onChanged: (_) => context.read<ThemeProvider>().toggle(),
                ),
                const Icon(Icons.dark_mode, size: 18),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthService>().signOut();
                // Navigation will be handled by AuthWrapper automatically
              },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user?.photoURL != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(user!.photoURL!),
              )
            else
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
            const SizedBox(height: 20),
            Text(
              'Welcome, ${user?.displayName ?? 'User'}' ?? 'User',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (user?.email != null)
              Text(
                user!.email!,
                style: TextStyle(color: Colors.grey[600]),
              )
            else if (user?.phoneNumber != null)
              Text(
                user!.phoneNumber!,
                style: TextStyle(color: Colors.grey[600]),
              ),
            const SizedBox(height: 40),
            // Add your app's main content here
            const Text(
              'Child Safety Monitoring',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            // Add your app's features here
            _buildFeatureButton(
              context,
              icon: Icons.location_on,
              label: 'Live Location',
              onTap: () {
                // Navigate to live location screen
              },
            ),
            _buildFeatureButton(
              context,
              icon: Icons.notifications,
              label: 'Alerts',
              onTap: () {
                // Navigate to alerts screen
              },
            ),
            _buildFeatureButton(
              context,
              icon: Icons.settings,
              label: 'Settings',
              onTap: () {
                // Navigate to settings screen
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(icon, size: 32, color: Theme.of(context).primaryColor),
          title: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        ),
      ),
    );
  }
}
