import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/storage_node_entity.dart';
import '../repositories/storage_node_repository.dart';

final storageNodeRepositoryProvider =
Provider<StorageNodeRepository>(
      (ref) => StorageNodeRepository(),
);

final storageRefreshProvider =
StateProvider<int>((ref) => 0);

final storageNodeProvider =
FutureProvider.family<
    StorageNodeEntity?,
    String>(
      (ref, nodeUuid) async {
    final repo = ref.read(
      storageNodeRepositoryProvider,
    );

    return repo.getByUuid(nodeUuid);
  },
);

final storageLocationsProvider =
FutureProvider.family<
    List<StorageNodeEntity>,
    String>((ref, roomUuid) async {
  ref.watch(storageRefreshProvider);

  final repo =
  ref.read(storageNodeRepositoryProvider);

  return repo.getStorageLocations(roomUuid);
});

final childNodesProvider =
FutureProvider.family<
    List<StorageNodeEntity>,
    String>(
      (ref, parentUuid) async {
    ref.watch(storageRefreshProvider);

    final repo = ref.read(
      storageNodeRepositoryProvider,
    );

    return repo.getChildren(parentUuid);
  },
);