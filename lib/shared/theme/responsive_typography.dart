import 'package:flutter/material.dart';

class ResponsiveTypography {
  ResponsiveTypography._();

  /// Calculates a responsive font size that adjusts to screen width and clamps 
  /// the accessibility text scaling factor to prevent layout breakage.
  static double _getScaledSize(
    BuildContext context, {
    required double mobileSize,
    required double desktopSize,
  }) {
    final width = MediaQuery.sizeOf(context).width;

    // Linearly interpolate base size between 360dp and 1200dp viewports
    const double minWidth = 360.0;
    const double maxWidth = 1200.0;
    final clampedWidth = width.clamp(minWidth, maxWidth);
    final t = (clampedWidth - minWidth) / (maxWidth - minWidth);
    final baseSize = mobileSize + (desktopSize - mobileSize) * t;

    // Retrieve system accessibility text scaler
    final textScaler = MediaQuery.textScalerOf(context);
    final systemScaleFactor = textScaler.scale(100.0) / 100.0;

    // Clamp the scale factor to prevent excessively large text from breaking the layout
    final clampedScaleFactor = systemScaleFactor.clamp(0.85, 1.35);

    // Because Flutter's standard Text widget automatically scales any TextStyle font size 
    // by the system scale factor, we counteract this by adjusting the size:
    // adjustedSize = baseSize * (clampedScaleFactor / systemScaleFactor)
    // Thus: finalSize = adjustedSize * systemScaleFactor = baseSize * clampedScaleFactor
    return baseSize * (clampedScaleFactor / systemScaleFactor);
  }

  static TextStyle display(BuildContext context) {
    return TextStyle(
      fontSize: _getScaledSize(context, mobileSize: 28, desktopSize: 36),
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    );
  }

  static TextStyle headline(BuildContext context) {
    return TextStyle(
      fontSize: _getScaledSize(context, mobileSize: 22, desktopSize: 30),
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    );
  }

  static TextStyle title(BuildContext context) {
    return TextStyle(
      fontSize: _getScaledSize(context, mobileSize: 18, desktopSize: 24),
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle subtitle(BuildContext context) {
    return TextStyle(
      fontSize: _getScaledSize(context, mobileSize: 16, desktopSize: 20),
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle body(BuildContext context) {
    return TextStyle(
      fontSize: _getScaledSize(context, mobileSize: 14, desktopSize: 18),
      fontWeight: FontWeight.w400,
      height: 1.5,
    );
  }

  static TextStyle bodySmall(BuildContext context) {
    return TextStyle(
      fontSize: _getScaledSize(context, mobileSize: 12, desktopSize: 14),
      fontWeight: FontWeight.w400,
      height: 1.4,
    );
  }

  static TextStyle caption(BuildContext context) {
    return TextStyle(
      fontSize: _getScaledSize(context, mobileSize: 12, desktopSize: 14),
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle label(BuildContext context) {
    return TextStyle(
      fontSize: _getScaledSize(context, mobileSize: 12, desktopSize: 14),
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle button(BuildContext context) {
    return TextStyle(
      fontSize: _getScaledSize(context, mobileSize: 14, desktopSize: 16),
      fontWeight: FontWeight.w600,
    );
  }
}
