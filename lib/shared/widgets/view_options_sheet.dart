import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.radiusL),
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
          left: context.spacingL,
          right: context.spacingL,
          bottom: context.spacingL + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Center(
                child: AutoSizeText(
                  'Display Options',
                  maxLines: 1,
                  minFontSize: 14,
                  style: context.titleStyle.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              SizedBox(height: context.spacingM + 4),

              // 1. View Mode (SegmentedButton)
              Text(
                'View As',
                style: context.subtitleStyle.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: context.spacingS),
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

              SizedBox(height: context.spacingL),
              const Divider(),
              SizedBox(height: context.spacingS),

              // 2. Sort Order
              Text(
                'Sort By',
                style: context.subtitleStyle.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: context.spacingXS),
              RadioGroup<ContentSortOrder>(
                groupValue: prefs.sortOrder,
                onChanged: (v) {
                  if (v != null) notifier.setSortOrder(v);
                },
                child: Column(
                  children: ContentSortOrder.values.map(
                    (order) => RadioListTile<ContentSortOrder>(
                      value: order,
                      title: Text(
                        order.label,
                        style: context.bodyStyle.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeColor: const Color(0xFFD10047),
                    ),
                  ).toList(),
                ),
              ),

              SizedBox(height: context.spacingM),
              const Divider(),
              SizedBox(height: context.spacingS),

              // 3. Filter Options
              Text(
                'Display Filter',
                style: context.subtitleStyle.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: context.spacingXS),
              RadioGroup<ContentFilter>(
                groupValue: prefs.filter,
                onChanged: (v) {
                  if (v != null) notifier.setFilter(v);
                },
                child: Column(
                  children: ContentFilter.values.map(
                    (filter) => RadioListTile<ContentFilter>(
                      value: filter,
                      title: Text(
                        filter.label,
                        style: context.bodyStyle.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeColor: const Color(0xFFD10047),
                    ),
                  ).toList(),
                ),
              ),

              SizedBox(height: context.spacingM),
              const Divider(),
              SizedBox(height: context.spacingS),

              // 4. Preferences (Coming Soon Toggles)
              Text(
                'Preferences (Coming Soon)',
                style: context.subtitleStyle.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: context.spacingXS),
              SwitchListTile(
                value: false,
                onChanged: null,
                title: Text(
                  'Show Archived',
                  style: context.bodyStyle.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                ),
                subtitle: Text(
                  'Include archived containers and items',
                  style: context.bodySmallStyle.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              SwitchListTile(
                value: false,
                onChanged: null,
                title: Text(
                  'Photos Only',
                  style: context.bodyStyle.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                ),
                subtitle: Text(
                  'Filter to items with photos only',
                  style: context.bodySmallStyle.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              SwitchListTile(
                value: false,
                onChanged: null,
                title: Text(
                  'Expiring Soon',
                  style: context.bodyStyle.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                ),
                subtitle: Text(
                  'Show items with upcoming expiration dates',
                  style: context.bodySmallStyle.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              SwitchListTile(
                value: false,
                onChanged: null,
                title: Text(
                  'Recently Added',
                  style: context.bodyStyle.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                ),
                subtitle: Text(
                  'Highlight items created within the last 48 hours',
                  style: context.bodySmallStyle.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),

              SizedBox(height: context.spacingL),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD10047),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: context.borderRadiusM,
                    ),
                  ),
                  child: AutoSizeText(
                    'Done',
                    maxLines: 1,
                    minFontSize: 12,
                    style: context.buttonStyle.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}