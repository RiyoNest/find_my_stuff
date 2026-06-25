// File: lib/features/archive/presentation/pages/archived_items_page.dart

import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:find_my_stuff/shared/widgets/safe_image_widget.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/widgets/custom_snackbar.dart';
import 'package:find_my_stuff/shared/widgets/location_breadcrumb.dart';
import 'package:find_my_stuff/shared/widgets/content_page_scaffold.dart';
import 'package:find_my_stuff/shared/widgets/empty_state_widget.dart';
import 'package:find_my_stuff/shared/utils/responsive_grid_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ArchivedItemsPage extends ConsumerStatefulWidget {
  const ArchivedItemsPage({super.key});

  @override
  ConsumerState<ArchivedItemsPage> createState() => _ArchivedItemsPageState();
}

class _ArchivedItemsPageState extends ConsumerState<ArchivedItemsPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final archivedAsync = ref.watch(archivedItemsProvider);
    final repo = ref.read(storageNodeRepositoryProvider);

    final segments = [
      BreadcrumbSegment(
        label: 'Home',
        isHome: true,
        onTap: () => context.go('/'),
      ),
      const BreadcrumbSegment(
        label: 'Archive',
        icon: Icons.archive_outlined,
      ),
    ];

    return ContentPageScaffold(
      title: 'Archived Items',
      searchHintText: 'Search archived items...',
      onSearchChanged: (val) {
        setState(() {
          _searchQuery = val;
        });
      },
      initialSearchQuery: _searchQuery,
      breadcrumbs: segments,
      child: archivedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(RAppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 40,
                  color: themeErrorColor(context),
                ),
                const SizedBox(height: RAppSpacing.sm),
                Text(
                  "Couldn't load archived items",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: RAppSpacing.md),
                TextButton.icon(
                  onPressed: () => ref.invalidate(archivedItemsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.archive_outlined,
              title: 'Nothing archived yet',
              description: 'Items you archive will appear here. You can restore them at any time.',
            );
          }

          // Apply contextual filtering
          var filtered = items;
          if (_searchQuery.trim().isNotEmpty) {
            final query = _searchQuery.toLowerCase().trim();
            filtered = filtered.where((item) {
              final path = repo.buildPath(item).toLowerCase();
              return item.name.toLowerCase().contains(query) ||
                  (item.description?.toLowerCase().contains(query) ?? false) ||
                  path.contains(query);
            }).toList();
          }

          if (filtered.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.search_off_rounded,
              title: 'No results found',
              description: 'Try adjusting your search criteria.',
            );
          }

          final cols = ResponsiveLayout.getColumns(context);
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: cols == 1 ? 3.5 : 1.3,
            ),
            itemBuilder: (_, index) {
              final item = filtered[index];
              return _ArchivedItemTile(item: item);
            },
          );
        },
      ),
    );
  }

  Color themeErrorColor(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }
}

class _ArchivedItemTile extends ConsumerWidget {
  final StorageNodeEntity item;

  const _ArchivedItemTile({required this.item});

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(storageNodeRepositoryProvider);
      repo.restoreItem(item.uuid);
      ref.invalidate(archivedItemsProvider);
      ref.read(storageRefreshProvider.notifier).state++;

      if (context.mounted) {
        AppSnackBar.success(context, '"${item.name}" restored');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, "Couldn't restore item. Please try again.");
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.read(storageNodeRepositoryProvider);
    final path = repo.buildPath(item);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFF8D7E3), width: 0.6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RAppSpacing.md,
          vertical: RAppSpacing.sm + 4,
        ),
        child: Row(
          children: [
            // Thumbnail or icon
            SafeImageWidget(
              photoPath: item.photoPath,
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(8),
              placeholder: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.archive_outlined,
                  color: Color(0xFFD10047),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: RAppSpacing.sm + 4),

            // Name + path
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (path.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      path,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (item.isImportant) ...[
                    const SizedBox(height: RAppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: RAppSpacing.xs + 2,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: RAppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(RAppRadius.sm),
                      ),
                      child: Text(
                        'Important',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: RAppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Restore button
            IconButton(
              icon: const Icon(Icons.unarchive_outlined),
              tooltip: 'Restore',
              color: const Color(0xFFD10047),
              onPressed: () => _restore(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}