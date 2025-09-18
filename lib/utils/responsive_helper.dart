import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  static double getResponsiveWidth(BuildContext context, {
    double mobile = 0.9,
    double tablet = 0.8,
    double desktop = 0.6,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static EdgeInsets getResponsivePadding(BuildContext context, {
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    if (isMobile(context)) {
      return mobile ?? const EdgeInsets.all(16);
    }
    if (isTablet(context)) {
      return tablet ?? const EdgeInsets.all(24);
    }
    return desktop ?? const EdgeInsets.all(32);
  }

  static double getResponsiveFontSize(BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static int getResponsiveColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }

  static Widget getResponsiveCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
    double? elevation,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: isMobile(context) ? 16 : 24,
        vertical: 8,
      ),
      child: Card(
        elevation: elevation ?? 0,
        child: Padding(
          padding: padding ?? getResponsivePadding(context),
          child: child,
        ),
      ),
    );
  }

  static Widget getResponsiveButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required String text,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    double? width,
  }) {
    final buttonWidth = width ?? (isMobile(context) ? double.infinity : 200);
    
    return SizedBox(
      width: buttonWidth,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget getResponsiveGrid({
    required BuildContext context,
    required List<Widget> children,
    double spacing = 16,
  }) {
    final columns = getResponsiveColumns(context);
    final crossAxisCount = columns;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: isMobile(context) ? 1.2 : 1.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}
