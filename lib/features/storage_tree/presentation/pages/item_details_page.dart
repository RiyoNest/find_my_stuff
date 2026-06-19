import 'dart:io';

import 'package:find_my_stuff/features/storage_tree/presentation/pages/photo_viewer_page.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/providers/storage_path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edit_item_page.dart';

class ItemDetailsPage extends ConsumerWidget {
  final String nodeUuid;

  const ItemDetailsPage({super.key, required this.nodeUuid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodeAsync = ref.watch(storageNodeProvider(nodeUuid));
    final pathAsync = ref.watch(storagePathProvider(nodeUuid));

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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (node.isImportant) const Chip(label: Text('Important')),

                pathAsync.when(
                  loading: () => const CircularProgressIndicator(),

                  error: (_, __) => const SizedBox(),

                  data: (path) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),

                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: path
                              .map((node) => Chip(label: Text(node.name)))
                              .toList(),
                        ),

                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),

                if (node.photoPath != null &&
                    node.photoPath!.isNotEmpty)
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Photo',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium,
                      ),

                      const SizedBox(height: 8),

                      ClipRRect(
                        borderRadius:
                        BorderRadius.circular(12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PhotoViewerPage(
                                  imagePath: node.photoPath!,
                                ),
                              ),
                            );
                          },
                          child: Hero(
                            tag: node.photoPath!,
                            child: Image.file(
                              File(node.photoPath!),
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),

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
