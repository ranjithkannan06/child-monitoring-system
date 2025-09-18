import 'package:flutter/material.dart';
import '../sign_in_screen.dart';
import 'sign_up_screen.dart';
import '../../utils/responsive_helper.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('WelcomeScreen: Building widget');
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF0B0B0F), const Color(0xFF0F1115)]
                  : [const Color(0xFFFFFFFF), const Color(0xFFF7F8FA)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Header
                Row(
                  children: [
                    Icon(Icons.shield_moon_outlined, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Care+',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Support',
                        style: TextStyle(color: cs.outline),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Hero mark
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.security_rounded, size: 48, color: cs.primary),
                ),
                const SizedBox(height: 16),
                // Debug text
                Text(
                  'App is working!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Child Safety Monitor',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Real-time ESP32 monitoring with instant alerts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignInScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                    ),
                    child: const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpScreen()),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: cs.primary),
                    ),
                    child: Text(
                      'Create Account',
                      style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
