import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArchivedItemsPage extends ConsumerWidget {
  const ArchivedItemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedAsync = ref.watch(
      archivedItemsProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Archived Items',
        ),
      ),
      body: archivedAsync.when(
        loading: () =>
        const Center(
          child: CircularProgressIndicator(),
        ),

        error: (e, _) =>
            Center(
              child: Text(
                e.toString(),
              ),
            ),

        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No archived items',
              ),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, index) {
              final item = items[index];

              return _ArchivedItemTile(
                item: item,
              );
            },
          );
        },
      ),
    );
  }
}

class _ArchivedItemTile extends ConsumerWidget {
  final StorageNodeEntity item;

  const _ArchivedItemTile({
    required this.item,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: ListTile(
        leading: const Icon(
          Icons.archive,
        ),

        title: Text(
          item.name,
        ),

        subtitle: Text(
          item.description ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        trailing: IconButton(
          icon: const Icon(
            Icons.unarchive,
          ),
          tooltip: 'Restore',
          onPressed: () {
            final repo = ref.read(
              storageNodeRepositoryProvider,
            );

            repo.restoreItem(
              item.uuid,
            );

            ref.invalidate(
              archivedItemsProvider,
            );

            ref.read(
              storageRefreshProvider.notifier,
            ).state++;
          },
        ),
      ),
    );
  }
}