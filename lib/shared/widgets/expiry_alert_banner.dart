// File: lib/shared/widgets/expiry_alert_banner.dart
//
// Surfaces expired / expiring items as a single attention-grabbing
// banner near the top of the Home Screen, instead of burying them as
// two more lookalike list sections mid-scroll. Uses RAppColors.error /
// RAppColors.warning container tokens for brand-consistent styling.

import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:flutter/material.dart';

class ExpiryAlertBanner extends StatelessWidget {
  final int expiredCount;
  final int expiringCount;
  final VoidCallback onTapExpired;
  final VoidCallback onTapExpiring;

  const ExpiryAlertBanner({
    super.key,
    required this.expiredCount,
    required this.expiringCount,
    required this.onTapExpired,
    required this.onTapExpiring,
  });

  @override
  Widget build(BuildContext context) {
    if (expiredCount == 0 && expiringCount == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (expiredCount > 0)
          _AlertRow(
            icon: Icons.error_rounded,
            background: RAppColors.errorContainer,
            foreground: RAppColors.onErrorContainer,
            label: expiredCount == 1
                ? '1 item has expired'
                : '$expiredCount items have expired',
            onTap: onTapExpired,
          ),
        if (expiredCount > 0 && expiringCount > 0)
          const SizedBox(height: RAppSpacing.sm),
        if (expiringCount > 0)
          _AlertRow(
            icon: Icons.schedule_rounded,
            background: RAppColors.warningContainer,
            foreground: RAppColors.onWarningContainer,
            label: expiringCount == 1
                ? '1 item expiring soon'
                : '$expiringCount items expiring soon',
            onTap: onTapExpiring,
          ),
      ],
    );
  }
}

class _AlertRow extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  final String label;
  final VoidCallback onTap;

  const _AlertRow({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(RAppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(RAppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RAppSpacing.sm + 6,
            vertical: RAppSpacing.sm + 4,
          ),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: RAppSpacing.sm + 2),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}