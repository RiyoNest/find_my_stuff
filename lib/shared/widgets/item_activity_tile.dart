import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ItemActivityTile extends ConsumerWidget {
  final StorageNodeEntity item;

  const ItemActivityTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(storageNodeRepositoryProvider);
    final path = repo.buildPath(item);

    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.inventory_2_outlined,
        ),
        title: Text(item.name),
        subtitle: path.isNotEmpty ? Text(path) : null,
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: () {
          context.push(
            '/node/${item.uuid}',
          );
        },
      ),
    );
  }
}