import 'package:find_my_stuff/features/storage_tree/presentation/pages/item_details_page.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/enums/node_type.dart';
import 'package:find_my_stuff/shared/models/add_child_node_result.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../widgets/add_child_node_dialog.dart';

class StorageNodeDetailsPage extends ConsumerStatefulWidget {
  final String nodeUuid;

  const StorageNodeDetailsPage({super.key, required this.nodeUuid});

  @override
  ConsumerState<StorageNodeDetailsPage> createState() =>
      _StorageNodeDetailsPageState();
}

class _StorageNodeDetailsPageState
    extends ConsumerState<StorageNodeDetailsPage> {
  Future<void> _addChildNode(StorageNodeEntity parentNode) async {
    final result = await showDialog<AddChildNodeResult>(
      context: context,
      builder: (_) => const AddChildNodeDialog(),
    );

    if (result == null) {
      return;
    }

    final childNode = StorageNodeEntity(
      uuid: const Uuid().v4(),
      roomUuid: parentNode.roomUuid,
      parentUuid: parentNode.uuid,
      nodeType: result.nodeType.name,
      name: result.name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final repo = ref.read(storageNodeRepositoryProvider);

    repo.save(childNode);

    ref.read(storageRefreshProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context) {
    final nodeAsync = ref.watch(storageNodeProvider(widget.nodeUuid));

    return nodeAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (node) {
        if (node == null) {
          return const Scaffold(body: Center(child: Text('Node not found')));
        }

        /// ITEM SCREEN

        if (node.nodeType == NodeType.item.name) {
          return ItemDetailsPage(
            nodeUuid: node.uuid,
          );
        }

        final childrenAsync = ref.watch(childNodesProvider(node.uuid));

        return Scaffold(
          appBar: AppBar(title: Text(node.name)),
          floatingActionButton: FloatingActionButton(
            heroTag: 'node_add_child',
            onPressed: () => _addChildNode(node),
            child: const Icon(Icons.add),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                childrenAsync.when(
                  loading: () => Text(
                    'Children',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  error: (_, __) => Text(
                    'Children',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  data: (children) => Text(
                    'Children (${children.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: childrenAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text(e.toString())),
                    data: (children) {
                      if (children.isEmpty) {
                        return const Center(
                          child: Text('No children added yet'),
                        );
                      }

                      return ListView.separated(
                        itemCount: children.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final child = children[index];

                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.folder_outlined),
                              title: Text(child.name),
                              subtitle: Text(child.nodeType),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                context.push('/node/${child.uuid}');
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
      },
    );
  }
}
