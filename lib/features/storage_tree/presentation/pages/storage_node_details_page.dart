import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/features/storage_tree/presentation/pages/item_details_page.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/enums/node_type.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/widgets/custom_snackbar.dart';
import 'package:find_my_stuff/shared/widgets/safe_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../../../../shared/enums/content_view_mode.dart';
import '../../../../shared/enums/content_sort_order.dart';
import '../../../../shared/enums/content_filter.dart';
import '../../../../shared/providers/content_preferences_provider.dart';
import '../../../../shared/widgets/location_breadcrumb.dart';
import '../../../../shared/widgets/hierarchy_tree_view.dart';
import '../../../../shared/widgets/quick_add_sheet.dart';
import '../../../../shared/widgets/content_page_scaffold.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/speed_dial_fab.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/providers/room_providers.dart';

class StorageNodeDetailsPage extends ConsumerStatefulWidget {
  final String nodeUuid;

  const StorageNodeDetailsPage({super.key, required this.nodeUuid});

  @override
  ConsumerState<StorageNodeDetailsPage> createState() =>
      _StorageNodeDetailsPageState();
}

class _StorageNodeDetailsPageState
    extends ConsumerState<StorageNodeDetailsPage> {
  String _searchQuery = '';

  Future<void> _addChildNodeWithType(StorageNodeEntity parentNode, NodeType selectedType) async {
    final typeLabel = selectedType.name[0].toUpperCase() + selectedType.name.substring(1);
    final name = await QuickAddSheet.show(
      context,
      title: 'Add $typeLabel',
      hintText: selectedType == NodeType.item
          ? 'e.g. Passport, Camera Box'
          : selectedType == NodeType.section
              ? 'e.g. Top Shelf, Left Side'
              : 'e.g. Red Box, Zip Pouch',
      labelText: '$typeLabel Name',
    );

    if (name == null || name.trim().isEmpty) return;

    try {
      final childNode = StorageNodeEntity(
        uuid: const Uuid().v4(),
        roomUuid: parentNode.roomUuid,
        parentUuid: parentNode.uuid,
        nodeType: selectedType.name,
        name: name.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(storageNodeRepositoryProvider).save(childNode);
      ref.read(storageRefreshProvider.notifier).state++;

      if (mounted) {
        AppSnackBar.success(context, '"$name" added');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, "Couldn't add $typeLabel. Please try again.");
      }
    }
  }

  List<StorageNodeEntity> _processNodes(
    List<StorageNodeEntity> nodes,
    ContentPreferences prefs,
  ) {
    // 1. Search Query filtering
    var result = nodes;
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      result = result.where((node) {
        return node.name.toLowerCase().contains(query) ||
            (node.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // 2. Filter
    var filtered = result.where((node) {
      return switch (prefs.filter) {
        ContentFilter.all => true,
        ContentFilter.itemsOnly => node.nodeType == NodeType.item.name,
        ContentFilter.containersOnly => node.nodeType == NodeType.container.name,
        ContentFilter.sectionsOnly => node.nodeType == NodeType.section.name,
      };
    }).toList();

    // 3. Sort
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

    return filtered;
  }

  static _NodeMeta _meta(String nodeType) {
    if (nodeType == NodeType.item.name) {
      return (Icons.label_rounded, RAppColors.primary, 'Item');
    }
    if (nodeType == NodeType.container.name) {
      return (Icons.inventory_2_rounded, RAppColors.accent, 'Container');
    }
    return (Icons.view_agenda_rounded, RAppColors.secondary, 'Section');
  }

  @override
  Widget build(BuildContext context) {
    final nodeAsync = ref.watch(storageNodeProvider(widget.nodeUuid));
    final prefs = ref.watch(contentPreferencesProvider);
    final theme = Theme.of(context);

    return nodeAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text(e.toString())),
      ),
      data: (node) {
        if (node == null) {
          return const Scaffold(
            body: Center(child: Text('Node not found')),
          );
        }

        // Items are terminal — delegate to ItemDetailsPage.
        if (node.nodeType == NodeType.item.name) {
          return ItemDetailsPage(nodeUuid: node.uuid);
        }

        final childrenAsync = ref.watch(childNodesProvider(node.uuid));
        final repo = ref.read(storageNodeRepositoryProvider);
        final roomRepo = ref.read(roomRepositoryProvider);

        // Resolve room and parents chain
        final room = roomRepo.getByUuid(node.roomUuid);
        final roomName = room?.name ?? 'Room';
        final pathNodes = repo.getPathToRoot(node);

        final segments = [
          BreadcrumbSegment(
            label: 'Home',
            isHome: true,
            onTap: () => context.go('/'),
          ),
          BreadcrumbSegment(
            label: roomName,
            onTap: () => context.push('/room/${node.roomUuid}'),
            icon: Icons.meeting_room_rounded,
          ),
          ...pathNodes.map((pNode) {
            final isCurrent = pNode.uuid == node.uuid;
            IconData icon = Icons.view_agenda_rounded;
            if (pNode.nodeType == NodeType.container.name) {
              icon = Icons.inventory_2_outlined;
            } else if (pNode.nodeType == NodeType.item.name) {
              icon = Icons.label_outline;
            }
            return BreadcrumbSegment(
              label: pNode.name,
              icon: icon,
              onTap: isCurrent
                  ? null
                  : () => context.push('/node/${pNode.uuid}'),
            );
          }),
        ];

        return ContentPageScaffold(
          title: node.name,
          searchHintText: 'Search this location...',
          onSearchChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          initialSearchQuery: _searchQuery,
          breadcrumbs: segments,
          floatingActionButton: SpeedDialFAB(
            tooltip: 'Add options',
            items: [
              SpeedDialItem(
                icon: Icons.view_agenda_outlined,
                label: 'New Section',
                onTap: () => _addChildNodeWithType(node, NodeType.section),
              ),
              SpeedDialItem(
                icon: Icons.inventory_2_outlined,
                label: 'New Container',
                onTap: () => _addChildNodeWithType(node, NodeType.container),
              ),
              SpeedDialItem(
                icon: Icons.label_outline,
                label: 'Add Item',
                onTap: () => _addChildNodeWithType(node, NodeType.item),
              ),
            ],
          ),
          child: childrenAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (children) {
              if (children.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.inbox_outlined,
                  title: '"${node.name}" is empty',
                  description: 'Add a section, container, or item to start organizing this space.',
                  actionButton: FilledButton.icon(
                    onPressed: () => _addChildNodeWithType(node, NodeType.item),
                    icon: const Icon(Icons.add),
                    label: AutoSizeText(
                      'Add Item',
                      maxLines: 1,
                      minFontSize: 11,
                      style: context.buttonStyle,
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, 48),
                    ),
                  ),
                );
              }

              final processed = _processNodes(children, prefs);

              if (processed.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.search_off_rounded,
                  title: 'No results found',
                  description: 'Try adjusting your display filters or query.',
                );
              }

              if (prefs.viewMode == ContentViewMode.tree) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: context.spacingM),
                  child: HierarchyTreeView(rootUuid: node.uuid),
                );
              }

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
                  itemCount: processed.length,
                  itemBuilder: (context, index) {
                    final child = processed[index];
                    final (icon, color, label) = _meta(child.nodeType);

                    return Card(
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: context.borderRadiusL,
                        side: const BorderSide(color: Color(0xFFF8D7E3), width: 0.8),
                      ),
                      elevation: 2,
                      shadowColor: Colors.black.withValues(alpha: 0.1),
                      child: InkWell(
                        onTap: () => context.push('/node/${child.uuid}'),
                        hoverColor: const Color(0xFFFFF5F8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SafeImageWidget(
                                photoPath: child.photoPath,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: Container(
                                  color: const Color(0xFFFFF5F8),
                                  child: Center(
                                    child: Icon(
                                      icon,
                                      color: color,
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
                                  AutoSizeText(
                                    child.name,
                                    style: context.titleStyle.copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    minFontSize: 11,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: context.spacingXS),
                                  Text(
                                    label,
                                    style: context.labelStyle.copyWith(
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }

              // Default List View
              return ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingS),
                itemCount: processed.length,
                separatorBuilder: (_, _) => SizedBox(height: context.spacingS),
                itemBuilder: (context, index) {
                  final child = processed[index];
                  return _ChildNodeCard(
                    node: child,
                    onTap: () => context.push('/node/${child.uuid}'),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _ChildNodeCard extends StatelessWidget {
  final StorageNodeEntity node;
  final VoidCallback onTap;

  const _ChildNodeCard({required this.node, required this.onTap});

  static _NodeMeta _meta(String nodeType) {
    if (nodeType == NodeType.item.name) {
      return (Icons.label_rounded, RAppColors.primary, 'Item');
    }
    if (nodeType == NodeType.container.name) {
      return (Icons.inventory_2_rounded, RAppColors.accent, 'Container');
    }
    return (Icons.view_agenda_rounded, RAppColors.secondary, 'Section');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color, label) = _meta(node.nodeType);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: context.borderRadiusM,
        side: const BorderSide(color: Color(0xFFF8D7E3), width: 0.6),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: context.borderRadiusM,
        hoverColor: const Color(0xFFFFF5F8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacingM,
            vertical: context.spacingS + 4,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: SafeImageWidget(
                  photoPath: node.photoPath,
                  borderRadius: context.borderRadiusS,
                  placeholder: Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: context.borderRadiusS,
                    ),
                    child: Icon(icon, color: color, size: context.iconSmall + 4),
                  ),
                ),
              ),
              SizedBox(width: context.spacingS + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      node.name,
                      style: context.titleStyle.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      minFontSize: 12,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.spacingXS),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.spacingXS + 2,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: context.borderRadiusS,
                      ),
                      child: Text(
                        label,
                        style: context.labelStyle.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: context.iconMedium),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _NodeMeta = (IconData, Color, String);