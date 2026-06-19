import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/storage_path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


class SearchResultTile
    extends ConsumerWidget {
  final StorageNodeEntity item;

  const SearchResultTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final pathAsync = ref.watch(
      storagePathProvider(
        item.uuid,
      ),
    );

    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.inventory_2_outlined,
        ),
        title: Text(item.name),
        subtitle: pathAsync.when(
          loading: () =>
          const Text('Loading path...'),
          error: (_, __) =>
          const SizedBox(),
          data: (path) {
            final text = path
                .map(
                  (e) => e.name,
            )
                .join(' > ');

            return Text(text);
          },
        ),
        trailing:
        const Icon(Icons.chevron_right),
        onTap: () {
          context.push(
            '/node/${item.uuid}',
          );
        },
      ),
    );
  }
}