import 'package:find_my_stuff/features/storage_tree/presentation/widgets/add_storage_location_dialog.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/room_providers.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/enums/node_type.dart';

class RoomDetailsPage extends ConsumerWidget {
  final String roomUuid;

  const RoomDetailsPage({
    super.key,
    required this.roomUuid,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final roomAsync = ref.watch(
      roomDetailsProvider(roomUuid),
    );

    return roomAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Scaffold(
        body: Center(
          child: Text(e.toString()),
        ),
      ),
      data: (room) {
        if (room == null) {
          return const Scaffold(
            body: Center(
              child: Text('Room not found'),
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

class _RoomDetailsContentState
    extends ConsumerState<_RoomDetailsContent> {
  Future<void> _addStorageLocation() async {
    final storageLocationName =
    await showDialog<String>(
      context: context,
      builder: (_) =>
      const AddStorageLocationDialog(),
    );

    if (storageLocationName == null ||
        storageLocationName.trim().isEmpty) {
      return;
    }

    final node = StorageNodeEntity(
      uuid: const Uuid().v4(),
      roomUuid: widget.roomUuid,
      parentUuid: null,
      nodeType: NodeType.storageLocation.name,
      name: storageLocationName.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final repo = ref.read(
      storageNodeRepositoryProvider,
    );

    repo.save(node);

    ref.read(
      storageRefreshProvider.notifier,
    ).state++;
  }

  @override
  Widget build(BuildContext context) {
    final storageAsync = ref.watch(
      storageLocationsProvider(
        widget.roomUuid,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
      ),
      floatingActionButton:
      FloatingActionButton(
        onPressed: _addStorageLocation,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            storageAsync.when(
              loading: () => Text(
                'Storage Locations',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),
              error: (_, __) => Text(
                'Storage Locations',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),
              data: (nodes) => Text(
                'Storage Locations (${nodes.length})',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: storageAsync.when(
                loading: () => const Center(
                  child:
                  CircularProgressIndicator(),
                ),
                error: (e, _) => Center(
                  child: Text(
                    e.toString(),
                  ),
                ),
                data: (nodes) {
                  if (nodes.isEmpty) {
                    return const Center(
                      child: Text(
                        'No storage locations yet',
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: nodes.length,
                    separatorBuilder:
                        (_, __) =>
                    const SizedBox(
                      height: 8,
                    ),
                    itemBuilder:
                        (_, index) {
                      final node =
                      nodes[index];

                      return Card(
                        child: ListTile(
                          leading:
                          const Icon(
                            Icons
                                .inventory_2,
                          ),
                          title: Text(
                            node.name,
                          ),
                          subtitle: Text(
                            node.nodeType,
                          ),
                          trailing:
                          const Icon(
                            Icons
                                .chevron_right,
                          ),
                          onTap: () {
                            context.push(
                              '/node/${node.uuid}',
                            );
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