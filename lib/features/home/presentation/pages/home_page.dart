import 'package:find_my_stuff/features/dashboard/presentation/pages/dashboard_items_page.dart';
import 'package:find_my_stuff/features/room/presentation/widgets/add_room_dialog.dart';
import 'package:find_my_stuff/features/storage_tree/presentation/pages/quick_add_item_page.dart';
import 'package:find_my_stuff/shared/entities/place_entity.dart';
import 'package:find_my_stuff/shared/entities/room_entity.dart';
import 'package:find_my_stuff/shared/providers/room_providers.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/repositories/place_repository.dart';
import 'package:find_my_stuff/shared/widgets/dashboard_stat_card.dart';
import 'package:find_my_stuff/shared/widgets/item_activity_tile.dart';
import 'package:flutter/material.dart';
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

  late final PlaceEntity currentPlace;

  @override
  void initState() {
    super.initState();
    currentPlace = _placeRepo.getAll().first;
  }

  Future<void> _addRoom() async {
    final roomName = await showDialog<String>(
      context: context,
      builder: (_) => const AddRoomDialog(),
    );

    if (roomName == null || roomName.trim().isEmpty) {
      return;
    }

    final room = RoomEntity(
      uuid: const Uuid().v4(),
      placeUuid: currentPlace.uuid,
      name: roomName.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final repo = ref.read(roomRepositoryProvider);

    repo.save(room);

    ref.read(roomRefreshProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomListProvider(currentPlace.uuid));

    final recentAsync = ref.watch(recentlyViewedProvider);

    final forgottenAsync = ref.watch(forgottenItemsProvider);

    final importantAsync = ref.watch(importantItemsProvider);

    final statsAsync = ref.watch(dashboardStatsProvider);

    final expiringAsync = ref.watch(expiringItemsProvider);

    final expiredAsync = ref.watch(expiredItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentPlace.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'archive') {
                context.push('/archived');
              }
              if (value == 'settings') {
                context.push('/settings');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'archive',
                child: Text('Archived Items'),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: _addRoom,
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchBar(
              hintText: 'Search your stuff...',
              leading: const Icon(Icons.search),
              onTap: () {
                context.push('/search');
              },
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Quick Add Item'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuickAddItemPage()),
                );
              },
            ),

            const SizedBox(height: 24),

            Text('Dashboard', style: Theme.of(context).textTheme.titleLarge),

            const SizedBox(height: 12),

            statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),

              error: (_, __) => const SizedBox(),

              data: (stats) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.6,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    DashboardStatCard(
                      title: 'Items',
                      value: stats['items'].toString(),
                      icon: Icons.inventory_2,
                      onTap: () {
                        final repo = ref.read(
                          storageNodeRepositoryProvider,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DashboardItemsPage(
                              title: 'All Items',
                              items: repo.getAllItems(),
                            ),
                          ),
                        );
                      },
                    ),

                    DashboardStatCard(
                      title: 'Important',
                      value: stats['important'].toString(),
                      icon: Icons.star,
                      onTap: () {
                        final repo = ref.read(
                          storageNodeRepositoryProvider,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DashboardItemsPage(
                              title: 'Important Items',
                              items: repo.getImportantItems(
                                limit: 999999,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    DashboardStatCard(
                      title: 'Photos',
                      value: stats['photos'].toString(),
                      icon: Icons.photo,
                      onTap: () {
                        final repo = ref.read(storageNodeRepositoryProvider);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DashboardItemsPage(
                              title: 'Items With Photos',
                              items: repo.getItemsWithPhotosList(),
                            ),
                          ),
                        );
                      },
                    ),

                    DashboardStatCard(
                      title: 'Expiring',
                      value: expiringAsync.value?.length.toString() ?? '0',
                      icon: Icons.schedule,
                      onTap: () {
                        final repo = ref.read(
                          storageNodeRepositoryProvider,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DashboardItemsPage(
                              title: 'Expiring Items',
                              items: repo.getExpiringItems(
                                days: 3650,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    DashboardStatCard(
                      title: 'Expired',
                      value: expiredAsync.value?.length.toString() ?? '0',
                      icon: Icons.warning,
                      onTap: () {
                        final repo = ref.read(storageNodeRepositoryProvider);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DashboardItemsPage(
                              title: 'Expired Items',
                              items: repo.getExpiredItems(),
                            ),
                          ),
                        );
                      },
                    ),

                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 12),

            recentAsync.when(
              loading: () => const CircularProgressIndicator(),

              error: (_, __) => const SizedBox(),

              data: (items) {
                if (items.isEmpty) {
                  return const Text('No recently viewed items');
                }

                return Column(
                  children: items
                      .take(5)
                      .map((e) => ItemActivityTile(item: e))
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            Text(
              'Important Items',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 12),

            importantAsync.when(
              loading: () => const CircularProgressIndicator(),

              error: (_, __) => const SizedBox(),

              data: (items) {
                if (items.isEmpty) {
                  return const Text('No important items');
                }

                return Column(
                  children: items
                      .take(5)
                      .map((e) => ItemActivityTile(item: e))
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            Text(
              'Expiring Soon',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 12),

            expiringAsync.when(
              loading: () => const CircularProgressIndicator(),

              error: (_, __) => const SizedBox(),

              data: (items) {
                if (items.isEmpty) {
                  return const Text('No items expiring soon');
                }

                return Column(
                  children: items
                      .take(5)
                      .map(
                        (e) => Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.schedule,
                              color: Colors.orange,
                            ),
                            title: Text(e.name),
                            subtitle: Text(
                              'Expires: ${e.expiryDate?.day}/${e.expiryDate?.month}/${e.expiryDate?.year}',
                            ),
                            onTap: () {
                              context.push('/node/${e.uuid}');
                            },
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            Text(
              'Expired Items',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 12),

            expiredAsync.when(
              loading: () => const CircularProgressIndicator(),

              error: (_, __) => const SizedBox(),

              data: (items) {
                if (items.isEmpty) {
                  return const Text('No expired items');
                }

                return Column(
                  children: items
                      .take(5)
                      .map(
                        (e) => Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.warning,
                              color: Colors.red,
                            ),
                            title: Text(e.name),
                            subtitle: Text(
                              'Expired: ${e.expiryDate?.day}/${e.expiryDate?.month}/${e.expiryDate?.year}',
                            ),
                            onTap: () {
                              context.push('/node/${e.uuid}');
                            },
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            Text(
              'Forgotten Items',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 12),

            forgottenAsync.when(
              loading: () => const CircularProgressIndicator(),

              error: (_, __) => const SizedBox(),

              data: (items) {
                if (items.isEmpty) {
                  return const Text('No forgotten items');
                }

                return Column(
                  children: items
                      .take(5)
                      .map((e) => ItemActivityTile(item: e))
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            roomsAsync.when(
              loading: () =>
                  Text('Rooms', style: Theme.of(context).textTheme.titleLarge),

              error: (_, __) =>
                  Text('Rooms', style: Theme.of(context).textTheme.titleLarge),

              data: (rooms) => Text(
                'Rooms (${rooms.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),

            const SizedBox(height: 12),

            roomsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),

              error: (e, _) => Center(child: Text('Error: $e')),

              data: (rooms) {
                if (rooms.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No rooms added yet'),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rooms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final room = rooms[index];

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.meeting_room),
                        title: Text(room.name),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.push('/room/${room.uuid}');
                        },
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
