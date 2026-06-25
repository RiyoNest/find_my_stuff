// File: lib/shared/widgets/view_options_sheet.dart
//
// Bottom sheet shown when the user taps the expand arrow in ContentToolbar.
// Lets the user pick view mode (List / Grid / Tree) and sort order.
// Uses showModalBottomSheet so it overlays without changing the page.

import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:find_my_stuff/shared/enums/view_sort_enums.dart';
import 'package:flutter/material.dart';

class ViewOptionsSheet extends StatefulWidget {
  final ContentViewMode currentViewMode;
  final ContentSortOrder currentSortOrder;
  final ValueChanged<ContentViewMode> onViewModeChanged;
  final ValueChanged<ContentSortOrder> onSortOrderChanged;

  const ViewOptionsSheet({
    super.key,
    required this.currentViewMode,
    required this.currentSortOrder,
    required this.onViewModeChanged,
    required this.onSortOrderChanged,
  });

  static Future<void> show(
      BuildContext context, {
        required ContentViewMode currentViewMode,
        required ContentSortOrder currentSortOrder,
        required ValueChanged<ContentViewMode> onViewModeChanged,
        required ValueChanged<ContentSortOrder> onSortOrderChanged,
      }) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RAppRadius.xl),
        ),
      ),
      builder: (_) => ViewOptionsSheet(
        currentViewMode: currentViewMode,
        currentSortOrder: currentSortOrder,
        onViewModeChanged: onViewModeChanged,
        onSortOrderChanged: onSortOrderChanged,
      ),
    );
  }

  @override
  State<ViewOptionsSheet> createState() => _ViewOptionsSheetState();
}

class _ViewOptionsSheetState extends State<ViewOptionsSheet> {
  late ContentViewMode _viewMode;
  late ContentSortOrder _sortOrder;

  @override
  void initState() {
    super.initState();
    _viewMode = widget.currentViewMode;
    _sortOrder = widget.currentSortOrder;
  }

  void _setViewMode(ContentViewMode mode) {
    setState(() => _viewMode = mode);
    widget.onViewModeChanged(mode);
  }

  void _setSortOrder(ContentSortOrder order) {
    setState(() => _sortOrder = order);
    widget.onSortOrderChanged(order);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          RAppSpacing.lg,
          0,
          RAppSpacing.lg,
          RAppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // View mode
            Text('View As', style: theme.textTheme.titleSmall),
            const SizedBox(height: RAppSpacing.sm),
            Row(
              children: [
                _ViewModeButton(
                  icon: Icons.list_rounded,
                  label: 'List',
                  selected: _viewMode == ContentViewMode.list,
                  onTap: () => _setViewMode(ContentViewMode.list),
                ),
                const SizedBox(width: RAppSpacing.sm),
                _ViewModeButton(
                  icon: Icons.grid_view_rounded,
                  label: 'Grid',
                  selected: _viewMode == ContentViewMode.grid,
                  onTap: () => _setViewMode(ContentViewMode.grid),
                ),
                const SizedBox(width: RAppSpacing.sm),
                _ViewModeButton(
                  icon: Icons.account_tree_outlined,
                  label: 'Tree',
                  selected: _viewMode == ContentViewMode.tree,
                  onTap: () => _setViewMode(ContentViewMode.tree),
                ),
              ],
            ),

            const SizedBox(height: RAppSpacing.lg),

            // Sort order
            Text('Sort By', style: theme.textTheme.titleSmall),
            const SizedBox(height: RAppSpacing.sm),
            ...ContentSortOrder.values.map(
                  (order) => RadioListTile<ContentSortOrder>(
                value: order,
                groupValue: _sortOrder,
                title: Text(
                  order.label,
                  style: theme.textTheme.bodyMedium,
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
                onChanged: (v) => _setSortOrder(v!),
              ),
            ),

            const SizedBox(height: RAppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RAppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            vertical: RAppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(RAppRadius.md),
            border: selected
                ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected
                    ? theme.colorScheme.primary
                    : RAppColors.textSecondary,
              ),
              const SizedBox(height: RAppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? theme.colorScheme.primary
                      : RAppColors.textSecondary,
                  fontWeight:
                  selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}