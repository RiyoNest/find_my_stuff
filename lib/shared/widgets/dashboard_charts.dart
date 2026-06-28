// File: lib/shared/widgets/dashboard_charts.dart
//
// Chart widgets for displaying statistics on the dashboard.
// Shows items breakdown and expiry status. Uses RAppColors tokens so
// status colors (success/warning/error) match the brand palette.
//
// Note: these are lightweight charts built from core widgets to avoid
// adding a new dependency. If richer charts are wanted later (pie/line),
// consider adding fl_chart (pub.dev/packages/fl_chart) to pubspec.yaml.

import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';

class ItemsBreakdownChart extends StatelessWidget {
  final Map<String, int> itemsByType;

  const ItemsBreakdownChart({super.key, required this.itemsByType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = itemsByType.values.fold<int>(0, (a, b) => a + b);

    if (total == 0) {
      return const _EmptyChart(label: 'No items yet');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Items Breakdown', style: theme.textTheme.titleSmall),
        const SizedBox(height: RAppSpacing.sm + 4),
        ...itemsByType.entries.map((entry) {
          final percentage = (entry.value / total * 100).toStringAsFixed(1);
          final label = entry.key.isEmpty
              ? entry.key
              : entry.key[0].toUpperCase() + entry.key.substring(1);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: RAppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: theme.textTheme.bodyMedium),
                    Text(
                      '${entry.value} ($percentage%)',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: RAppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: RAppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(RAppRadius.sm),
                  child: LinearProgressIndicator(
                    value: entry.value / total,
                    minHeight: 8,
                    backgroundColor: RAppColors.border,
                    valueColor: AlwaysStoppedAnimation(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class ExpiryStatusChart extends StatelessWidget {
  final int expired;
  final int expiring;
  final int active;

  const ExpiryStatusChart({
    super.key,
    required this.expired,
    required this.expiring,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = expired + expiring + active;

    if (total == 0) {
      return const _EmptyChart(label: 'No tracked items');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Item Status', style: theme.textTheme.titleSmall),
        const SizedBox(height: RAppSpacing.sm + 4),
        Row(
          children: [
            _StatusIndicator(
              label: 'Active',
              count: active,
              color: RAppColors.success,
              percentage: (active / total * 100).toStringAsFixed(0),
            ),
            const SizedBox(width: RAppSpacing.sm + 4),
            _StatusIndicator(
              label: 'Expiring',
              count: expiring,
              color: RAppColors.warning,
              percentage: (expiring / total * 100).toStringAsFixed(0),
            ),
            const SizedBox(width: RAppSpacing.sm + 4),
            _StatusIndicator(
              label: 'Expired',
              count: expired,
              color: RAppColors.error,
              percentage: (expired / total * 100).toStringAsFixed(0),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final String percentage;

  const _StatusIndicator({
    required this.label,
    required this.count,
    required this.color,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(RAppSpacing.sm + 4),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(RAppRadius.sm),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Center(
                child: Text(
                  percentage,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: RAppSpacing.xs + 2),
            Text(
              label,
              style: theme.textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              count.toString(),
              style: context.bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String label;

  const _EmptyChart({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: RAppSpacing.xl),
        child: Text(
          label,
          style: const TextStyle(color: RAppColors.textSecondary),
        ),
      ),
    );
  }
}

/// Small insight/recommendation card used under the charts section.
class InsightCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  const InsightCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RAppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(RAppSpacing.md),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          border: Border.all(color: accentColor.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(RAppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(RAppSpacing.sm),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: RAppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}