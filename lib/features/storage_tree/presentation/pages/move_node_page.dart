import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MoveNodePage extends ConsumerStatefulWidget {
  final StorageNodeEntity node;

  const MoveNodePage({super.key, required this.node});

  @override
  ConsumerState<MoveNodePage> createState() => _MoveNodePageState();
}

class _MoveNodePageState extends ConsumerState<MoveNodePage> {
  String? selectedDestinationUuid;

  Future<void> _moveNode() async {
    if (selectedDestinationUuid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination')),
      );
      return;
    }

    final repo = ref.read(storageNodeRepositoryProvider);

    final canMove = repo.canMoveNode(
      widget.node.uuid,
      selectedDestinationUuid!,
    );

    if (!canMove) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid move destination')));
      return;
    }

    repo.moveNode(widget.node.uuid, selectedDestinationUuid!);

    ref.read(storageRefreshProvider.notifier).state++;

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinationsAsync = ref.watch(moveDestinationsProvider(widget.node));

    return Scaffold(
      appBar: AppBar(title: Text('Move ${widget.node.name}')),
      body: destinationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (e, _) => Center(child: Text(e.toString())),

        data: (destinations) {
          final repo = ref.read(storageNodeRepositoryProvider);


          if (destinations.isEmpty) {
            return const Center(child: Text('No valid destinations found'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: destinations.length,
                  itemBuilder: (_, index) {
                    final destination = destinations[index];

                    final path = repo.buildPath(destination);

                    return RadioListTile<String>(
                      value: destination.uuid,
                      groupValue: selectedDestinationUuid,
                      title: Text(destination.name),
                      subtitle: Text(path),
                      onChanged: (value) {
                        setState(() {
                          selectedDestinationUuid = value;
                        });
                      },
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _moveNode,
                    icon: const Icon(Icons.drive_file_move),
                    label: const Text('Move Here'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
