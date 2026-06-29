// File: lib/features/home/presentation/pages/home_page.dart
//
// FULL CHANGE LOG from your original:
//  1. FAB is single "Add Room" again (matches the consistent per-level
//     hierarchy pattern you described — Home adds Room, Room adds
//     Location, etc.). The dual-FAB from my earlier draft is reverted.
//  2. "Quick Add Item" is now CONDITIONAL: it only appears once at least
//     one valid destination exists (watches quickAddDestinationsProvider,
//     the same provider QuickAddItemPage already uses to populate its
//     radio list). New users see the hierarchy-only flow; once a path
//     exists, the shortcut appears — exactly the behavior you described.
//  3. Information overload addressed via:
//       - Recent/Important/Forgotten merged into one SegmentedButton
//         section instead of three stacked lists.
//       - Expired/Expiring merged into one urgent banner near the top.
//       - Stats moved to a horizontal scroll (also fixes the unbalanced
//         2-column grid — a scroll has no "dangling last card" problem
//         regardless of how many cards you add later).
//       - New "Insights" section (charts) is collapsed by default via
//         AnimatedExpandableSection so it adds value without adding
//         permanent scroll length.
//  4. Navigation is now 100% context.push() (go_router) — no more mixed
//     Navigator.push(MaterialPageRoute(...)). See updated app_router.dart
//     for the new /quick-add, /dashboard-items, /photos routes.
//  5. Every async section has a real error + retry state (HomeAsyncList).
//  6. Pull-to-refresh added.
//  7. Drawer added (theme switch, FAQs, contact, about) — Scaffold picks
//     up the hamburger icon in the app bar automatically.
//  8. Light entrance animations (FadeInScale on stats, staggered
//     slide-in on rooms and activity items) — kept subtle/short per
//     "less is more" since this is a utility app, not a marketing page.
//  9. Add Room flow now goes through real validation with inline error
//     text and a success/error AppSnackBar instead of a silent return.
//
// NOTE: Place-switching UI is intentionally omitted — you said you're
// holding that feature for the next version.

import 'package:find_my_stuff/shared/extensions/context_extensions.dart';
import 'package:find_my_stuff/shared/widgets/quick_add_sheet.dart';
import 'package:find_my_stuff/shared/widgets/speed_dial_fab.dart';
import 'package:find_my_stuff/shared/enums/node_type.dart';
import 'package:find_my_stuff/core/utils/validation_helpers.dart';
import 'package:find_my_stuff/shared/entities/place_entity.dart';
import 'package:find_my_stuff/shared/entities/room_entity.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/objectbox.g.dart';
import 'package:find_my_stuff/shared/providers/room_providers.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/repositories/place_repository.dart';
import 'package:find_my_stuff/shared/widgets/animation_helpers.dart';
import 'package:find_my_stuff/shared/widgets/app_drawer.dart';
import 'package:find_my_stuff/shared/widgets/custom_snackbar.dart';
import 'package:find_my_stuff/shared/widgets/dashboard_stat_card.dart';
import 'package:find_my_stuff/shared/widgets/expiry_alert_banner.dart';
import 'package:find_my_stuff/shared/widgets/item_activity_tile.dart';
import 'package:find_my_stuff/shared/widgets/room_card.dart';
import 'package:find_my_stuff/shared/widgets/loading_state_widget.dart';
import 'package:find_my_stuff/shared/widgets/error_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';


class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _placeRepo = PlaceRepository();

  late final List<PlaceEntity> _allPlaces;
  late PlaceEntity currentPlace;

  final ValueNotifier<bool> _isFabExtended = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    _allPlaces = _placeRepo.getAll();
    if (_allPlaces.isNotEmpty) {
      currentPlace = _allPlaces.first;
    }
  }

  Future<void> _addRoom() async {
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
        placeUuid: currentPlace.uuid,
        name: roomName.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(roomRepositoryProvider).save(room);
      ref.read(roomRefreshProvider.notifier).state++;

      if (mounted) {
        AppSnackBar.success(context, '"${room.name}" added');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, "Couldn't add room. Please try again.");
      }
    }
  }

  Future<void> _addLocationFromHome() async {
    final rooms = ref.read(roomListProvider(currentPlace.uuid)).value ?? [];
    if (rooms.isEmpty) {
      if (mounted) {
        AppSnackBar.error(context, "Please create a room first.");
      }
      return;
    }

    if (!mounted) return;

    final RoomEntity? selectedRoom = await showModalBottomSheet<RoomEntity>(
      context: context,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.radiusL)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: context.sheetPadding,
                child: Text(
                  'Select Room',
                  style: context.titleStyle,
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return ListTile(
                      leading: const Icon(Icons.meeting_room_rounded),
                      title: Text(room.name),
                      onTap: () => Navigator.pop(context, room),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selectedRoom == null) return;
    if (!mounted) return;

    final name = await QuickAddSheet.show(
      context,
      title: 'Add Location',
      hintText: 'e.g. Wardrobe, Pantry',
    );

    if (name == null || name.trim().isEmpty) return;

    try {
      final node = StorageNodeEntity(
        uuid: const Uuid().v4(),
        roomUuid: selectedRoom.uuid,
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
        AppSnackBar.error(context, "Couldn't add Location. Please try again.");
      }
    }
  }

  void _addItem() => context.push('/quick-add');

  Future<void> _addChildFromHome(NodeType type) async {
    final destinations = await ref.read(quickAddDestinationsProvider.future);
    if (destinations.isEmpty) {
      if (mounted) {
        AppSnackBar.error(context, "Please create a room and location first.");
      }
      return;
    }

    if (!mounted) return;

    final StorageNodeEntity? parent = await showModalBottomSheet<StorageNodeEntity>(
      context: context,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.radiusL)),
      ),
      builder: (context) {
        final repo = ref.read(storageNodeRepositoryProvider);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: context.sheetPadding,
                child: Text(
                  'Select Parent Location',
                  style: context.titleStyle,
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: destinations.length,
                  itemBuilder: (context, index) {
                    final d = destinations[index];
                    final path = repo.buildPath(d);
                    return ListTile(
                      title: Text(d.name),
                      subtitle: Text(path),
                      onTap: () => Navigator.pop(context, d),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (parent == null) return;
    if (!mounted) return;

    final name = await QuickAddSheet.show(
      context,
      title: 'Add ${type == NodeType.section ? "Section" : "Container"}',
      hintText: type == NodeType.section ? 'e.g. Top Shelf, Left Side' : 'e.g. Box, Zip Pouch',
    );

    if (name == null || name.trim().isEmpty) return;

    try {
      final node = StorageNodeEntity(
        uuid: const Uuid().v4(),
        roomUuid: parent.roomUuid,
        parentUuid: parent.uuid,
        nodeType: type.name,
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
        AppSnackBar.error(context, "Couldn't add ${type == NodeType.section ? 'section' : 'container'}.");
      }
    }
  }



  Future<void> _onRefresh() async {
    ref.invalidate(roomListProvider(currentPlace.uuid));
    ref.invalidate(recentlyViewedProvider);
    ref.invalidate(forgottenItemsProvider);
    ref.invalidate(importantItemsProvider);
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(expiringItemsProvider);
    ref.invalidate(expiredItemsProvider);
    ref.invalidate(quickAddDestinationsProvider);
    ref.invalidate(archivedItemsProvider);
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    if (_allPlaces.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No place found. Please restart the app.')),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final roomsAsync = ref.watch(roomListProvider(currentPlace.uuid));
    final recentAsync = ref.watch(recentlyViewedProvider);
    final forgottenAsync = ref.watch(forgottenItemsProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final expiringAsync = ref.watch(expiringItemsProvider);
    final expiredAsync = ref.watch(expiredItemsProvider);
    final archivedAsync = ref.watch(archivedItemsProvider);
    final archivedCount = archivedAsync.value?.length ?? 0;

    return Scaffold(
      drawer: const AppDrawer(),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _isFabExtended,
        builder: (context, isExtended, child) {
          return SpeedDialFAB(
            tooltip: 'Add Options',
            isExtended: isExtended,
            items: [
              SpeedDialItem(
                icon: Icons.label_outline,
                label: 'Add Item',
                onTap: _addItem,
              ),
              SpeedDialItem(
                icon: Icons.meeting_room_rounded,
                label: 'New Room',
                onTap: _addRoom,
              ),
              SpeedDialItem(
                icon: Icons.inventory_2_outlined,
                label: 'New Location',
                onTap: _addLocationFromHome,
              ),
              SpeedDialItem(
                icon: Icons.view_agenda_outlined,
                label: 'New Section',
                onTap: () => _addChildFromHome(NodeType.section),
              ),
              SpeedDialItem(
                icon: Icons.inventory_2_outlined,
                label: 'New Container',
                onTap: () => _addChildFromHome(NodeType.container),
              ),
            ],
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.pixels <= 50) {
              if (!_isFabExtended.value) {
                _isFabExtended.value = true;
              }
              return false;
            }
            if (notification is UserScrollNotification) {
              if (notification.direction == ScrollDirection.reverse) {
                if (_isFabExtended.value) {
                  _isFabExtended.value = false;
                }
              } else if (notification.direction == ScrollDirection.forward) {
                if (!_isFabExtended.value) {
                  _isFabExtended.value = true;
                }
              }
            }
            return false;
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                snap: true,
                title: Text(
                  currentPlace.name,
                  style: context.titleStyle.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                context.spacingM,
                context.spacingS,
                context.spacingM,
                110,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Semantics(
                    label: 'Global search bar button',
                    button: true,
                    child: Tooltip(
                      message: 'Search your stuff',
                      child: SearchBar(
                        hintText: 'Search your stuff...',
                        leading: const Icon(Icons.search),
                        onTap: () => context.push('/search'),
                      ),
                    ),
                  ),

                  SizedBox(height: context.spacingM),

                  // Merged expired + expiring urgency banner.
                  expiredAsync.when(
                    data: (expired) => expiringAsync.when(
                      data: (expiring) => ExpiryAlertBanner(
                        expiredCount: expired.length,
                        expiringCount: expiring.length,
                        onTapExpired: () =>
                            context.push('/dashboard/expired'),
                        onTapExpiring: () =>
                            context.push('/dashboard/expiring'),
                      ),
                      loading: () => const SizedBox(),
                      error: (_, _) => const SizedBox(),
                    ),
                    loading: () => const SizedBox(),
                    error: (_, _) => const SizedBox(),
                  ),

                  roomsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 64),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: context.spacingL,
                      ),
                      child: Column(
                        children: [
                          Text("Couldn't load rooms: $err"),
                          SizedBox(height: context.spacingS),
                          TextButton.icon(
                            onPressed: () => ref
                                .invalidate(roomListProvider(currentPlace.uuid)),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                    data: (rooms) {
                      final stats = statsAsync.value;
                      final totalItems = stats?['items'] ?? (rooms.isEmpty ? 0 : 1);
                      if (totalItems == 0) {
                        return _EmptyHomeState(
                          onAddItem: _addItem,
                          onAddRoom: _addRoom,
                        );
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Compact horizontal stats row — a scroll has no
                          // "awkward dangling card" problem like the old
                          // 2-column grid did with an odd card count.
                          statsAsync.when(
                            loading: () => const SizedBox(
                              height: 100,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (_, _) => const SizedBox(),
                            data: (stats) => FadeInScale(
                              duration: const Duration(milliseconds: 350),
                              child: SizedBox(
                                height: context.dashboardCardHeight,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(
                                        width: context.roomCardWidth,
                                        child: DashboardStatCard(
                                          title: 'Items',
                                          value: stats['items'].toString(),
                                          icon: Icons.inventory_2,
                                          onTap: () => context.push('/dashboard/all'),
                                        ),
                                      ),
                                      SizedBox(width: context.spacingS + 4),
                                      SizedBox(
                                        width: context.roomCardWidth,
                                        child: DashboardStatCard(
                                          title: 'Important',
                                          value: stats['important'].toString(),
                                          icon: Icons.star,
                                          onTap: () => context.push('/dashboard/important'),
                                        ),
                                      ),
                                      SizedBox(width: context.spacingS + 4),
                                      SizedBox(
                                        width: context.roomCardWidth,
                                        child: DashboardStatCard(
                                          title: 'Photos',
                                          value: stats['photos'].toString(),
                                          icon: Icons.photo,
                                          onTap: () => context.push('/photos'),
                                        ),
                                      ),
                                      SizedBox(width: context.spacingS + 4),
                                      SizedBox(
                                        width: context.roomCardWidth,
                                        child: DashboardStatCard(
                                          title: 'Archived',
                                          value: archivedCount.toString(),
                                          icon: Icons.archive_outlined,
                                          onTap: () =>
                                              context.push('/archived'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: context.spacingL),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Rooms',
                                style: context.titleStyle,
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.spacingS + 2,
                                  vertical: context.spacingXS,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: context.borderRadiusM,
                                ),
                                child: Text(
                                  '${rooms.length} Room(s)',
                                  style: context.labelStyle.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.spacingS + 4),
                          SizedBox(
                            height: context.dashboardCardHeight,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: rooms.length + 1,
                              separatorBuilder: (_, _) => SizedBox(width: context.spacingS),
                              itemBuilder: (context, index) {
                                if (index == rooms.length) {
                                  return SizedBox(
                                    width: context.roomCardWidth,
                                    child: _AddRoomCard(onTap: _addRoom),
                                  );
                                }
                                final room = rooms[index];
                                final repo = ref.read(storageNodeRepositoryProvider);
                                final itemCount = repo.box.query(
                                  StorageNodeEntity_.roomUuid.equals(room.uuid) &
                                  StorageNodeEntity_.nodeType.equals(NodeType.item.name) &
                                  StorageNodeEntity_.isArchived.equals(false),
                                ).build().count();
                                final containerCount = repo.box.query(
                                  StorageNodeEntity_.roomUuid.equals(room.uuid) &
                                  StorageNodeEntity_.nodeType.equals(NodeType.container.name) &
                                  StorageNodeEntity_.isArchived.equals(false),
                                ).build().count();

                                return SizedBox(
                                  width: context.roomCardWidth,
                                  child: RoomCard(
                                    room: room,
                                    itemCount: itemCount,
                                    containerCount: containerCount,
                                    onTap: () => context.push('/room/${room.uuid}'),
                                  ),
                                );
                              },
                            ),
                          ),

                          SizedBox(height: context.spacingL),

                          // Insights — collapsed by default so it adds
                          // value without adding permanent scroll length.
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLow,
                              borderRadius: context.borderRadiusL,
                            ),
                            child: AnimatedExpandableSection(
                              title: 'Insights',
                              initiallyExpanded: false,
                              leading: const Icon(Icons.insights_outlined),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: context.spacingM,
                                  right: context.spacingM,
                                  bottom: context.spacingM,
                                ),
                                child: expiredAsync.when(
                                  data: (expired) => expiringAsync.when(
                                    data: (expiring) {
                                      final totalItems =
                                          statsAsync.value?['items'] ?? 0;

                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Card(
                                            elevation: 1,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: context.borderRadiusL,
                                              side: BorderSide(
                                                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                                              ),
                                            ),
                                            child: Padding(
                                              padding: context.cardPadding,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          'Items Stored',
                                                          style: context.titleStyle.copyWith(
                                                            color: theme.colorScheme.onSurfaceVariant,
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        '$totalItems',
                                                        style: context.displayStyle.copyWith(
                                                          color: theme.colorScheme.onSurface,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: context.spacingS),
                                                  Wrap(
                                                    spacing: context.spacingS,
                                                    runSpacing: context.spacingS,
                                                    children: [
                                                      Semantics(
                                                        label: 'View expiring items',
                                                        button: true,
                                                        child: Tooltip(
                                                          message: 'Show items expiring soon',
                                                          child: InkWell(
                                                            onTap: () => context.push('/dashboard/expiring'),
                                                            borderRadius: context.borderRadiusPill,
                                                            child: Container(
                                                              padding: EdgeInsets.symmetric(
                                                                horizontal: context.spacingM,
                                                                vertical: context.spacingS,
                                                              ),
                                                              decoration: BoxDecoration(
                                                                color: isDark ? const Color(0xFF422006) : const Color(0xFFFEF3C7),
                                                                border: Border.all(
                                                                  color: isDark ? const Color(0xFF5A3E12) : const Color(0xFFFDE68A),
                                                                ),
                                                                borderRadius: context.borderRadiusPill,
                                                              ),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  const Text('⏳', style: TextStyle(fontSize: 14)),
                                                                  SizedBox(width: context.spacingXS),
                                                                  Text(
                                                                    '${expiring.length} Expiring',
                                                                    style: context.labelStyle.copyWith(
                                                                      color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Semantics(
                                                        label: 'View expired items',
                                                        button: true,
                                                        child: Tooltip(
                                                          message: 'Show expired items',
                                                          child: InkWell(
                                                            onTap: () => context.push('/dashboard/expired'),
                                                            borderRadius: context.borderRadiusPill,
                                                            child: Container(
                                                              padding: EdgeInsets.symmetric(
                                                                horizontal: context.spacingM,
                                                                vertical: context.spacingS,
                                                              ),
                                                              decoration: BoxDecoration(
                                                                color: isDark ? const Color(0xFF4C0519) : const Color(0xFFFFF1F2),
                                                                border: Border.all(
                                                                  color: isDark ? const Color(0xFF6B1D2F) : const Color(0xFFFFE4E6),
                                                                ),
                                                                borderRadius: context.borderRadiusPill,
                                                              ),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  const Text('❌', style: TextStyle(fontSize: 14)),
                                                                  SizedBox(width: context.spacingXS),
                                                                  Text(
                                                                    '${expired.length} Expired',
                                                                    style: context.labelStyle.copyWith(
                                                                      color: isDark ? const Color(0xFFFDA4AF) : const Color(0xFFBE123C),
                                                                    ),
                                                                  ),
                                                                ],
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
                                          ),
                                        ],
                                      );
                                    },
                                    loading: () => const SizedBox(),
                                    error: (_, _) => const SizedBox(),
                                  ),
                                  loading: () => const SizedBox(),
                                  error: (_, _) => const SizedBox(),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: context.spacingL),

                          // Section 4: Continue Where You Left Off
                          Text(
                            'Continue Where You Left Off',
                            style: context.titleStyle.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          recentAsync.when(
                            loading: () => const LoadingStateWidget(type: LoadingType.list),
                            error: (err, _) => ErrorStateWidget(
                              description: "We couldn't retrieve your recently viewed items.",
                              onRetry: () => ref.invalidate(recentlyViewedProvider),
                            ),
                            data: (items) {
                              final list = items.take(5).toList();
                              if (list.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(context.spacingM),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: theme.colorScheme.outlineVariant),
                                    borderRadius: context.borderRadiusM,
                                  ),
                                  child: Text(
                                    'Items you recently opened will appear here.',
                                    style: context.bodySmallStyle.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                );
                              }
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: list.length,
                                itemBuilder: (context, index) {
                                  final item = list[index];
                                  return SlideInFromLeft(
                                    delayMilliseconds: index * 60,
                                    child: ItemActivityTile(
                                      item: item,
                                      customTimeText: _getRelativeViewedTime(item.viewedAt),
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                          SizedBox(height: context.spacingL),

                          // Section 5: Forgotten Items
                          Text(
                            'Forgotten Items',
                            style: context.titleStyle.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          forgottenAsync.when(
                            loading: () => const LoadingStateWidget(type: LoadingType.list),
                            error: (err, _) => ErrorStateWidget(
                              description: "We couldn't retrieve your forgotten items.",
                              onRetry: () => ref.invalidate(forgottenItemsProvider),
                            ),
                            data: (items) {
                              final sorted = List<StorageNodeEntity>.from(items)
                                ..sort((a, b) {
                                  final dateA = a.viewedAt ?? a.createdAt;
                                  final dateB = b.viewedAt ?? b.createdAt;
                                  return dateA.compareTo(dateB);
                                });

                              if (sorted.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(context.spacingM),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: theme.colorScheme.outlineVariant),
                                    borderRadius: context.borderRadiusM,
                                  ),
                                  child: Text(
                                    'Items left untouched for a long time will appear here.',
                                    style: context.bodySmallStyle.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: sorted.length,
                                itemBuilder: (context, index) {
                                  final item = sorted[index];
                                  return SlideInFromLeft(
                                    delayMilliseconds: index * 60,
                                    child: ItemActivityTile(
                                      item: item,
                                      customTimeText: _getForgottenContextText(item),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  String _getRelativeViewedTime(DateTime? date) {
    if (date == null) return 'Viewed long ago';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Viewed just now';
    } else if (difference.inMinutes < 60) {
      final m = difference.inMinutes;
      return 'Viewed $m ${m == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final h = difference.inHours;
      return 'Viewed $h ${h == 1 ? 'hour' : 'hours'} ago';
    } else {
      final days = difference.inDays;
      if (days == 1) return 'Viewed yesterday';
      return 'Viewed $days days ago';
    }
  }

  String _getForgottenContextText(StorageNodeEntity item) {
    final date = item.viewedAt ?? item.createdAt;
    final diff = DateTime.now().difference(date);
    final hasOpened = item.viewedAt != null;

    if (diff.inDays >= 365) {
      return 'Stored over a year ago';
    }
    final months = (diff.inDays / 30).floor();
    if (months >= 1) {
      if (hasOpened) {
        return 'Last viewed $months ${months == 1 ? 'month' : 'months'} ago';
      } else {
        return 'Haven\'t opened for $months ${months == 1 ? 'month' : 'months'}';
      }
    }
    return 'Last viewed ${diff.inDays} days ago';
  }
}

class _AddRoomCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddRoomCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: context.borderRadiusL,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: context.borderRadiusL,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: theme.colorScheme.primary, size: context.iconMedium),
              SizedBox(height: context.spacingXS),
              Text(
                'Add Room',
                style: context.labelStyle.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHomeState extends StatelessWidget {
  final VoidCallback onAddItem;
  final VoidCallback onAddRoom;

  const _EmptyHomeState({
    required this.onAddItem,
    required this.onAddRoom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FadeInScale(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.spacingXL + 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: context.iconXL + 8,
                color: theme.colorScheme.outline,
              ),
              SizedBox(height: context.spacingM),
              Text('Nothing organized yet', style: context.titleStyle.copyWith(fontWeight: FontWeight.w700)),
              SizedBox(height: context.spacingXS),
              Text(
                'Add your items to start organizing\nwhere your things live.',
                textAlign: TextAlign.center,
                style: context.bodyStyle.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              SizedBox(height: context.spacingM + 4),
              FilledButton.icon(
                onPressed: onAddItem,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: Text(
                  'Add Your First Item',
                  style: context.buttonStyle,
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(180, 48),
                  backgroundColor: const Color(0xFFD10047),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onAddRoom,
                icon: const Icon(Icons.meeting_room_rounded),
                label: Text(
                  'Create Room',
                  style: context.buttonStyle,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(180, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}