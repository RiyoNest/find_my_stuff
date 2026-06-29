// File: lib/shared/widgets/custom_snackbar.dart
//
// Enhanced SnackBar widget that supports success, error, warning, and info types
// with custom icons, colors, and animations. Use via AppSnackBar static methods.
//
// Colors come from RAppColors' soft "container" tokens (see updated
// app_colours.dart) so the snackbar matches the rest of the brand palette
// instead of generic Material red/green/amber/blue.

import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';

enum SnackBarType { success, error, warning, info }

class AppSnackBar {
  static void show(
      BuildContext context,
      String message, {
        SnackBarType type = SnackBarType.info,
        Duration duration = const Duration(seconds: 3),
        SnackBarAction? action,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        _buildSnackBar(
          context: context,
          message: message,
          type: type,
          duration: duration,
          action: action,
        ),
      );
  }

  static void success(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 3),
      }) {
    show(context, message, type: SnackBarType.success, duration: duration);
  }

  static void error(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 4),
      }) {
    show(context, message, type: SnackBarType.error, duration: duration);
  }

  static void warning(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 3),
      }) {
    show(context, message, type: SnackBarType.warning, duration: duration);
  }

  static void info(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 3),
      }) {
    show(context, message, type: SnackBarType.info, duration: duration);
  }

  static SnackBar _buildSnackBar({
    required BuildContext context,
    required String message,
    required SnackBarType type,
    required Duration duration,
    SnackBarAction? action,
  }) {
    final (background, foreground, icon) = _getTypeConfig(type);

    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: context.bodyStyle.copyWith(
                color: foreground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: background,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RAppRadius.md),
      ),
      elevation: 3,
      action: action != null
          ? SnackBarAction(
        label: action.label,
        textColor: foreground,
        onPressed: action.onPressed,
      )
          : null,
    );
  }

  static (Color, Color, IconData) _getTypeConfig(SnackBarType type) {
    return switch (type) {
      SnackBarType.success => (
      RAppColors.successContainer,
      RAppColors.onSuccessContainer,
      Icons.check_circle_rounded,
      ),
      SnackBarType.error => (
      RAppColors.errorContainer,
      RAppColors.onErrorContainer,
      Icons.error_rounded,
      ),
      SnackBarType.warning => (
      RAppColors.warningContainer,
      RAppColors.onWarningContainer,
      Icons.warning_rounded,
      ),
      SnackBarType.info => (
      RAppColors.infoContainer,
      RAppColors.onInfoContainer,
      Icons.info_rounded,
      ),
    };
  }
}