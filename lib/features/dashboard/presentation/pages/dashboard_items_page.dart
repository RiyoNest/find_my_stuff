// File: lib/features/dashboard/presentation/pages/dashboard_items_page.dart

import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/repositories/storage_node_repository.dart';
import 'package:find_my_stuff/shared/widgets/loading_state_widget.dart';
import 'package:find_my_stuff/shared/widgets/error_state_widget.dart';
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
        loading: () => const LoadingStateWidget(type: LoadingType.list),
        error: (err, _) => ErrorStateWidget(
          description: "We couldn't retrieve your inventory.",
          onRetry: () {
            switch (widget.type) {
              case 'all':
                ref.invalidate(allItemsProvider);
                break;
              case 'important':
                ref.invalidate(importantItemsProvider);
                break;
              case 'expired':
                ref.invalidate(expiredItemsProvider);
                break;
              case 'expiring':
                ref.invalidate(expiringItemsProvider);
                break;
            }
          },
        ),
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

          if (widget.type == 'expiring' || widget.type == 'expired') {
            return _buildGroupedTimeline(context, filtered, repo, isDark, theme);
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
            separatorBuilder: (_, _) => SizedBox(height: context.spacingS),
            itemBuilder: (_, index) {
              final item = filtered[index];
              final path = repo.buildPath(item);

              return Card(
                margin: EdgeInsets.zero,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: context.borderRadiusM,
                  side: BorderSide(
                    color: isDark ? theme.colorScheme.outline.withValues(alpha: 0.3) : const Color(0xFFF8D7E3),
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

  Widget _buildGroupedTimeline(
    BuildContext context,
    List<StorageNodeEntity> items,
    StorageNodeRepository repo,
    bool isDark,
    ThemeData theme,
  ) {
    final grouped = _groupByExpiryTimeline(items);

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingS),
      children: grouped.entries.map((entry) {
        final groupTitle = entry.key;
        final groupItems = entry.value;

        final (badgeBg, badgeText) = switch (groupTitle) {
          'Expired' => (theme.colorScheme.errorContainer, theme.colorScheme.error),
          'Today' => (theme.colorScheme.primaryContainer, theme.colorScheme.primary),
          'Tomorrow' => (theme.colorScheme.secondaryContainer, theme.colorScheme.secondary),
          'This Week' => (theme.colorScheme.tertiaryContainer, theme.colorScheme.tertiary),
          'This Month' => (Colors.transparent, theme.colorScheme.outline),
          _ => (theme.colorScheme.surfaceContainerHighest, theme.colorScheme.onSurfaceVariant),
        };

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: context.borderRadiusM,
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: ExpansionTile(
            key: PageStorageKey<String>(groupTitle),
            initiallyExpanded: true,
            title: Row(
              children: [
                Text(
                  groupTitle,
                  style: context.titleStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    border: groupTitle == 'This Month' ? Border.all(color: theme.colorScheme.outline) : null,
                    borderRadius: context.borderRadiusPill,
                  ),
                  child: Text(
                    '${groupItems.length}',
                    style: context.labelStyle.copyWith(
                      color: badgeText,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            childrenPadding: EdgeInsets.all(context.spacingS),
            children: groupItems.map((item) {
              final path = repo.buildPath(item);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Card(
                  margin: EdgeInsets.zero,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: context.borderRadiusM,
                    side: BorderSide(
                      color: isDark ? theme.colorScheme.outline.withValues(alpha: 0.3) : const Color(0xFFF8D7E3),
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          path.isNotEmpty ? path : 'No location path',
                          style: context.bodySmallStyle.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.expiryDate != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.event, size: 12, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Expires: ${item.expiryDate!.day}/${item.expiryDate!.month}/${item.expiryDate!.year}',
                                style: context.captionStyle.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            border: groupTitle == 'This Month' ? Border.all(color: theme.colorScheme.outline) : null,
                            borderRadius: context.borderRadiusS,
                          ),
                          child: Text(
                            groupTitle,
                            style: context.captionStyle.copyWith(
                              color: badgeText,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: context.iconMedium),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Map<String, List<StorageNodeEntity>> _groupByExpiryTimeline(List<StorageNodeEntity> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final endOfWeek = today.add(const Duration(days: 7));
    final endOfMonth = today.add(const Duration(days: 30));

    final groups = <String, List<StorageNodeEntity>>{
      'Expired': [],
      'Today': [],
      'Tomorrow': [],
      'This Week': [],
      'This Month': [],
      'Later': [],
    };

    for (final item in items) {
      if (item.expiryDate == null) continue;
      final exp = item.expiryDate!;
      final expDate = DateTime(exp.year, exp.month, exp.day);

      if (expDate.isBefore(today)) {
        groups['Expired']!.add(item);
      } else if (expDate == today) {
        groups['Today']!.add(item);
      } else if (expDate == tomorrow) {
        groups['Tomorrow']!.add(item);
      } else if (expDate.isBefore(endOfWeek)) {
        groups['This Week']!.add(item);
      } else if (expDate.isBefore(endOfMonth)) {
        groups['This Month']!.add(item);
      } else {
        groups['Later']!.add(item);
      }
    }

    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
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
          shadowColor: Colors.black.withValues(alpha: 0.1),
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: context.borderRadiusL,
              side: BorderSide(
                color: widget.isDark
                    ? widget.theme.colorScheme.outline.withValues(alpha: 0.3)
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
