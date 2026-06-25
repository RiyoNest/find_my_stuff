// File: lib/shared/widgets/view_options_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colours.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../enums/content_view_mode.dart';
import '../enums/content_sort_order.dart';
import '../enums/content_filter.dart';
import '../providers/content_preferences_provider.dart';

class ViewOptionsSheet extends ConsumerWidget {
  const ViewOptionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RAppRadius.xl),
        ),
      ),
      builder: (_) => const ViewOptionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prefs = ref.watch(contentPreferencesProvider);
    final notifier = ref.read(contentPreferencesProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: RAppSpacing.lg,
          right: RAppSpacing.lg,
          bottom: RAppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Center(
                child: Text(
                  'Display Options',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: RAppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: RAppSpacing.md + 4),

              // 1. View mode
              Text(
                'View As',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: RAppColors.textPrimary,
                ),
              ),
              const SizedBox(height: RAppSpacing.sm),
              Row(
                children: [
                  _ViewModeButton(
                    icon: Icons.list_rounded,
                    label: 'List',
                    selected: prefs.viewMode == ContentViewMode.list,
                    onTap: () => notifier.setViewMode(ContentViewMode.list),
                  ),
                  const SizedBox(width: RAppSpacing.sm),
                  _ViewModeButton(
                    icon: Icons.grid_view_rounded,
                    label: 'Grid',
                    selected: prefs.viewMode == ContentViewMode.grid,
                    onTap: () => notifier.setViewMode(ContentViewMode.grid),
                  ),
                  const SizedBox(width: RAppSpacing.sm),
                  _ViewModeButton(
                    icon: Icons.account_tree_outlined,
                    label: 'Tree',
                    selected: prefs.viewMode == ContentViewMode.tree,
                    onTap: () => notifier.setViewMode(ContentViewMode.tree),
                  ),
                ],
              ),

              const SizedBox(height: RAppSpacing.lg),
              const Divider(),
              const SizedBox(height: RAppSpacing.sm),

              // 2. Sort order
              Text(
                'Sort By',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: RAppColors.textPrimary,
                ),
              ),
              const SizedBox(height: RAppSpacing.xs),
              ...ContentSortOrder.values.map(
                (order) => RadioListTile<ContentSortOrder>(
                  value: order,
                  groupValue: prefs.sortOrder,
                  title: Text(
                    order.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: RAppColors.textPrimary,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: const Color(0xFFD10047),
                  onChanged: (v) {
                    if (v != null) notifier.setSortOrder(v);
                  },
                ),
              ),

              const SizedBox(height: RAppSpacing.md),
              const Divider(),
              const SizedBox(height: RAppSpacing.sm),

              // 3. Filter
              Text(
                'Display Filter',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: RAppColors.textPrimary,
                ),
              ),
              const SizedBox(height: RAppSpacing.xs),
              ...ContentFilter.values.map(
                (filter) => RadioListTile<ContentFilter>(
                  value: filter,
                  groupValue: prefs.filter,
                  title: Text(
                    filter.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: RAppColors.textPrimary,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: const Color(0xFFD10047),
                  onChanged: (v) {
                    if (v != null) notifier.setFilter(v);
                  },
                ),
              ),

              const SizedBox(height: RAppSpacing.md),
              const Divider(),
              const SizedBox(height: RAppSpacing.sm),

              // 4. Future placeholders (Coming Soon)
              Text(
                'Preferences (Coming Soon)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: RAppColors.textSecondary,
                ),
              ),
              const SizedBox(height: RAppSpacing.xs),
              SwitchListTile(
                value: false,
                onChanged: null,
                title: const Text('Show Archived'),
                subtitle: const Text('Include archived containers and items'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              SwitchListTile(
                value: false,
                onChanged: null,
                title: const Text('Photos Only'),
                subtitle: const Text('Filter to items with photos only'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              SwitchListTile(
                value: false,
                onChanged: null,
                title: const Text('Expiring Items'),
                subtitle: const Text('Show items with upcoming expiration dates'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),

              const SizedBox(height: RAppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD10047),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
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
    final bgColor = selected ? const Color(0xFFD10047) : theme.colorScheme.surface;
    final foregroundColor = selected ? Colors.white : const Color(0xFF374151);
    final borderColor = selected ? Colors.transparent : const Color(0xFFF8D7E3);

    return Expanded(
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(RAppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: const Color(0xFFFCE4EC),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              vertical: RAppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(RAppRadius.md),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: foregroundColor,
                ),
                const SizedBox(height: RAppSpacing.xs),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}