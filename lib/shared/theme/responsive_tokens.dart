import 'package:flutter/material.dart';
import 'responsive_breakpoints.dart';

class ResponsiveTokens {
  ResponsiveTokens._();

  // =========================
  // SPACING & MARGINS
  // =========================

  static double spacingXS(BuildContext context) {
    if (ResponsiveBreakpoints.isDesktop(context)) return 6.0;
    return 4.0;
  }

  static double spacingS(BuildContext context) {
    if (ResponsiveBreakpoints.isDesktop(context)) return 12.0;
    if (ResponsiveBreakpoints.isTablet(context) || ResponsiveBreakpoints.isLargeTablet(context)) return 10.0;
    return 8.0;
  }

  static double spacingM(BuildContext context) {
    if (ResponsiveBreakpoints.isDesktop(context)) return 24.0;
    if (ResponsiveBreakpoints.isTablet(context) || ResponsiveBreakpoints.isLargeTablet(context)) return 18.0;
    return 16.0;
  }

  static double spacingL(BuildContext context) {
    if (ResponsiveBreakpoints.isDesktop(context)) return 36.0;
    if (ResponsiveBreakpoints.isTablet(context) || ResponsiveBreakpoints.isLargeTablet(context)) return 28.0;
    return 24.0;
  }

  static double spacingXL(BuildContext context) {
    if (ResponsiveBreakpoints.isDesktop(context)) return 56.0;
    if (ResponsiveBreakpoints.isTablet(context) || ResponsiveBreakpoints.isLargeTablet(context)) return 40.0;
    return 32.0;
  }

  // =========================
  // PADDING
  // =========================

  static EdgeInsets pagePadding(BuildContext context) {
    if (ResponsiveBreakpoints.isDesktop(context)) {
      return EdgeInsets.symmetric(
        horizontal: spacingXL(context),
        vertical: spacingL(context),
      );
    }
    if (ResponsiveBreakpoints.isTablet(context) || ResponsiveBreakpoints.isLargeTablet(context)) {
      return EdgeInsets.symmetric(
        horizontal: spacingL(context),
        vertical: spacingM(context),
      );
    }
    return EdgeInsets.all(spacingM(context));
  }

  static EdgeInsets cardPadding(BuildContext context) {
    final horizontal = spacingM(context);
    final vertical = ResponsiveBreakpoints.isDesktop(context)
        ? 20.0
        : (ResponsiveBreakpoints.isTablet(context) || ResponsiveBreakpoints.isLargeTablet(context) ? 15.0 : 12.0);
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  static EdgeInsets sheetPadding(BuildContext context) {
    return EdgeInsets.all(spacingM(context));
  }

  static EdgeInsets dialogPadding(BuildContext context) {
    return EdgeInsets.all(spacingL(context));
  }

  // =========================
  // RADIUS
  // =========================

  static double radiusS(BuildContext context) => 8.0;
  static double radiusM(BuildContext context) => 12.0;
  static double radiusL(BuildContext context) => 16.0;
  static double radiusPill(BuildContext context) => 999.0;

  static BorderRadius borderRadiusS(BuildContext context) => BorderRadius.circular(radiusS(context));
  static BorderRadius borderRadiusM(BuildContext context) => BorderRadius.circular(radiusM(context));
  static BorderRadius borderRadiusL(BuildContext context) => BorderRadius.circular(radiusL(context));
  static BorderRadius borderRadiusPill(BuildContext context) => BorderRadius.circular(radiusPill(context));

  // =========================
  // ICON SIZES
  // =========================

  static double iconSmall(BuildContext context) {
    if (ResponsiveBreakpoints.isDesktop(context)) return 20.0;
    return 16.0;
  }

  static double iconMedium(BuildContext context) {
    if (ResponsiveBreakpoints.isDesktop(context)) return 28.0;
    if (ResponsiveBreakpoints.isTablet(context) || ResponsiveBreakpoints.isLargeTablet(context)) return 26.0;
    return 24.0;
  }

  static double iconLarge(BuildContext context) {
    if (ResponsiveBreakpoints.isDesktop(context)) return 40.0;
    if (ResponsiveBreakpoints.isTablet(context) || ResponsiveBreakpoints.isLargeTablet(context)) return 36.0;
    return 32.0;
  }

  static double iconXL(BuildContext context) {
    if (ResponsiveBreakpoints.isDesktop(context)) return 64.0;
    if (ResponsiveBreakpoints.isTablet(context) || ResponsiveBreakpoints.isLargeTablet(context)) return 54.0;
    return 48.0;
  }

  // =========================
  // DIMENSIONS & ASPECT RATIOS
  // =========================

  static double dashboardCardHeight(BuildContext context) {
    if (ResponsiveBreakpoints.isDesktop(context)) return 124.0;
    if (ResponsiveBreakpoints.isTablet(context) || ResponsiveBreakpoints.isLargeTablet(context)) return 114.0;
    return 104.0;
  }

  static double roomCardWidth(BuildContext context) {
    if (ResponsiveBreakpoints.isDesktop(context)) return 200.0;
    if (ResponsiveBreakpoints.isTablet(context) || ResponsiveBreakpoints.isLargeTablet(context)) return 180.0;
    return 165.0;
  }

  static double imageHeight(BuildContext context) {
    if (ResponsiveBreakpoints.isDesktop(context)) return 200.0;
    if (ResponsiveBreakpoints.isTablet(context) || ResponsiveBreakpoints.isLargeTablet(context)) return 160.0;
    return 120.0;
  }

  static double listTileHeight(BuildContext context) {
    if (ResponsiveBreakpoints.isDesktop(context)) return 72.0;
    if (ResponsiveBreakpoints.isTablet(context) || ResponsiveBreakpoints.isLargeTablet(context)) return 64.0;
    return 56.0;
  }

  static int getColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    return 4;
  }

  static double roomCardAspectRatio(BuildContext context) {
    final cols = getColumns(context);
    if (cols == 1) return 2.8;
    if (cols == 2) return 1.4;
    if (cols == 3) return 1.2;
    return 1.1;
  }

  static double itemCardAspectRatio(BuildContext context) {
    final cols = getColumns(context);
    if (cols == 1) return 2.6;
    if (cols == 2) return 1.2;
    if (cols == 3) return 1.1;
    return 1.0;
  }

  static double photoCardAspectRatio(BuildContext context) {
    final cols = getColumns(context);
    if (cols == 1) return 1.8;
    if (cols == 2) return 1.1;
    if (cols == 3) return 1.0;
    return 0.9;
  }
}
