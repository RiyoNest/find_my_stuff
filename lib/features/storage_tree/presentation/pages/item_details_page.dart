import 'dart:io';

import 'package:find_my_stuff/features/storage_tree/presentation/pages/photo_viewer_page.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/providers/storage_path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edit_item_page.dart';
import 'move_node_page.dart';

class ItemDetailsPage extends ConsumerStatefulWidget {
  final String nodeUuid;

  const ItemDetailsPage({super.key, required this.nodeUuid});

  @override
  ConsumerState<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends ConsumerState<ItemDetailsPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(storageNodeRepositoryProvider);

      repo.markAsViewed(widget.nodeUuid);

      ref.invalidate(recentlyViewedProvider);

      ref.invalidate(forgottenItemsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final nodeAsync = ref.watch(storageNodeProvider(widget.nodeUuid));
    final pathAsync = ref.watch(storagePathProvider(widget.nodeUuid));

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

                  ref.invalidate(storageNodeProvider(widget.nodeUuid));
                },
              ),
              IconButton(
                icon: const Icon(Icons.drive_file_move),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MoveNodePage(node: node)),
                  );

                  ref.read(storageRefreshProvider.notifier).state++;

                  if (mounted) {
                    ref.invalidate(storageNodeProvider(widget.nodeUuid));
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.archive),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Archive Item'),
                      content: Text('Move "${node.name}" to archive?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                          child: const Text('Archive'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) {
                    return;
                  }

                  final repo = ref.read(storageNodeRepositoryProvider);

                  repo.archiveItem(node.uuid);

                  ref.read(storageRefreshProvider.notifier).state++;

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    if (node.isImportant) const Chip(label: Text('Important')),

                    if (node.trackExpiry)
                      const Chip(label: Text('Expiry Tracked')),
                  ],
                ),

                if (node.trackExpiry && node.expiryDate != null)
                  Builder(
                    builder: (_) {
                      final daysLeft = node.expiryDate!
                          .difference(DateTime.now())
                          .inDays;

                      Color color;

                      String status;

                      if (daysLeft < 0) {
                        color = Colors.red;
                        status = 'Expired';
                      } else if (daysLeft <= 30) {
                        color = Colors.orange;
                        status = '$daysLeft days remaining';
                      } else {
                        color = Colors.green;
                        status = '$daysLeft days remaining';
                      }

                      return Card(
                        color: color.withOpacity(0.1),
                        child: ListTile(
                          leading: Icon(Icons.event, color: color),
                          title: Text('Expiry Date'),
                          subtitle: Text(
                            '${node.expiryDate!.day}/${node.expiryDate!.month}/${node.expiryDate!.year}',
                          ),
                          trailing: Text(
                            status,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

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

                if (node.photoPath != null && node.photoPath!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Photo',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),

                      const SizedBox(height: 8),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PhotoViewerPage(
                                  imagePath: node.photoPath!,
                                  itemUuid: node.uuid,
                                  itemName: node.name,
                                ),
                              ),
                            );
                          },
                          child: Hero(
                            tag: node.photoPath!,
                            child: File(node.photoPath!).existsSync()
                                ? Image.file(
                                    File(node.photoPath!),
                                    height: 220,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 220,
                                    width: double.infinity,
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 60,
                                    ),
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
