import 'package:flutter/material.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';

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
        padding: context.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(context.spacingM + 4),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                    : const Color(0xFFFFF5F8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? theme.colorScheme.outline.withValues(alpha: 0.3)
                      : const Color(0xFFF8D7E3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: context.iconXL,
                color: const Color(0xFFD10047),
              ),
            ),
            SizedBox(height: context.spacingM + 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.titleStyle.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: context.spacingXS),
            Text(
              description,
              textAlign: TextAlign.center,
              style: context.bodyStyle.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionButton != null) ...[
              SizedBox(height: context.spacingL),
              actionButton!,
            ],
          ],
        ),
      ),
    );
  }
}
