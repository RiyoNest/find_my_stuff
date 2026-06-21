// File: lib/core/constants/app_colours.dart
//
// CHANGES from your version:
//   - Added `info` (was missing — needed for the info SnackBar/banner type)
//   - Added `successContainer` / `onSuccessContainer` and equivalents for
//     warning / error / info — soft pastel backgrounds + readable text/icon
//     color, used by AppSnackBar and ExpiryAlertBanner so status colors
//     match your brand red instead of generic Material green/amber/blue.
//   - Everything else is unchanged.

import 'package:flutter/material.dart';

class RAppColors {
  RAppColors._();

  // Brand
  static const primary = Color(0xFFB11226);
  static const secondary = Color(0xFF374151);
  static const background = Color(0xFFF8F9FA);
  static const accent = Color(0xFFFFB703);
  static const surface = Color(0xFFFFFFFF);

  // Light Theme
  static const lightBackground = Color(0xFFF8F9FB);
  static const lightSurface = Colors.white;

  // Dark Theme
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);

  // Common
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF57C00);
  static const error = Color(0xFFD32F2F);
  static const info = Color(0xFF0288D1);

  // Soft "container" backgrounds for banners, snackbars, badges —
  // pair with the matching on*Container color for text/icon on top.
  static const successContainer = Color(0xFFE3F3E4);
  static const onSuccessContainer = Color(0xFF1B5E20);

  static const warningContainer = Color(0xFFFFF1DC);
  static const onWarningContainer = Color(0xFFB85C00);

  static const errorContainer = Color(0xFFFBE2E1);
  static const onErrorContainer = Color(0xFF9A271F);

  static const infoContainer = Color(0xFFDFF0FB);
  static const onInfoContainer = Color(0xFF015685);

  static const border = Color(0xFFE0E0E0);

  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF666666);
}