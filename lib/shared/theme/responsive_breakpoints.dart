import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  static const double mobileMax = 599.0;
  static const double tabletMax = 899.0;
  static const double largeTabletMax = 1199.0;

  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 600 && width < 900;
  }

  static bool isLargeTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 900 && width < 1200;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 1200;
  }

  static bool isPortrait(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.portrait;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }
}
