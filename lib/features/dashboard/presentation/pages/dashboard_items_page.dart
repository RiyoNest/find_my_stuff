// File: lib/features/dashboard/presentation/pages/dashboard_items_page.dart

import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:find_my_stuff/shared/widgets/safe_image_widget.dart';
import 'package:find_my_stuff/shared/widgets/location_breadcrumb.dart';
import 'package:find_my_stuff/shared/widgets/content_page_scaffold.dart';
import 'package:find_my_stuff/shared/widgets/empty_state_widget.dart';
import 'package:find_my_stuff/shared/enums/content_view_mode.dart';
import 'package:find_my_stuff/shared/enums/content_sort_order.dart';
import 'package:find_my_stuff/shared/enums/content_filter.dart';
import 'package:find_my_stuff/shared/providers/content_preferences_provider.dart';
import 'package:find_my_stuff/shared/enums/node_type.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';

class DashboardItemsPage extends ConsumerStatefulWidget {
  final String type;

  const DashboardItemsPage({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<DashboardItemsPage> createState() => _DashboardItemsPageState();
}

class _DashboardItemsPageState extends ConsumerState<DashboardItemsPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(storageNodeRepositoryProvider);
    final prefs = ref.watch(contentPreferencesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Map type to title
    final String title = switch (widget.type) {
      'all' => 'All Items',
      'important' => 'Important Items',
      'expired' => 'Expired Items',
      'expiring' => 'Expiring Items',
      _ => 'Items',
    };

    final AsyncValue<List<StorageNodeEntity>> itemsAsync = switch (widget.type) {
      'all' => ref.watch(allItemsProvider),
      'important' => ref.watch(importantItemsProvider),
      'expired' => ref.watch(expiredItemsProvider),
      'expiring' => ref.watch(expiringItemsProvider),
      _ => const AsyncValue.data([]),
    };

    final segments = [
      BreadcrumbSegment(
        label: 'Home',
        isHome: true,
        onTap: () => context.go('/'),
      ),
      BreadcrumbSegment(
        label: title,
        icon: widget.type == 'important'
            ? Icons.star_rounded
            : widget.type == 'all'
                ? Icons.inventory_2_outlined
                : Icons.timelapse_rounded,
      ),
    ];

    return ContentPageScaffold(
      title: title,
      searchHintText: 'Search items...',
      onSearchChanged: (val) {
        setState(() {
          _searchQuery = val;
        });
      },
      initialSearchQuery: _searchQuery,
      breadcrumbs: segments,
      child: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.inventory_2_outlined,
              title: 'No items found',
              description: 'There is nothing to display in this list.',
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

          // Apply content preferences filter
          filtered = filtered.where((node) {
            return switch (prefs.filter) {
              ContentFilter.all => true,
              ContentFilter.itemsOnly => node.nodeType == NodeType.item.name,
              ContentFilter.containersOnly => node.nodeType == NodeType.container.name,
              ContentFilter.sectionsOnly => node.nodeType == NodeType.section.name,
            };
          }).toList();

          // Apply content preferences sort
          filtered.sort((a, b) {
            return switch (prefs.sortOrder) {
              ContentSortOrder.nameAsc =>
                a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              ContentSortOrder.nameDesc =>
                b.name.toLowerCase().compareTo(a.name.toLowerCase()),
              ContentSortOrder.newestFirst => b.createdAt.compareTo(a.createdAt),
              ContentSortOrder.oldestFirst => a.createdAt.compareTo(b.createdAt),
              ContentSortOrder.recentlyViewed =>
                (b.viewedAt ?? DateTime(0)).compareTo(a.viewedAt ?? DateTime(0)),
            };
          });

          if (filtered.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.search_off_rounded,
              title: 'No search results',
              description: 'No items in this dashboard match your query or filters.',
            );
          }

          // Grid View rendering
          if (prefs.viewMode == ContentViewMode.grid) {
            final cols = context.columns;
            return GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingS),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: context.spacingS + 4,
                crossAxisSpacing: context.spacingS + 4,
                childAspectRatio: context.itemCardAspectRatio,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final path = repo.buildPath(item);

                return _ResponsiveDashboardItemCard(
                  item: item,
                  path: path,
                  isDark: isDark,
                  theme: theme,
                );
              },
            );
          }

          // Default / List View rendering
          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingS),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => SizedBox(height: context.spacingS),
            itemBuilder: (_, index) {
              final item = filtered[index];
              final path = repo.buildPath(item);

              return Card(
                margin: EdgeInsets.zero,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: context.borderRadiusM,
                  side: BorderSide(
                    color: isDark ? theme.colorScheme.outline.withOpacity(0.3) : const Color(0xFFF8D7E3),
                    width: 0.6,
                  ),
                ),
                child: ListTile(
                  onTap: () => context.push('/node/${item.uuid}'),
                  shape: RoundedRectangleBorder(borderRadius: context.borderRadiusM),
                  hoverColor: const Color(0xFFFFF5F8),
                  leading: SizedBox(
                    width: 40,
                    height: 40,
                    child: SafeImageWidget(
                      photoPath: item.photoPath,
                      borderRadius: context.borderRadiusS,
                      placeholder: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5F8),
                          borderRadius: context.borderRadiusS,
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: const Color(0xFFD10047),
                          size: context.iconSmall + 4,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: context.titleStyle.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    path.isNotEmpty ? path : 'No location path',
                    style: context.bodyMediumStyle.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.isImportant)
                        Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: context.iconSmall + 4,
                        ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: context.iconMedium),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ResponsiveDashboardItemCard extends StatefulWidget {
  final StorageNodeEntity item;
  final String path;
  final bool isDark;
  final ThemeData theme;

  const _ResponsiveDashboardItemCard({
    required this.item,
    required this.path,
    required this.isDark,
    required this.theme,
  });

  @override
  State<_ResponsiveDashboardItemCard> createState() => _ResponsiveDashboardItemCardState();
}

class _ResponsiveDashboardItemCardState extends State<_ResponsiveDashboardItemCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.00,
        duration: const Duration(milliseconds: 150),
        child: AnimatedPhysicalModel(
          duration: const Duration(milliseconds: 150),
          shape: BoxShape.rectangle,
          borderRadius: context.borderRadiusL,
          elevation: _isHovered ? 4 : 2,
          color: widget.theme.cardColor,
          shadowColor: Colors.black.withOpacity(0.1),
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: context.borderRadiusL,
              side: BorderSide(
                color: widget.isDark
                    ? widget.theme.colorScheme.outline.withOpacity(0.3)
                    : const Color(0xFFF8D7E3),
                width: 0.8,
              ),
            ),
            child: InkWell(
              onTap: () => context.push('/node/${widget.item.uuid}'),
              hoverColor: const Color(0xFFFFF5F8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SafeImageWidget(
                      photoPath: widget.item.photoPath,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        color: const Color(0xFFFFF5F8),
                        child: Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: const Color(0xFFD10047),
                            size: context.iconLarge,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(context.spacingS + 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AutoSizeText(
                                widget.item.name,
                                style: context.titleStyle.copyWith(
                                  color: widget.theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                minFontSize: 11,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.item.isImportant)
                              Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: context.iconSmall,
                              ),
                          ],
                        ),
                        SizedBox(height: context.spacingXS),
                        Text(
                          widget.path.isNotEmpty ? widget.path : 'No location path',
                          style: context.bodySmallStyle.copyWith(
                            color: widget.theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
