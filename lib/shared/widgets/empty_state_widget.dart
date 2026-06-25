import 'package:flutter/material.dart';
import '../../core/constants/app_colours.dart';
import '../../core/constants/app_spacing.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? actionButton;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(RAppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(RAppSpacing.md + 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F8),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF8D7E3), width: 1),
              ),
              child: Icon(
                icon,
                size: 48,
                color: const Color(0xFFD10047),
              ),
            ),
            const SizedBox(height: RAppSpacing.md + 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: RAppColors.textPrimary,
              ),
            ),
            const SizedBox(height: RAppSpacing.xs + 2),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: RAppColors.textSecondary,
              ),
            ),
            if (actionButton != null) ...[
              const SizedBox(height: RAppSpacing.lg),
              actionButton!,
            ],
          ],
        ),
      ),
    );
  }
}
