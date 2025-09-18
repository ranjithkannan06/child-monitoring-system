import 'package:flutter/material.dart';
import '../sign_in_screen.dart';
import 'sign_up_screen.dart';
import '../../utils/responsive_helper.dart';

class WelcomeScreenApple extends StatelessWidget {
  const WelcomeScreenApple({Key? key}) : super(key: key);

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
                  ? [const Color(0xFF000000), const Color(0xFF1C1C1E)]
                  : [const Color(0xFFF2F2F7), const Color(0xFFFFFFFF)],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.isMobile(context) ? double.infinity : 400,
              ),
              child: Padding(
                padding: ResponsiveHelper.getResponsivePadding(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Icon
                    Container(
                      width: ResponsiveHelper.isMobile(context) ? 80 : 100,
                      height: ResponsiveHelper.isMobile(context) ? 80 : 100,
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.security_rounded,
                        size: ResponsiveHelper.isMobile(context) ? 40 : 50,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // App Title
                    Text(
                      'Care+',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 32,
                          tablet: 36,
                          desktop: 40,
                        ),
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Subtitle
                    Text(
                      'Child Safety Monitor',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 20,
                          tablet: 24,
                          desktop: 28,
                        ),
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      'Keep your children safe with real-time monitoring and instant alerts',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.2,
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Sign In Button
                    ResponsiveHelper.getResponsiveButton(
                      context: context,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignInScreen()),
                      ),
                      text: 'Sign In',
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                    ),
                    const SizedBox(height: 16),
                    
                    // Create Account Button
                    ResponsiveHelper.getResponsiveButton(
                      context: context,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpScreen()),
                      ),
                      text: 'Create Account',
                      backgroundColor: Colors.transparent,
                      foregroundColor: cs.primary,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Footer
                    Text(
                      'Privacy • Terms • Help',
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurfaceVariant.withOpacity(0.7),
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
