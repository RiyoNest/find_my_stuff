// File: lib/shared/widgets/home_async_list.dart
//
// Generic wrapper around AsyncValue<List<T>> that gives every dashboard
// section consistent loading, error+retry, and empty states. Replaces
// six near-identical `.when(...)` blocks that previously lived inline
// in home_page.dart (and silently swallowed errors with `SizedBox()`).

import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeAsyncList<T> extends StatelessWidget {
  final AsyncValue<List<T>> asyncValue;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final String emptyMessage;
  final IconData emptyIcon;
  final VoidCallback onRetry;
  final int maxItems;

  const HomeAsyncList({
    super.key,
    required this.asyncValue,
    required this.itemBuilder,
    required this.emptyMessage,
    required this.onRetry,
    this.emptyIcon = Icons.inbox_outlined,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return asyncValue.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: RAppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: RAppSpacing.md),
        child: Center(
          child: Column(
            children: [
              Text(
                "Couldn't load this section",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: RAppColors.error,
                ),
              ),
              const SizedBox(height: RAppSpacing.sm),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: RAppSpacing.md + 4),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    emptyIcon,
                    color: RAppColors.textSecondary,
                    size: 28,
                  ),
                  const SizedBox(height: RAppSpacing.sm),
                  Text(
                    emptyMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: RAppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final visible = items.take(maxItems).toList();

        return Column(
          children: [
            for (var i = 0; i < visible.length; i++)
              itemBuilder(context, visible[i], i),
          ],
        );
      },
    );
  }
}