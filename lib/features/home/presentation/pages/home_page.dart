import 'package:find_my_stuff/features/room/presentation/widgets/add_room_dialog.dart';
import 'package:find_my_stuff/shared/entities/place_entity.dart';
import 'package:find_my_stuff/shared/entities/room_entity.dart';
import 'package:find_my_stuff/shared/providers/room_providers.dart';
import 'package:find_my_stuff/shared/repositories/place_repository.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text(currentPlace.name)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home',
        onPressed: _addRoom,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchBar(
              hintText: 'Search your stuff...',
              leading: const Icon(Icons.search),
              onTap: () {},
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

            const SizedBox(height: 16),

            Expanded(
              child: roomsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (rooms) {
                  if (rooms.isEmpty) {
                    return const Center(child: Text('No rooms added yet'));
                  }

                  return ListView.separated(
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
            ),
          ],
        ),
      ),
    );
  }
}
