import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:find_my_stuff/shared/models/storage_path.dart';

import 'storage_node_providers.dart';

final storagePathProvider =
    FutureProvider.family<StoragePath, String>((
      ref,
      nodeUuid,
    ) async {
      final repo = ref.read(storageNodeRepositoryProvider);

      final node = repo.getByUuid(nodeUuid);

      if (node == null) {
        return const StoragePath([]);
      }

      return repo.getStoragePath(node);
    });

