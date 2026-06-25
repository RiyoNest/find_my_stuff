// File: lib/shared/widgets/location_breadcrumb.dart
//
// Horizontally-scrollable breadcrumb showing the path from Home down
// to the current page. Each segment is tappable and navigates to that
// level. Used in ContentToolbar on every list page.
//
// Usage:
//   LocationBreadcrumb(
//     segments: [
//       BreadcrumbSegment(label: 'Home', onTap: () => context.go('/')),
//       BreadcrumbSegment(label: 'Kitchen', onTap: () => context.pop()),
//       BreadcrumbSegment(label: 'Cupboard'),  // current — no tap
//     ],
//   )

import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:flutter/material.dart';

class BreadcrumbSegment {
  final String label;
  final VoidCallback? onTap; // null = current page (not tappable)
  final bool isHome;

  const BreadcrumbSegment({
    required this.label,
    this.onTap,
    this.isHome = false,
  });
}

class LocationBreadcrumb extends StatelessWidget {
  final List<BreadcrumbSegment> segments;

  const LocationBreadcrumb({super.key, required this.segments});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrent = (int i) => i == segments.length - 1;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: RAppSpacing.xs,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: RAppColors.textSecondary,
                ),
              ),
            _BreadcrumbChip(
              segment: segments[i],
              isCurrent: isCurrent(i),
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }
}

class _BreadcrumbChip extends StatelessWidget {
  final BreadcrumbSegment segment;
  final bool isCurrent;
  final ThemeData theme;

  const _BreadcrumbChip({
    required this.segment,
    required this.isCurrent,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final canTap = !isCurrent && segment.onTap != null;

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (segment.isHome)
          Padding(
            padding: const EdgeInsets.only(right: RAppSpacing.xs),
            child: Icon(
              Icons.home_rounded,
              size: 14,
              color: isCurrent
                  ? theme.colorScheme.primary
                  : RAppColors.textSecondary,
            ),
          ),
        Text(
          segment.label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isCurrent
                ? theme.colorScheme.primary
                : RAppColors.textSecondary,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );

    if (!canTap) return child;

    return InkWell(
      onTap: segment.onTap,
      borderRadius: BorderRadius.circular(RAppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RAppSpacing.xs,
          vertical: 2,
        ),
        child: child,
      ),
    );
  }
}