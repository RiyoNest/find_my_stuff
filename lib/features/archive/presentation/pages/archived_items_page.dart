// File: lib/features/archive/presentation/pages/archived_items_page.dart

import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/shared/widgets/safe_image_widget.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/widgets/custom_snackbar.dart';
import 'package:find_my_stuff/shared/widgets/location_breadcrumb.dart';
import 'package:find_my_stuff/shared/widgets/content_page_scaffold.dart';
import 'package:find_my_stuff/shared/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';

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
            padding: context.pagePadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: context.iconXL,
                  color: themeErrorColor(context),
                ),
                SizedBox(height: context.spacingS),
                Text(
                  "Couldn't load archived items",
                  style: context.titleStyle,
                ),
                SizedBox(height: context.spacingM),
                TextButton.icon(
                  onPressed: () => ref.invalidate(archivedItemsProvider),
                  icon: const Icon(Icons.refresh),
                  label: Text('Retry', style: context.buttonStyle),
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

          final cols = context.columns;
          return GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingS),
            itemCount: filtered.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: context.spacingS + 4,
              crossAxisSpacing: context.spacingS + 4,
              childAspectRatio: cols == 1 ? 3.5 : (cols == 2 ? 1.8 : 1.3),
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
        borderRadius: context.borderRadiusM,
        side: const BorderSide(color: Color(0xFFF8D7E3), width: 0.6),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacingM,
          vertical: context.spacingS + 4,
        ),
        child: Row(
          children: [
            // Thumbnail or icon
            SizedBox(
              width: 40,
              height: 40,
              child: SafeImageWidget(
                photoPath: item.photoPath,
                borderRadius: context.borderRadiusS,
                placeholder: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F8),
                    borderRadius: context.borderRadiusS,
                  ),
                  child: Icon(
                    Icons.archive_outlined,
                    color: const Color(0xFFD10047),
                    size: context.iconSmall + 4,
                  ),
                ),
              ),
            ),
            SizedBox(width: context.spacingS + 4),

            // Name + path
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AutoSizeText(
                    item.name,
                    style: context.titleStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    minFontSize: 11,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (path.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      path,
                      style: context.bodyMediumStyle.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (item.isImportant) ...[
                    SizedBox(height: context.spacingXS),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.spacingXS + 2,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: RAppColors.accent.withOpacity(0.12),
                        borderRadius: context.borderRadiusS,
                      ),
                      child: Text(
                        'Important',
                        style: context.labelStyle.copyWith(
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
              icon: Icon(Icons.unarchive_outlined, size: context.iconMedium),
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