// lib/utils/responsive_helper.dart
import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < 600;
  
  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width >= 600 && 
      MediaQuery.of(context).size.width < 1024;
  
  static bool isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width >= 1024;

  // Dynamic padding berdasarkan screen size
  static double getPadding(BuildContext context) {
    if (isMobile(context)) return 12.0;
    if (isTablet(context)) return 16.0;
    return 20.0;
  }

  // Dynamic font size
  static double getFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return baseSize * 0.9;
    if (screenWidth > 1200) return baseSize * 1.1;
    return baseSize;
  }

  // Dynamic chart height
  static double getChartHeight(BuildContext context) {
    if (isMobile(context)) return 180.0;
    if (isTablet(context)) return 220.0;
    return 250.0;
  }

  // Grid column count berdasarkan screen
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) return 2;
    if (isTablet(context)) return 3;
    return 4;
  }
}

// Extension untuk MediaQuery shortcut
extension ResponsiveExtension on BuildContext {
  bool get isMobile => ResponsiveHelper.isMobile(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isDesktop => ResponsiveHelper.isDesktop(this);
  
  double get dynamicPadding => ResponsiveHelper.getPadding(this);
  double dynamicFontSize(double baseSize) => ResponsiveHelper.getFontSize(this, baseSize);
  double get chartHeight => ResponsiveHelper.getChartHeight(this);
}