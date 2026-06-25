import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../enums/content_view_mode.dart';
import '../enums/content_sort_order.dart';
import '../enums/content_filter.dart';
import '../providers/content_preferences_provider.dart';

class ViewOptionsSheet extends ConsumerWidget {
  const ViewOptionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    final theme = Theme.of(context);
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
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
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: RAppSpacing.md + 4),

              // 1. View Mode (SegmentedButton)
              Text(
                'View As',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: RAppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ContentViewMode>(
                  segments: const [
                    ButtonSegment(
                      value: ContentViewMode.list,
                      icon: Icon(Icons.list_rounded),
                      label: Text('List'),
                    ),
                    ButtonSegment(
                      value: ContentViewMode.grid,
                      icon: Icon(Icons.grid_view_rounded),
                      label: Text('Grid'),
                    ),
                    ButtonSegment(
                      value: ContentViewMode.tree,
                      icon: Icon(Icons.account_tree_outlined),
                      label: Text('Tree'),
                    ),
                  ],
                  selected: {prefs.viewMode},
                  onSelectionChanged: (selected) {
                    notifier.setViewMode(selected.first);
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFFD10047);
                      }
                      return theme.colorScheme.surfaceContainer;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return theme.colorScheme.onSurface;
                    }),
                  ),
                ),
              ),

              const SizedBox(height: RAppSpacing.lg),
              const Divider(),
              const SizedBox(height: RAppSpacing.sm),

              // 2. Sort Order
              Text(
                'Sort By',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
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
                      color: theme.colorScheme.onSurface,
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

              // 3. Filter Options
              Text(
                'Display Filter',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
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
                      color: theme.colorScheme.onSurface,
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

              // 4. Preferences (Coming Soon Toggles)
              Text(
                'Preferences (Coming Soon)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: RAppSpacing.xs),
              SwitchListTile(
                value: false,
                onChanged: null,
                title: Text(
                  'Show Archived',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                ),
                subtitle: Text(
                  'Include archived containers and items',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              SwitchListTile(
                value: false,
                onChanged: null,
                title: Text(
                  'Photos Only',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                ),
                subtitle: Text(
                  'Filter to items with photos only',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              SwitchListTile(
                value: false,
                onChanged: null,
                title: Text(
                  'Expiring Soon',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                ),
                subtitle: Text(
                  'Show items with upcoming expiration dates',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              SwitchListTile(
                value: false,
                onChanged: null,
                title: Text(
                  'Recently Added',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                ),
                subtitle: Text(
                  'Highlight items created within the last 48 hours',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
                ),
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