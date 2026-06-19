import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edit_item_page.dart';

class ItemDetailsPage extends ConsumerWidget {
  final String nodeUuid;

  const ItemDetailsPage({super.key, required this.nodeUuid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodeAsync = ref.watch(storageNodeProvider(nodeUuid));

    return nodeAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (node) {
        if (node == null) {
          return const Scaffold(body: Center(child: Text('Item not found')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(node.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditItemPage(node: node)),
                  );

                  ref.invalidate(storageNodeProvider(nodeUuid));
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (node.isImportant) const Chip(label: Text('Important')),

                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium,
                ),

                const SizedBox(height: 8),

                Text(
                  node.description?.isNotEmpty == true
                      ? node.description!
                      : 'No description available',
                ),

                const SizedBox(height: 24),

                Text('Tags', style: Theme.of(context).textTheme.titleMedium),

                const SizedBox(height: 8),

                Text(node.tags?.isNotEmpty == true ? node.tags! : 'No tags'),
              ],
            ),
          ),
        );
      },
    );
  }
}
