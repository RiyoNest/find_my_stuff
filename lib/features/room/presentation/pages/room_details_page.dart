// File: lib/features/room/presentation/pages/room_details_page.dart

import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/room_providers.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/widgets/delete_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../../../../core/constants/app_colours.dart';
import '../../../../shared/enums/node_type.dart';
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
import '../../../../shared/widgets/safe_image_widget.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../core/utils/validation_helpers.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/loading_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';

class RoomDetailsPage extends ConsumerWidget {
  final String roomUuid;

  const RoomDetailsPage({
    super.key,
    required this.roomUuid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomDetailsProvider(roomUuid));

    return roomAsync.when(
      loading: () => const Scaffold(
        body: LoadingStateWidget(type: LoadingType.list),
      ),
      error: (e, _) => Scaffold(
        body: ErrorStateWidget(
          description: "We couldn't load this room.",
          onRetry: () => ref.invalidate(roomDetailsProvider(roomUuid)),
        ),
      ),
      data: (room) {
        if (room == null) {
          return Scaffold(
            body: ErrorStateWidget(
              description: 'Room not found',
              secondaryAction: TextButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ),
          );
        }

        return _RoomDetailsContent(
          roomUuid: roomUuid,
          roomName: room.name,
        );
      },
    );
  }
}

class _RoomDetailsContent extends ConsumerStatefulWidget {
  final String roomUuid;
  final String roomName;

  const _RoomDetailsContent({
    required this.roomUuid,
    required this.roomName,
  });

  @override
  ConsumerState<_RoomDetailsContent> createState() =>
      _RoomDetailsContentState();
}

class _RoomDetailsContentState extends ConsumerState<_RoomDetailsContent> {
  String _searchQuery = '';

  Future<void> _addStorageLocation() async {
    final name = await QuickAddSheet.show(
      context,
      title: 'Add Location',
      hintText: 'e.g. Wardrobe, Pantry',
      labelText: 'Location Name',
      maxLength: ValidationHelpers.maxRoomNameLength,
      validator: ValidationHelpers.validateRoomName,
    );

    if (name == null || name.trim().isEmpty) return;

    try {
      final node = StorageNodeEntity(
        uuid: const Uuid().v4(),
        roomUuid: widget.roomUuid,
        parentUuid: null,
        nodeType: NodeType.storageLocation.name,
        name: name.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repo = ref.read(storageNodeRepositoryProvider);
      repo.save(node);
      ref.read(storageRefreshProvider.notifier).state++;

      if (mounted) {
        AppSnackBar.success(context, '"$name" added');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, "Couldn't add location. Please try again.");
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

  @override
  Widget build(BuildContext context) {
    final storageAsync = ref.watch(storageLocationsProvider(widget.roomUuid));
    final prefs = ref.watch(contentPreferencesProvider);
    final theme = Theme.of(context);

    final segments = [
      BreadcrumbSegment(
        label: 'Home',
        isHome: true,
        onTap: () => context.go('/'),
      ),
      BreadcrumbSegment(
        label: widget.roomName,
        icon: Icons.meeting_room_rounded,
      ),
    ];

    return ContentPageScaffold(
      title: widget.roomName,
      searchHintText: 'Search this room...',
      onSearchChanged: (val) {
        setState(() {
          _searchQuery = val;
        });
      },
      initialSearchQuery: _searchQuery,
      breadcrumbs: segments,
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          tooltip: 'Delete Room',
          onPressed: () {
            DeleteAction.execute(
              context: context,
              ref: ref,
              nodeType: 'room',
              uuid: widget.roomUuid,
              displayName: widget.roomName,
            );
          },
        ),
      ],
      floatingActionButton: SpeedDialFAB(
        tooltip: 'Add options',
        items: [
          SpeedDialItem(
            icon: Icons.inventory_2_outlined,
            label: 'New Location',
            onTap: _addStorageLocation,
          ),
          SpeedDialItem(
            icon: Icons.label_outline,
            label: 'Add Item',
            onTap: () => context.push('/quick-add'),
          ),
        ],
      ),
      child: storageAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (nodes) {
          final processed = _processNodes(nodes, prefs);

          if (nodes.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.inventory_2_outlined,
              title: 'No locations yet',
              description: 'Add a wardrobe, drawer, or shelf to start organizing.',
              actionButton: FilledButton.icon(
                onPressed: _addStorageLocation,
                icon: const Icon(Icons.add),
                label: const Text('Add Location'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD10047),
                ),
              ),
            );
          }

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
              child: HierarchyTreeView(rootUuid: widget.roomUuid),
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
                final node = processed[index];
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
                    onTap: () => context.push('/node/${node.uuid}'),
                    hoverColor: const Color(0xFFFFF5F8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SafeImageWidget(
                            photoPath: node.photoPath,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: Container(
                              color: const Color(0xFFFFF5F8),
                              child: Center(
                                child: Icon(
                                  node.nodeType == NodeType.container.name
                                      ? Icons.inventory_2_outlined
                                      : Icons.meeting_room_outlined,
                                  size: context.iconLarge,
                                  color: const Color(0xFFD10047),
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
                                node.name,
                                style: context.titleStyle.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                minFontSize: 11,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: context.spacingXS),
                              Text(
                                node.nodeType == 'storageLocation'
                                    ? 'Location'
                                    : node.nodeType[0].toUpperCase() + node.nodeType.substring(1),
                                style: context.bodySmallStyle.copyWith(
                                  color: RAppColors.textSecondary,
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
              final node = processed[index];
              return Card(
                margin: EdgeInsets.zero,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: context.borderRadiusM,
                  side: const BorderSide(color: Color(0xFFF8D7E3), width: 0.6),
                ),
                child: ListTile(
                  onTap: () => context.push('/node/${node.uuid}'),
                  shape: RoundedRectangleBorder(borderRadius: context.borderRadiusM),
                  hoverColor: const Color(0xFFFFF5F8),
                  leading: SizedBox(
                    width: 40,
                    height: 40,
                    child: SafeImageWidget(
                      photoPath: node.photoPath,
                      borderRadius: context.borderRadiusS,
                      placeholder: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5F8),
                          borderRadius: context.borderRadiusS,
                        ),
                        child: Icon(
                          node.nodeType == 'storageLocation'
                              ? Icons.meeting_room_outlined
                              : Icons.inventory_2_outlined,
                          color: const Color(0xFFD10047),
                          size: context.iconSmall + 4,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    node.name,
                    style: context.titleStyle.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    node.nodeType == 'storageLocation'
                        ? 'Location'
                        : node.nodeType[0].toUpperCase() + node.nodeType.substring(1),
                    style: context.bodyMediumStyle.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey[400],
                    size: context.iconMedium,
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