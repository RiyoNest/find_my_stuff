import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/entities/room_entity.dart';
import 'package:find_my_stuff/shared/entities/place_entity.dart';
import 'package:find_my_stuff/shared/enums/node_type.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/providers/room_providers.dart';
import 'package:find_my_stuff/shared/providers/storage_path_provider.dart';
import 'package:find_my_stuff/shared/repositories/place_repository.dart';
import 'package:find_my_stuff/shared/widgets/custom_snackbar.dart';
import 'package:find_my_stuff/shared/widgets/quick_add_sheet.dart';
import 'package:find_my_stuff/core/services/move_service.dart';
import 'package:find_my_stuff/core/utils/validation_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class MoveNodePage extends ConsumerStatefulWidget {
  final StorageNodeEntity node;

  const MoveNodePage({super.key, required this.node});

  @override
  ConsumerState<MoveNodePage> createState() => _MoveNodePageState();
}

class _MoveNodePageState extends ConsumerState<MoveNodePage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isMoving = false;

  // Selected progressive levels
  String? _selectedRoomUuid;
  String? _selectedLocationUuid;
  String? _selectedSectionUuid;
  String? _selectedContainerUuid;

  // Skip states
  bool _skipSection = false;
  bool _skipContainer = false;

  final _placeRepo = PlaceRepository();
  late final PlaceEntity _currentPlace;

  @override
  void initState() {
    super.initState();
    
    // Set current place
    final places = _placeRepo.getAll();
    if (places.isNotEmpty) {
      _currentPlace = places.first;
    }

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _getDestinationUuid() {
    if (_selectedContainerUuid != null) return _selectedContainerUuid;
    if (_selectedSectionUuid != null) return _selectedSectionUuid;
    return _selectedLocationUuid;
  }

  bool _isHierarchyValid() {
    return _selectedRoomUuid != null && _selectedLocationUuid != null;
  }

  Future<void> _moveNode() async {
    final destinationUuid = _getDestinationUuid();
    if (destinationUuid == null) {
      AppSnackBar.warning(context, 'Please select a destination');
      return;
    }

    setState(() => _isMoving = true);

    try {
      // Isolated MoveService execution
      final moveService = ref.read(moveServiceProvider);
      await moveService.executeMove(widget.node.uuid, destinationUuid);
      
      // Perform light haptic success feedback
      await HapticFeedback.mediumImpact();

      // Invalidate related providers to automatically refresh visual trees
      ref.read(storageRefreshProvider.notifier).state++;
      ref.invalidate(storageNodeProvider(widget.node.uuid));
      ref.invalidate(storagePathProvider(widget.node.uuid));
      ref.invalidate(recentlyViewedProvider);
      ref.invalidate(forgottenItemsProvider);
      ref.invalidate(dashboardStatsProvider);

      if (mounted) {
        AppSnackBar.success(context, '"${widget.node.name}" moved successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, e.toString().replaceAll("ArgumentError: ", ""));
      }
    } finally {
      if (mounted) setState(() => _isMoving = false);
    }
  }

  // Inline creation methods
  Future<void> _createRoomInline() async {
    final roomName = await QuickAddSheet.show(
      context,
      title: 'Add Room',
      hintText: 'e.g. Living Room, Bedroom',
      labelText: 'Room Name',
      maxLength: ValidationHelpers.maxRoomNameLength,
      validator: ValidationHelpers.validateRoomName,
    );

    if (roomName == null || roomName.trim().isEmpty) return;

    try {
      final room = RoomEntity(
        uuid: const Uuid().v4(),
        placeUuid: _currentPlace.uuid,
        name: roomName.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(roomRepositoryProvider).save(room);
      ref.read(roomRefreshProvider.notifier).state++;
      
      setState(() {
        _selectedRoomUuid = room.uuid;
        _selectedLocationUuid = null;
        _selectedSectionUuid = null;
        _selectedContainerUuid = null;
        _skipSection = false;
        _skipContainer = false;
      });
      if (mounted) {
        AppSnackBar.success(context, 'Room "${room.name}" created and selected');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, "Couldn't add room.");
      }
    }
  }

  Future<void> _createLocationInline(String roomUuid) async {
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
        roomUuid: roomUuid,
        parentUuid: null,
        nodeType: NodeType.storageLocation.name,
        name: name.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(storageNodeRepositoryProvider).save(node);
      ref.read(storageRefreshProvider.notifier).state++;
      
      setState(() {
        _selectedLocationUuid = node.uuid;
        _selectedSectionUuid = null;
        _selectedContainerUuid = null;
        _skipSection = false;
        _skipContainer = false;
      });
      if (mounted) {
        AppSnackBar.success(context, 'Location "${node.name}" created and selected');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, "Couldn't add location.");
      }
    }
  }

  Future<void> _createSectionInline(String roomUuid, String locationUuid) async {
    final name = await QuickAddSheet.show(
      context,
      title: 'Add Section',
      hintText: 'e.g. Top Shelf, Left Side',
      labelText: 'Section Name',
      maxLength: ValidationHelpers.maxRoomNameLength,
      validator: ValidationHelpers.validateRoomName,
    );

    if (name == null || name.trim().isEmpty) return;

    try {
      final node = StorageNodeEntity(
        uuid: const Uuid().v4(),
        roomUuid: roomUuid,
        parentUuid: locationUuid,
        nodeType: NodeType.section.name,
        name: name.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(storageNodeRepositoryProvider).save(node);
      ref.read(storageRefreshProvider.notifier).state++;
      
      setState(() {
        _selectedSectionUuid = node.uuid;
        _selectedContainerUuid = null;
        _skipSection = false;
        _skipContainer = false;
      });
      if (mounted) {
        AppSnackBar.success(context, 'Section "${node.name}" created and selected');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, "Couldn't add section.");
      }
    }
  }

  Future<void> _createContainerInline(String roomUuid, String parentUuid) async {
    final name = await QuickAddSheet.show(
      context,
      title: 'Add Container',
      hintText: 'e.g. Blue Box, Plastic Pouch',
      labelText: 'Container Name',
      maxLength: ValidationHelpers.maxRoomNameLength,
      validator: ValidationHelpers.validateRoomName,
    );

    if (name == null || name.trim().isEmpty) return;

    try {
      final node = StorageNodeEntity(
        uuid: const Uuid().v4(),
        roomUuid: roomUuid,
        parentUuid: parentUuid,
        nodeType: NodeType.container.name,
        name: name.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(storageNodeRepositoryProvider).save(node);
      ref.read(storageRefreshProvider.notifier).state++;
      
      setState(() {
        _selectedContainerUuid = node.uuid;
        _skipContainer = false;
      });
      if (mounted) {
        AppSnackBar.success(context, 'Container "${node.name}" created and selected');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, "Couldn't add container.");
      }
    }
  }

  List<List<dynamic>> _getRecentLocations() {
    final repo = ref.read(storageNodeRepositoryProvider);
    final roomRepo = ref.read(roomRepositoryProvider);
    final recentlyViewed = repo.getRecentlyViewed(limit: 15);
    
    final paths = <String, List<dynamic>>{}; // key -> [room, ...nodes]
    
    for (final item in recentlyViewed) {
      final path = repo.getPathToRoot(item);
      final parentPath = path.where((e) => e.uuid != item.uuid).toList();
      if (parentPath.isEmpty) continue;
      
      final lastNode = parentPath.last;
      if (!repo.canMoveNode(widget.node.uuid, lastNode.uuid)) {
        continue; // Skip invalid parent paths!
      }
      
      final room = roomRepo.getByUuid(item.roomUuid);
      if (room == null) continue;
      
      final pathParts = [room, ...parentPath];
      final key = pathParts.map((e) {
        if (e is RoomEntity) return e.name;
        if (e is StorageNodeEntity) return e.name;
        return '';
      }).join(' › ');
      paths[key] = pathParts;
    }
    
    return paths.values.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.read(storageNodeRepositoryProvider);
    final roomRepo = ref.read(roomRepositoryProvider);

    // Current location path construction
    final currentRoom = roomRepo.getByUuid(widget.node.roomUuid);
    final currentRoomName = currentRoom?.name ?? '';
    final currentParentPath = repo.getPathToRoot(widget.node)
        .where((e) => e.uuid != widget.node.uuid)
        .map((e) => e.name)
        .join(' › ');
    final currentPathString = currentParentPath.isNotEmpty 
        ? '$currentRoomName › $currentParentPath' 
        : currentRoomName;

    // Load dynamic watch lists
    final roomsAsync = ref.watch(roomListProvider(_currentPlace.uuid));
    
    final locationsAsync = _selectedRoomUuid != null
        ? ref.watch(storageLocationsProvider(_selectedRoomUuid!))
        : null;
    final locations = locationsAsync?.value?.where((l) => repo.canMoveNode(widget.node.uuid, l.uuid)).toList() ?? [];

    final sectionsAsync = _selectedLocationUuid != null
        ? ref.watch(childNodesProvider(_selectedLocationUuid!))
        : null;
    final sections = sectionsAsync?.value
            ?.where((c) => c.nodeType == NodeType.section.name && repo.canMoveNode(widget.node.uuid, c.uuid))
            .toList() ?? [];
    final isSectionSkipped = _skipSection || sections.isEmpty;

    final containerParentUuid = _selectedSectionUuid ?? (isSectionSkipped ? _selectedLocationUuid : null);
    final containersAsync = containerParentUuid != null
        ? ref.watch(childNodesProvider(containerParentUuid))
        : null;
    final containers = containersAsync?.value
            ?.where((c) => c.nodeType == NodeType.container.name && repo.canMoveNode(widget.node.uuid, c.uuid))
            .toList() ?? [];
    final isContainerSkipped = _skipContainer || containers.isEmpty;

    // Load valid destinations list for global search
    final destinationsAsync = ref.watch(moveDestinationsProvider(widget.node));
    final destinations = destinationsAsync.value ?? [];

    // Filter search results
    final searchResults = _searchQuery.isEmpty
        ? <StorageNodeEntity>[]
        : destinations.where((d) {
            final path = repo.buildPath(d).toLowerCase();
            return d.name.toLowerCase().contains(_searchQuery) || path.contains(_searchQuery);
          }).toList();

    final recentLocations = _getRecentLocations();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Move Item',
          style: context.titleStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: context.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose where this item is stored.',
                    style: context.bodyStyle.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),

                  // Section 1: Current location subtle information card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(context.spacingM),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: context.borderRadiusM,
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CURRENT LOCATION',
                          style: context.labelStyle.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, color: theme.colorScheme.primary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.node.name,
                                    style: context.bodyStyle.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currentPathString,
                                    style: context.bodySmallStyle.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section 2: Search Destination bar
                  Semantics(
                    label: 'Search destinations',
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search destinations...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),

                  // Conditional Search Results or Progressive Selection
                  if (_searchQuery.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Search Results',
                      style: context.titleStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (searchResults.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No locations match "$_searchQuery"',
                            style: context.bodyStyle.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: searchResults.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (_, index) {
                          final dest = searchResults[index];
                          final destPath = repo.buildPath(dest);
                          return ListTile(
                            leading: Icon(
                              dest.nodeType == NodeType.container.name
                                  ? Icons.inventory_2_outlined
                                  : Icons.folder_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            title: Text(dest.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(destPath),
                            onTap: () {
                              final pathParts = repo.getPathToRoot(dest);
                              _selectedRoomUuid = dest.roomUuid;
                              _selectedLocationUuid = null;
                              _selectedSectionUuid = null;
                              _selectedContainerUuid = null;
                              
                              for (final node in pathParts) {
                                if (node.nodeType == NodeType.storageLocation.name) {
                                  _selectedLocationUuid = node.uuid;
                                } else if (node.nodeType == NodeType.section.name) {
                                  _selectedSectionUuid = node.uuid;
                                } else if (node.nodeType == NodeType.container.name) {
                                  _selectedContainerUuid = node.uuid;
                                }
                              }
                              
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                              if (mounted) {
                                AppSnackBar.success(context, 'Location populated from search');
                              }
                            },
                          );
                        },
                      ),
                  ] else ...[
                    // Section 3: Recently Used Locations (if any)
                    if (recentLocations.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Recent Destinations',
                        style: context.titleStyle.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recentLocations.map((entry) {
                          final key = entry.map((e) {
                            if (e is RoomEntity) return e.name;
                            if (e is StorageNodeEntity) return e.name;
                            return '';
                          }).join(' › ');
                          return ActionChip(
                            avatar: const Icon(Icons.history_rounded, size: 14),
                            label: Text(key, style: context.bodySmallStyle),
                            onPressed: () {
                              final RoomEntity room = entry.first as RoomEntity;
                              setState(() {
                                _selectedRoomUuid = room.uuid;
                                _selectedLocationUuid = null;
                                _selectedSectionUuid = null;
                                _selectedContainerUuid = null;
                                _skipSection = false;
                                _skipContainer = false;
                                
                                for (var i = 1; i < entry.length; i++) {
                                  final node = entry[i] as StorageNodeEntity;
                                  if (node.nodeType == NodeType.storageLocation.name) {
                                    _selectedLocationUuid = node.uuid;
                                  } else if (node.nodeType == NodeType.section.name) {
                                    _selectedSectionUuid = node.uuid;
                                  } else if (node.nodeType == NodeType.container.name) {
                                    _selectedContainerUuid = node.uuid;
                                  }
                                }
                              });
                              if (mounted) {
                                AppSnackBar.success(context, 'Location filled from history');
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ─── Section 4: PROGRESSIVE ROOM SELECTION ───
                    roomsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error loading rooms: $e'),
                      data: (rooms) => _buildSelectionSection<RoomEntity>(
                        title: 'Room',
                        subtitle: 'Select the room this item lives in.',
                        items: rooms,
                        selectedUuid: _selectedRoomUuid,
                        getName: (r) => r.name,
                        getUuid: (r) => r.uuid,
                        onSelected: (uuid) {
                          setState(() {
                            _selectedRoomUuid = uuid;
                            _selectedLocationUuid = null;
                            _selectedSectionUuid = null;
                            _selectedContainerUuid = null;
                            _skipSection = false;
                            _skipContainer = false;
                          });
                        },
                        onCreateNew: _createRoomInline,
                        helperText: 'No rooms yet. Create one to begin.',
                      ),
                    ),

                    // ─── LOCATION SELECTION ───
                    if (_selectedRoomUuid != null) ...[
                      const SizedBox(height: 20),
                      locationsAsync == null
                          ? const SizedBox()
                          : locationsAsync.when(
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, _) => Text('Error: $e'),
                              data: (_) => _buildSelectionSection<StorageNodeEntity>(
                                title: 'Location',
                                subtitle: 'e.g. Wardrobe, Cabinet, Desk',
                                items: locations,
                                selectedUuid: _selectedLocationUuid,
                                getName: (l) => l.name,
                                getUuid: (l) => l.uuid,
                                onSelected: (uuid) {
                                  setState(() {
                                    _selectedLocationUuid = uuid;
                                    _selectedSectionUuid = null;
                                    _selectedContainerUuid = null;
                                    _skipSection = false;
                                    _skipContainer = false;
                                  });
                                },
                                onCreateNew: () => _createLocationInline(_selectedRoomUuid!),
                                helperText: 'No locations yet. You can create one below.',
                              ),
                            ),
                    ],

                    // ─── SECTION SELECTION ───
                    if (_selectedLocationUuid != null) ...[
                      const SizedBox(height: 20),
                      sectionsAsync != null && sectionsAsync.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildSelectionSection<StorageNodeEntity>(
                              title: 'Section (Optional)',
                              subtitle: 'e.g. Shelf 1, Top drawer',
                              items: sections,
                              selectedUuid: _selectedSectionUuid,
                              getName: (s) => s.name,
                              getUuid: (s) => s.uuid,
                              isSkipped: isSectionSkipped,
                              onSkipChanged: (skip) {
                                setState(() {
                                  _skipSection = skip;
                                  if (skip) {
                                    _selectedSectionUuid = null;
                                  }
                                });
                              },
                              skipLabel: 'Skip Section',
                              helperText: 'No sections yet. Create one if needed, or skip.',
                              onSelected: (uuid) {
                                setState(() {
                                  _selectedSectionUuid = uuid;
                                  _selectedContainerUuid = null;
                                  _skipSection = false;
                                  _skipContainer = false;
                                });
                              },
                              onCreateNew: () => _createSectionInline(_selectedRoomUuid!, _selectedLocationUuid!),
                            ),
                    ],

                    // ─── CONTAINER SELECTION ───
                    if (_selectedLocationUuid != null && (_selectedSectionUuid != null || isSectionSkipped)) ...[
                      const SizedBox(height: 20),
                      containersAsync != null && containersAsync.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildSelectionSection<StorageNodeEntity>(
                              title: 'Container (Optional)',
                              subtitle: 'e.g. Blue Box, Toy Box',
                              items: containers,
                              selectedUuid: _selectedContainerUuid,
                              getName: (c) => c.name,
                              getUuid: (c) => c.uuid,
                              isSkipped: isContainerSkipped,
                              onSkipChanged: (skip) {
                                setState(() {
                                  _skipContainer = skip;
                                  if (skip) {
                                    _selectedContainerUuid = null;
                                  }
                                });
                              },
                              skipLabel: 'Skip Container',
                              helperText: 'No containers yet. Create one if needed, or skip.',
                              onSelected: (uuid) {
                                setState(() {
                                  _selectedContainerUuid = uuid;
                                  _skipContainer = false;
                                });
                              },
                              onCreateNew: () => _createContainerInline(
                                _selectedRoomUuid!,
                                _selectedSectionUuid ?? _selectedLocationUuid!,
                              ),
                            ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          // Section 5: Destination Summary Card and Section 6: Action Bar at the bottom
          Container(
            padding: EdgeInsets.all(context.spacingM),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPathSummaryCard(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: 'Cancel move operation',
                        button: true,
                        child: Tooltip(
                          message: 'Cancel Move',
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Semantics(
                        label: 'Confirm move item to destination location',
                        button: true,
                        child: Tooltip(
                          message: 'Confirm Move',
                          child: FilledButton.icon(
                            onPressed: (_isHierarchyValid() && !_isMoving) ? _moveNode : null,
                            icon: _isMoving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.drive_file_move),
                            label: Text(_isMoving ? 'Moving...' : 'Move Here'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionSection<T>({
    required String title,
    required String subtitle,
    required List<T> items,
    required String? selectedUuid,
    required String Function(T) getName,
    required String Function(T) getUuid,
    required void Function(String?) onSelected,
    required VoidCallback onCreateNew,
    bool isSkipped = false,
    void Function(bool)? onSkipChanged,
    String skipLabel = 'None',
    String? helperText,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.titleStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: context.bodyStyle.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (items.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              helperText ?? 'No items available yet.',
              style: context.bodyStyle.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...items.map((item) {
              final uuid = getUuid(item);
              final isSel = selectedUuid == uuid && !isSkipped;
              return ChoiceChip(
                label: Text(getName(item)),
                selected: isSel,
                selectedColor: theme.colorScheme.primaryContainer,
                onSelected: (selected) {
                  onSelected(selected ? uuid : null);
                },
              );
            }),
            if (onSkipChanged != null && items.isNotEmpty)
              ChoiceChip(
                label: Text(skipLabel),
                selected: isSkipped,
                selectedColor: theme.colorScheme.secondaryContainer,
                onSelected: (selected) {
                  onSkipChanged(selected);
                },
              ),
            ActionChip(
              avatar: Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
              label: Text(
                'Create New',
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
              ),
              onPressed: onCreateNew,
              backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFFFF5F8),
              side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPathSummaryCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final repo = ref.read(storageNodeRepositoryProvider);
    final roomRepo = ref.read(roomRepositoryProvider);

    final roomName = _selectedRoomUuid != null ? roomRepo.getByUuid(_selectedRoomUuid!)?.name : null;
    final locationName = _selectedLocationUuid != null ? repo.getByUuid(_selectedLocationUuid!)?.name : null;
    final sectionName = _selectedSectionUuid != null ? repo.getByUuid(_selectedSectionUuid!)?.name : null;
    final containerName = _selectedContainerUuid != null ? repo.getByUuid(_selectedContainerUuid!)?.name : null;

    final pathParts = <String>[];
    if (roomName != null) pathParts.add(roomName);
    if (locationName != null) pathParts.add(locationName);
    if (sectionName != null) pathParts.add(sectionName);
    if (containerName != null) pathParts.add(containerName);

    final isPathEmpty = pathParts.isEmpty;
    final pathText = isPathEmpty ? 'No destination selected' : pathParts.join('  ›  ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: RAppSpacing.md, vertical: RAppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4) : const Color(0xFFFFF5F8),
        borderRadius: BorderRadius.circular(RAppRadius.md),
        border: Border.all(
          color: isDark ? theme.colorScheme.outline.withValues(alpha: 0.2) : const Color(0xFFF8D7E3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPathEmpty ? Icons.info_outline : Icons.location_on,
            color: isPathEmpty ? theme.colorScheme.outline : theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Moving to',
                  style: context.labelStyle.copyWith(
                    color: isPathEmpty ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pathText,
                  style: context.bodyStyle.copyWith(
                    fontWeight: isPathEmpty ? FontWeight.normal : FontWeight.w600,
                    color: isPathEmpty ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}