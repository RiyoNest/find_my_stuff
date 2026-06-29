import 'package:flutter/material.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';

class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onRetry;
  final Widget? secondaryAction;

  const ErrorStateWidget({
    super.key,
    this.title = 'Something went wrong',
    required this.description,
    this.onRetry,
    this.secondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = secondaryAction;

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
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: context.iconXL,
                color: theme.colorScheme.error,
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
            if (onRetry != null || secondary != null) ...[
              SizedBox(height: context.spacingL),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onRetry != null)
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Try Again'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.spacingL,
                          vertical: context.spacingM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: context.borderRadiusM,
                        ),
                      ),
                    ),
                  if (onRetry != null && secondary != null)
                    const SizedBox(width: 12),
                  // ignore: use_null_aware_elements
                  if (secondary != null) secondary,
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
