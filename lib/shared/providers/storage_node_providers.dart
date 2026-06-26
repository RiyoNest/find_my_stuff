import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/storage_node_entity.dart';
import '../repositories/storage_node_repository.dart';

final storageNodeRepositoryProvider = Provider<StorageNodeRepository>(
  (ref) => StorageNodeRepository(),
);

final storageRefreshProvider = StateProvider<int>((ref) => 0);

final storageNodeProvider = FutureProvider.family<StorageNodeEntity?, String>((
  ref,
  nodeUuid,
) async {
  ref.watch(storageRefreshProvider);

  final repo = ref.read(storageNodeRepositoryProvider);

  return repo.getByUuid(nodeUuid);
});

final storageLocationsProvider =
    FutureProvider.family<List<StorageNodeEntity>, String>((
      ref,
      roomUuid,
    ) async {
      ref.watch(storageRefreshProvider);

      final repo = ref.read(storageNodeRepositoryProvider);

      return repo.getStorageLocations(roomUuid);
    });

final childNodesProvider =
    FutureProvider.family<List<StorageNodeEntity>, String>((
      ref,
      parentUuid,
    ) async {
      ref.watch(storageRefreshProvider);

      final repo = ref.read(storageNodeRepositoryProvider);

      return repo.getChildren(parentUuid);
    });

final searchProvider = FutureProvider.family<List<StorageNodeEntity>, String>((
  ref,
  query,
) async {
  if (query.trim().isEmpty) {
    return [];
  }

  final repo = ref.read(storageNodeRepositoryProvider);

  return repo.searchItems(query);
});

final recentlyViewedProvider = FutureProvider<List<StorageNodeEntity>>((
  ref,
) async {
  ref.watch(storageRefreshProvider);
  final repo = ref.read(storageNodeRepositoryProvider);

  return repo.getRecentlyViewed();
});

final forgottenItemsProvider = FutureProvider<List<StorageNodeEntity>>((
  ref,
) async {
  ref.watch(storageRefreshProvider);
  final repo = ref.read(storageNodeRepositoryProvider);

  return repo.getForgottenItems();
});

final dashboardStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  ref.watch(storageRefreshProvider);

  final repo = ref.read(storageNodeRepositoryProvider);

  return {
    'items': repo.getTotalItems(),
    'important': repo.getImportantItemCount(),
    'photos': repo.getItemsWithPhotos(),
  };
});

final importantItemsProvider = FutureProvider<List<StorageNodeEntity>>((
  ref,
) async {
  ref.watch(storageRefreshProvider);

  final repo = ref.read(storageNodeRepositoryProvider);

  return repo.getImportantItems();
});

final expiringItemsProvider = FutureProvider<List<StorageNodeEntity>>((
  ref,
) async {
  ref.watch(storageRefreshProvider);

  final repo = ref.read(storageNodeRepositoryProvider);

  return repo.getExpiringItems();
});

final expiredItemsProvider = FutureProvider<List<StorageNodeEntity>>((
  ref,
) async {
  ref.watch(storageRefreshProvider);

  final repo = ref.read(storageNodeRepositoryProvider);

  return repo.getExpiredItems();
});

final archivedItemsProvider = FutureProvider<List<StorageNodeEntity>>((
  ref,
) async {
  ref.watch(storageRefreshProvider);
  final repo = ref.read(storageNodeRepositoryProvider);

  return repo.getArchivedItems();
});

final allItemsProvider = FutureProvider<List<StorageNodeEntity>>((
  ref,
) async {
  ref.watch(storageRefreshProvider);
  final repo = ref.read(storageNodeRepositoryProvider);

  return repo.getAllItems();
});

final itemsWithPhotosProvider = FutureProvider<List<StorageNodeEntity>>((
  ref,
) async {
  ref.watch(storageRefreshProvider);
  final repo = ref.read(storageNodeRepositoryProvider);

  return repo.getItemsWithPhotosList();
});

final moveDestinationsProvider =
    FutureProvider.family<List<StorageNodeEntity>, StorageNodeEntity>((
      ref,
      sourceNode,
    ) async {
      final repo = ref.read(storageNodeRepositoryProvider);

      return repo.getValidMoveDestinations(sourceNode);
    });

final quickAddDestinationsProvider = FutureProvider<List<StorageNodeEntity>>((
  ref,
) async {
  final repo = ref.read(storageNodeRepositoryProvider);

  return repo.getQuickAddDestinations();
});

final nodeChildrenProvider =
    FutureProvider.family<List<StorageNodeEntity>, String>((
      ref,
      parentUuid,
    ) async {
      ref.watch(storageRefreshProvider);

      final repo = ref.read(storageNodeRepositoryProvider);

      return repo.getChildren(parentUuid);
    });
