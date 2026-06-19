import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/storage_node_entity.dart';
import 'storage_node_providers.dart';

final storagePathProvider =
FutureProvider.family<
    List<StorageNodeEntity>,
    String
>(
      (ref, nodeUuid) async {
    final repo =
    ref.read(storageNodeRepositoryProvider);

    final node = repo.getByUuid(nodeUuid);

    if (node == null) {
      return [];
    }

    return repo.getPathToRoot(node);
  },
);