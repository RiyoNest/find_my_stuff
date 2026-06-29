import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/enums/node_type.dart';
import 'package:find_my_stuff/shared/repositories/storage_node_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';

enum SearchSortOption {
  newest,
  oldest,
  alphabetical,
  recentlyUpdated,
  location,
}

enum SearchFilterOption {
  all,
  important,
  forgotten,
  archived,
  expiring,
  hasPhotos,
}

class SearchService {
  final StorageNodeRepository _repository;

  SearchService(this._repository);

  /// Performs a filtered, sorted, and ranked search on the storage inventory.
  List<StorageNodeEntity> search({
    required String query,
    required SearchFilterOption filter,
    required SearchSortOption sortBy,
  }) {
    final q = query.trim().toLowerCase();
    var list = _repository.box.getAll();

    // 1. Filter by Archive State (Archived filter shows ONLY archived, others hide archived)
    if (filter == SearchFilterOption.archived) {
      list = list.where((node) => node.isArchived).toList();
    } else {
      list = list.where((node) => !node.isArchived).toList();
    }

    // 2. Filter by search query (name, description, tags matches)
    if (q.isNotEmpty) {
      list = list.where((node) {
        final name = node.name.toLowerCase();
        final description = (node.description ?? '').toLowerCase();
        final tags = (node.tags ?? '').toLowerCase();
        return name.contains(q) || description.contains(q) || tags.contains(q);
      }).toList();
    }

    // 3. Apply custom filter categories
    if (filter == SearchFilterOption.important) {
      list = list.where((node) => node.isImportant).toList();
    } else if (filter == SearchFilterOption.forgotten) {
      // Forgotten items are items that have been viewed, sorted oldest first
      list = list.where((node) =>
        node.nodeType == NodeType.item.name && node.viewedAt != null
      ).toList();
    } else if (filter == SearchFilterOption.expiring) {
      list = list.where((node) => node.trackExpiry && node.expiryDate != null).toList();
    } else if (filter == SearchFilterOption.hasPhotos) {
      list = list.where((node) => node.photoPath != null && node.photoPath!.trim().isNotEmpty).toList();
    }

    // 4. Sort and Rank results
    if (q.isNotEmpty) {
      // Rank by query relevance score, breaking ties with the selected sort option
      list.sort((a, b) {
        final scoreA = _calculateScore(a, q);
        final scoreB = _calculateScore(b, q);
        if (scoreA != scoreB) {
          return scoreB.compareTo(scoreA); // Higher relevance score first
        }
        return _compareNodes(a, b, sortBy);
      });
    } else {
      // Just sort by selected sort option
      list.sort((a, b) => _compareNodes(a, b, sortBy));
    }

    return list;
  }

  /// Calculates a relevance score for a search result.
  int _calculateScore(StorageNodeEntity node, String query) {
    final name = node.name.toLowerCase();
    if (name == query) return 1000;
    if (name.startsWith(query)) return 500;
    if (name.contains(query)) return 100;

    final desc = (node.description ?? '').toLowerCase();
    if (desc.contains(query)) return 10;

    final tags = (node.tags ?? '').toLowerCase();
    if (tags.contains(query)) return 5;

    return 0;
  }

  /// Compares two nodes based on the active Sort Option.
  int _compareNodes(StorageNodeEntity a, StorageNodeEntity b, SearchSortOption sortBy) {
    switch (sortBy) {
      case SearchSortOption.newest:
        return b.createdAt.compareTo(a.createdAt);
      case SearchSortOption.oldest:
        return a.createdAt.compareTo(b.createdAt);
      case SearchSortOption.alphabetical:
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case SearchSortOption.recentlyUpdated:
        return b.updatedAt.compareTo(a.updatedAt);
      case SearchSortOption.location:
        final pathA = _repository.buildPath(a);
        final pathB = _repository.buildPath(b);
        return pathA.compareTo(pathB);
    }
  }
}

// Riverpod Provider definitions
final searchServiceProvider = Provider<SearchService>((ref) {
  final repository = ref.read(storageNodeRepositoryProvider);
  return SearchService(repository);
});
