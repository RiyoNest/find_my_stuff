import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ItemActivityTile extends StatelessWidget {
  final StorageNodeEntity item;

  const ItemActivityTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.inventory_2_outlined,
        ),
        title: Text(item.name),
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