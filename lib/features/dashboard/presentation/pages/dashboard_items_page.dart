import 'dart:io';

import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardItemsPage extends ConsumerWidget {
  final String title;
  final List<StorageNodeEntity> items;

  const DashboardItemsPage({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(storageNodeRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: items.isEmpty
          ? const Center(child: Text('No items found'))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final item = items[index];

                final path = repo.buildPath(item);

                return ListTile(
                  leading: item.photoPath != null &&
                      item.photoPath!.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(item.photoPath!),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                      : const Icon(Icons.inventory_2),

                  title: Text(item.name),

                  subtitle: Text(path),

                  trailing: item.isImportant
                      ? const Icon(
                    Icons.star,
                    color: Colors.amber,
                  )
                      : null,

                  onTap: () {
                    context.push('/node/${item.uuid}');
                  },
                );
              },
            ),
    );
  }
}
