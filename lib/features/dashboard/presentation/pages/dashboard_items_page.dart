// File: lib/features/dashboard/presentation/pages/dashboard_items_page.dart

import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:find_my_stuff/shared/widgets/safe_image_widget.dart';
import 'package:find_my_stuff/shared/widgets/location_breadcrumb.dart';
import 'package:find_my_stuff/shared/widgets/content_page_scaffold.dart';
import 'package:find_my_stuff/shared/widgets/empty_state_widget.dart';
import 'package:find_my_stuff/core/constants/app_colours.dart';

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

    // Map type to title and provider
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

          if (filtered.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.search_off_rounded,
              title: 'No search results',
              description: 'No items in this dashboard match your query.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final item = filtered[index];
              final path = repo.buildPath(item);

              return Card(
                margin: EdgeInsets.zero,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFF8D7E3), width: 0.6),
                ),
                child: ListTile(
                  onTap: () => context.push('/node/${item.uuid}'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  hoverColor: const Color(0xFFFFF5F8),
                  leading: SizedBox(
                    width: 44,
                    height: 44,
                    child: SafeImageWidget(
                      photoPath: item.photoPath,
                      borderRadius: BorderRadius.circular(8),
                      placeholder: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5F8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: Color(0xFFD10047),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: RAppColors.textPrimary,
                        ),
                  ),
                  subtitle: Text(
                    path.isNotEmpty ? path : 'No location path',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: RAppColors.textSecondary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.isImportant)
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
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
