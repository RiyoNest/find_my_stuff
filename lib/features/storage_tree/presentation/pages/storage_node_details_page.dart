import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/storage_node_providers.dart';

class StorageNodeDetailsPage extends ConsumerWidget {
  final String nodeUuid;

  const StorageNodeDetailsPage({
    super.key,
    required this.nodeUuid,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final nodeAsync = ref.watch(
      storageNodeProvider(nodeUuid),
    );

    return nodeAsync.when(
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
      data: (node) {
        if (node == null) {
          return const Scaffold(
            body: Center(
              child: Text('Node not found'),
            ),
          );
        }

        final childrenAsync = ref.watch(
          childNodesProvider(node.uuid),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(node.name),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                childrenAsync.when(
                  loading: () => Text(
                    'Children',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),
                  error: (_, __) => Text(
                    'Children',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),
                  data: (children) => Text(
                    'Children (${children.length})',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: childrenAsync.when(
                    loading: () => const Center(
                      child:
                      CircularProgressIndicator(),
                    ),
                    error: (e, _) => Center(
                      child: Text(
                        e.toString(),
                      ),
                    ),
                    data: (children) {
                      if (children.isEmpty) {
                        return const Center(
                          child: Text(
                            'No children added yet',
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: children.length,
                        itemBuilder: (_, index) {
                          final child =
                          children[index];

                          return Card(
                            child: ListTile(
                              title: Text(
                                child.name,
                              ),
                              subtitle: Text(
                                child.nodeType,
                              ),
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