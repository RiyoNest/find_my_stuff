// File: lib/shared/widgets/content_toolbar.dart
//
// Two-column toolbar shown below the search bar on every list page.
// Left: LocationBreadcrumb (scrollable path, each segment tappable).
// Right: expand button → opens ViewOptionsSheet.
// Also shows current sort order as a tiny chip.
//
// Usage:
//   ContentToolbar(
//     segments: [
//       BreadcrumbSegment(label: 'Home', isHome: true, onTap: () => context.go('/')),
//       BreadcrumbSegment(label: 'Kitchen', onTap: () => context.pop()),
//       BreadcrumbSegment(label: 'Cupboard'),
//     ],
//     viewMode: _viewMode,
//     sortOrder: _sortOrder,
//     onViewModeChanged: (m) => setState(() => _viewMode = m),
//     onSortOrderChanged: (s) => setState(() => _sortOrder = s),
//   )

import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:find_my_stuff/shared/enums/view_sort_enums.dart';
import 'package:find_my_stuff/shared/widgets/location_breadcrumb.dart';
import 'package:find_my_stuff/shared/widgets/view_options_sheet.dart';
import 'package:flutter/material.dart';

class ContentToolbar extends StatelessWidget {
  final List<BreadcrumbSegment> segments;
  final ContentViewMode viewMode;
  final ContentSortOrder sortOrder;
  final ValueChanged<ContentViewMode> onViewModeChanged;
  final ValueChanged<ContentSortOrder> onSortOrderChanged;

  const ContentToolbar({
    super.key,
    required this.segments,
    required this.viewMode,
    required this.sortOrder,
    required this.onViewModeChanged,
    required this.onSortOrderChanged,
  });

  static IconData _viewIcon(ContentViewMode mode) {
    return switch (mode) {
      ContentViewMode.list => Icons.list_rounded,
      ContentViewMode.grid => Icons.grid_view_rounded,
      ContentViewMode.tree => Icons.account_tree_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RAppSpacing.xs,
        vertical: RAppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(RAppRadius.md),
      ),
      child: Row(
        children: [
          // Left: breadcrumb
          Expanded(
            child: LocationBreadcrumb(segments: segments),
          ),

          const SizedBox(width: RAppSpacing.sm),

          // Right: sort chip + view/options button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sort label chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: RAppSpacing.sm,
                  vertical: RAppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(RAppRadius.sm),
                ),
                child: Text(
                  sortOrder.shortLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: RAppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: RAppSpacing.xs),

              // Expand button — opens ViewOptionsSheet
              InkWell(
                borderRadius: BorderRadius.circular(RAppRadius.sm),
                onTap: () => ViewOptionsSheet.show(
                  context,
                  currentViewMode: viewMode,
                  currentSortOrder: sortOrder,
                  onViewModeChanged: onViewModeChanged,
                  onSortOrderChanged: onSortOrderChanged,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(RAppSpacing.xs + 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _viewIcon(viewMode),
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.expand_more_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}