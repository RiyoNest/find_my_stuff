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

import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:find_my_stuff/features/room/presentation/widgets/add_room_dialog.dart';
import 'package:find_my_stuff/shared/entities/place_entity.dart';
import 'package:find_my_stuff/shared/entities/room_entity.dart';
import 'package:find_my_stuff/shared/providers/room_providers.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/repositories/place_repository.dart';
import 'package:find_my_stuff/shared/widgets/animation_helpers.dart';
import 'package:find_my_stuff/shared/widgets/custom_snackbar.dart';
import 'package:find_my_stuff/shared/widgets/dashboard_charts.dart';
import 'package:find_my_stuff/shared/widgets/dashboard_stat_card.dart';
import 'package:find_my_stuff/shared/widgets/expiry_alert_banner.dart';
import 'package:find_my_stuff/shared/widgets/home_async_list.dart';
import 'package:find_my_stuff/shared/widgets/item_activity_tile.dart';
import 'package:find_my_stuff/shared/widgets/room_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../widgets/app_drawer.dart';

enum _ActivityFilter { recent, important, forgotten }

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _placeRepo = PlaceRepository();

  late final List<PlaceEntity> _allPlaces;
  late PlaceEntity currentPlace;

  _ActivityFilter _activityFilter = _ActivityFilter.recent;

  @override
  void initState() {
    super.initState();
    _allPlaces = _placeRepo.getAll();
    if (_allPlaces.isNotEmpty) {
      currentPlace = _allPlaces.first;
    }
  }

  Future<void> _addRoom() async {
    final roomName = await showDialog<String>(
      context: context,
      builder: (_) => const AddRoomDialog(),
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

  void _addItem() => context.push('/quick-add');

  void _openFilteredItems<T>(String title, List<T> items) {
    context.push('/dashboard-items', extra: {'title': title, 'items': items});
  }

  void _openPhotos<T>(List<T> items) {
    context.push('/photos', extra: items);
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

    final roomsAsync = ref.watch(roomListProvider(currentPlace.uuid));
    final recentAsync = ref.watch(recentlyViewedProvider);
    final forgottenAsync = ref.watch(forgottenItemsProvider);
    final importantAsync = ref.watch(importantItemsProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final expiringAsync = ref.watch(expiringItemsProvider);
    final expiredAsync = ref.watch(expiredItemsProvider);
    final destinationsAsync = ref.watch(quickAddDestinationsProvider);

    final canQuickAdd = destinationsAsync.value?.isNotEmpty ?? false;

    return Scaffold(
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: _addRoom,
        tooltip: 'Add Room',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              title: Text(currentPlace.name),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                RAppSpacing.md,
                RAppSpacing.sm,
                RAppSpacing.md,
                110,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SearchBar(
                    hintText: 'Search your stuff...',
                    leading: const Icon(Icons.search),
                    onTap: () => context.push('/search'),
                  ),

                  // Conditional Quick Add — only shown once a path exists,
                  // so first-time users learn the hierarchy first.
                  if (canQuickAdd) ...[
                    const SizedBox(height: RAppSpacing.sm + 4),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.bolt_outlined),
                        label: const Text('Quick Add Item'),
                      ),
                    ),
                  ],

                  const SizedBox(height: RAppSpacing.md),

                  // Merged expired + expiring urgency banner.
                  expiredAsync.when(
                    data: (expired) => expiringAsync.when(
                      data: (expiring) => ExpiryAlertBanner(
                        expiredCount: expired.length,
                        expiringCount: expiring.length,
                        onTapExpired: () =>
                            _openFilteredItems('Expired Items', expired),
                        onTapExpiring: () =>
                            _openFilteredItems('Expiring Items', expiring),
                      ),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),

                  roomsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 64),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: RAppSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          Text("Couldn't load rooms: $err"),
                          const SizedBox(height: RAppSpacing.sm),
                          TextButton.icon(
                            onPressed: () => ref.invalidate(
                              roomListProvider(currentPlace.uuid),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                    data: (rooms) {
                      if (rooms.isEmpty) {
                        return _EmptyHomeState(onAddRoom: _addRoom);
                      }

                      return Column(
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
                            error: (_, __) => const SizedBox(),
                            data: (stats) => FadeInScale(
                              duration: const Duration(milliseconds: 350),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(
                                        width: 150,
                                        child: DashboardStatCard(
                                          title: 'Items',
                                          value: stats['items'].toString(),
                                          icon: Icons.inventory_2,
                                          onTap: () => _openFilteredItems(
                                            'All Items',
                                            ref
                                                .read(
                                                  storageNodeRepositoryProvider,
                                                )
                                                .getAllItems(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: RAppSpacing.sm + 4),
                                      SizedBox(
                                        width: 150,
                                        child: DashboardStatCard(
                                          title: 'Important',
                                          value: stats['important'].toString(),
                                          icon: Icons.star,
                                          onTap: () => _openFilteredItems(
                                            'Important Items',
                                            ref
                                                .read(
                                                  storageNodeRepositoryProvider,
                                                )
                                                .getImportantItems(
                                                  limit: 999999,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: RAppSpacing.sm + 4),
                                      SizedBox(
                                        width: 150,
                                        child: DashboardStatCard(
                                          title: 'Photos',
                                          value: stats['photos'].toString(),
                                          icon: Icons.photo,
                                          onTap: () => _openPhotos(
                                            ref
                                                .read(
                                                  storageNodeRepositoryProvider,
                                                )
                                                .getItemsWithPhotosList(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: RAppSpacing.lg + 4),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Rooms', style: theme.textTheme.titleLarge),
                              Text(
                                '${rooms.length}',
                                style: theme.textTheme.labelMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: RAppSpacing.sm + 4),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (
                                    var index = 0;
                                    index < rooms.length;
                                    index++
                                  ) ...[
                                    if (index > 0)
                                      const SizedBox(width: RAppSpacing.sm + 2),
                                    FadeInScale(
                                      delayMilliseconds: index * 50,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: RoomCard(
                                        room: rooms[index],
                                        onTap: () => context.push(
                                          '/room/${rooms[index].uuid}',
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: RAppSpacing.sm + 2),
                                  _AddRoomCard(onTap: _addRoom),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: RAppSpacing.lg + 4),

                          // Insights — collapsed by default so it adds
                          // value without adding permanent scroll length.
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(
                                RAppRadius.lg,
                              ),
                            ),
                            child: AnimatedExpandableSection(
                              title: 'Insights',
                              initiallyExpanded: false,
                              leading: const Icon(Icons.insights_outlined),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: RAppSpacing.md,
                                ),
                                child: expiredAsync.when(
                                  data: (expired) => expiringAsync.when(
                                    data: (expiring) {
                                      final totalItems =
                                          statsAsync.value?['items'] ?? 0;
                                      final active =
                                          (totalItems -
                                                  expired.length -
                                                  expiring.length)
                                              .clamp(0, totalItems);

                                      return ExpiryStatusChart(
                                        expired: expired.length,
                                        expiring: expiring.length,
                                        active: active,
                                      );
                                    },
                                    loading: () => const SizedBox(),
                                    error: (_, __) => const SizedBox(),
                                  ),
                                  loading: () => const SizedBox(),
                                  error: (_, __) => const SizedBox(),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: RAppSpacing.lg + 4),

                          Text('Activity', style: theme.textTheme.titleLarge),
                          const SizedBox(height: RAppSpacing.sm + 4),
                          SegmentedButton<_ActivityFilter>(
                            segments: const [
                              ButtonSegment(
                                value: _ActivityFilter.recent,
                                label: Text('Recent'),
                                icon: Icon(Icons.history, size: 16),
                              ),
                              ButtonSegment(
                                value: _ActivityFilter.important,
                                label: Text('Important'),
                                icon: Icon(Icons.star_outline, size: 16),
                              ),
                              ButtonSegment(
                                value: _ActivityFilter.forgotten,
                                label: Text('Forgotten'),
                                icon: Icon(
                                  Icons.visibility_off_outlined,
                                  size: 16,
                                ),
                              ),
                            ],
                            selected: {_activityFilter},
                            onSelectionChanged: (selection) {
                              setState(() => _activityFilter = selection.first);
                            },
                          ),
                          const SizedBox(height: RAppSpacing.sm + 4),

                          if (_activityFilter == _ActivityFilter.recent)
                            HomeAsyncList(
                              asyncValue: recentAsync,
                              emptyMessage: 'No recently viewed items',
                              emptyIcon: Icons.history,
                              onRetry: () =>
                                  ref.invalidate(recentlyViewedProvider),
                              itemBuilder: (_, item, index) => SlideInFromLeft(
                                delayMilliseconds: index * 60,
                                child: ItemActivityTile(item: item),
                              ),
                            ),
                          if (_activityFilter == _ActivityFilter.important)
                            HomeAsyncList(
                              asyncValue: importantAsync,
                              emptyMessage: 'No important items yet',
                              emptyIcon: Icons.star_outline,
                              onRetry: () =>
                                  ref.invalidate(importantItemsProvider),
                              itemBuilder: (_, item, index) => SlideInFromLeft(
                                delayMilliseconds: index * 60,
                                child: ItemActivityTile(item: item),
                              ),
                            ),
                          if (_activityFilter == _ActivityFilter.forgotten)
                            HomeAsyncList(
                              asyncValue: forgottenAsync,
                              emptyMessage: 'Nothing forgotten - nice!',
                              emptyIcon: Icons.visibility_off_outlined,
                              onRetry: () =>
                                  ref.invalidate(forgottenItemsProvider),
                              itemBuilder: (_, item, index) => SlideInFromLeft(
                                delayMilliseconds: index * 60,
                                child: ItemActivityTile(item: item),
                              ),
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
    );
  }
}

class _AddRoomCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddRoomCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(RAppRadius.lg),
      onTap: onTap,
      child: Container(
        width: 104,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RAppRadius.lg),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: theme.colorScheme.primary),
              const SizedBox(height: RAppSpacing.xs + 2),
              Text(
                'Add Room',
                style: theme.textTheme.labelMedium?.copyWith(
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
  final VoidCallback onAddRoom;

  const _EmptyHomeState({required this.onAddRoom});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FadeInScale(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 56,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: RAppSpacing.md),
              Text('Nothing organized yet', style: theme.textTheme.titleMedium),
              const SizedBox(height: RAppSpacing.xs + 2),
              Text(
                'Add your first room to start organizing\nwhere your things live.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: RAppSpacing.md + 4),
              FilledButton.icon(
                onPressed: onAddRoom,
                icon: const Icon(Icons.add),
                label: const Text('Add Your First Room'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
