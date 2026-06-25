// File: lib/shared/widgets/content_toolbar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../enums/content_view_mode.dart';
import '../enums/content_sort_order.dart';
import '../providers/content_preferences_provider.dart';
import 'view_options_sheet.dart';

class ContentToolbar extends ConsumerWidget {
  const ContentToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prefs = ref.watch(contentPreferencesProvider);
    final notifier = ref.read(contentPreferencesProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Left: Premium Segmented View Mode selector
          Expanded(
            child: Row(
              children: [
                _buildSegmentButton(
                  context,
                  icon: Icons.list_rounded,
                  label: 'List',
                  isSelected: prefs.viewMode == ContentViewMode.list,
                  onTap: () => notifier.setViewMode(ContentViewMode.list),
                ),
                const SizedBox(width: 6),
                _buildSegmentButton(
                  context,
                  icon: Icons.grid_view_rounded,
                  label: 'Grid',
                  isSelected: prefs.viewMode == ContentViewMode.grid,
                  onTap: () => notifier.setViewMode(ContentViewMode.grid),
                ),
                const SizedBox(width: 6),
                _buildSegmentButton(
                  context,
                  icon: Icons.account_tree_outlined,
                  label: 'Tree',
                  isSelected: prefs.viewMode == ContentViewMode.tree,
                  onTap: () => notifier.setViewMode(ContentViewMode.tree),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Right: Sort & Filter options bottom sheet trigger
          InkWell(
            onTap: () => ViewOptionsSheet.show(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF8D7E3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: Color(0xFFD10047),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    prefs.sortOrder.shortLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFD10047),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final bgColor = isSelected ? const Color(0xFFD10047) : theme.colorScheme.surface;
    final foregroundColor = isSelected ? Colors.white : const Color(0xFF374151);
    final borderColor = isSelected ? Colors.transparent : const Color(0xFFF8D7E3);

    return Expanded(
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          hoverColor: const Color(0xFFFCE4EC),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: foregroundColor,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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