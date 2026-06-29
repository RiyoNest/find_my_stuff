import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/entities/room_entity.dart';
import 'package:find_my_stuff/shared/enums/node_type.dart';
import 'package:find_my_stuff/shared/repositories/storage_node_repository.dart';
import 'package:find_my_stuff/shared/repositories/room_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/providers/room_providers.dart';

class SuggestionPath {
  final RoomEntity room;
  final StorageNodeEntity? location;
  final StorageNodeEntity? section;
  final StorageNodeEntity? container;
  final String label; // "Highly Recommended", "Frequently Used", "Recently Used"
  final String reason;

  SuggestionPath({
    required this.room,
    this.location,
    this.section,
    this.container,
    required this.label,
    required this.reason,
  });

  String get displayString {
    final parts = [room.name];
    if (location != null) parts.add(location!.name);
    if (section != null) parts.add(section!.name);
    if (container != null) parts.add(container!.name);
    return parts.join(' → ');
  }
}

class SuggestionService {
  final StorageNodeRepository _repository;
  final RoomRepository _roomRepository;

  SuggestionService(this._repository, this._roomRepository);

  /// Get the top 5 most frequently used location paths.
  List<SuggestionPath> getFrequentlyUsedLocations() {
    final allItems = _repository.box
        .getAll()
        .where((e) => e.nodeType == NodeType.item.name && !e.isArchived)
        .toList();

    if (allItems.isEmpty) return [];

    final pathCounts = <String, int>{};
    final pathsMap = <String, SuggestionPath>{};

    for (final item in allItems) {
      final room = _roomRepository.getByUuid(item.roomUuid);
      if (room == null) continue;

      final pathNodes = _repository.getPathToRoot(item);
      final parentNodes = pathNodes.where((n) => n.uuid != item.uuid).toList();
      if (parentNodes.isEmpty) continue;

      StorageNodeEntity? loc;
      StorageNodeEntity? sec;
      StorageNodeEntity? con;

      for (final node in parentNodes) {
        if (node.nodeType == NodeType.storageLocation.name) {
          loc = node;
        } else if (node.nodeType == NodeType.section.name) {
          sec = node;
        } else if (node.nodeType == NodeType.container.name) {
          con = node;
        }
      }

      if (loc == null) continue;

      final sp = SuggestionPath(
        room: room,
        location: loc,
        section: sec,
        container: con,
        label: 'Frequently Used',
        reason: 'Most frequently used location',
      );

      final key = sp.displayString;
      pathCounts[key] = (pathCounts[key] ?? 0) + 1;
      pathsMap[key] = sp;
    }

    final sortedKeys = pathCounts.keys.toList()
      ..sort((a, b) => pathCounts[b]!.compareTo(pathCounts[a]!));

    return sortedKeys.map((k) => pathsMap[k]!).take(5).toList();
  }

  /// Suggest locations using a weighted confidence score.
  /// Similar item names: 50%
  /// Frequently used locations: 30%
  /// Recently used locations: 20%
  List<SuggestionPath> getSuggestions(String name) {
    final query = name.trim().toLowerCase();
    if (query.isEmpty) return [];

    final allItems = _repository.box
        .getAll()
        .where((e) => e.nodeType == NodeType.item.name && !e.isArchived)
        .toList();

    if (allItems.isEmpty) return [];

    // 1. Group items by parent paths
    final pathItems = <String, List<StorageNodeEntity>>{};
    final pathsMap = <String, SuggestionPath>{};

    for (final item in allItems) {
      final room = _roomRepository.getByUuid(item.roomUuid);
      if (room == null) continue;

      final pathNodes = _repository.getPathToRoot(item);
      final parentNodes = pathNodes.where((n) => n.uuid != item.uuid).toList();
      if (parentNodes.isEmpty) continue;

      StorageNodeEntity? loc;
      StorageNodeEntity? sec;
      StorageNodeEntity? con;

      for (final node in parentNodes) {
        if (node.nodeType == NodeType.storageLocation.name) {
          loc = node;
        } else if (node.nodeType == NodeType.section.name) {
          sec = node;
        } else if (node.nodeType == NodeType.container.name) {
          con = node;
        }
      }

      if (loc == null) continue;

      final sp = SuggestionPath(
        room: room,
        location: loc,
        section: sec,
        container: con,
        label: 'Recently Used',
        reason: '',
      );

      final key = sp.displayString;
      pathsMap[key] = sp;
      pathItems.putIfAbsent(key, () => []).add(item);
    }

    // 2. Compute similarity score (50%)
    // Similarity = number of items matching the query in this path
    final similarityScores = <String, double>{};
    final similarityCounts = <String, int>{};
    for (final entry in pathItems.entries) {
      int count = 0;
      for (final item in entry.value) {
        final itemName = item.name.toLowerCase();
        if (itemName == query) {
          count += 3; // exact match gets extra weight
        } else if (itemName.contains(query)) {
          count += 1;
        }
      }
      similarityCounts[entry.key] = count;
    }
    final maxSimilarity = similarityCounts.values.fold(0, (max, val) => val > max ? val : max);
    if (maxSimilarity > 0) {
      for (final key in similarityCounts.keys) {
        similarityScores[key] = similarityCounts[key]! / maxSimilarity;
      }
    }

    // 3. Frequently Used score (30%)
    final frequencies = pathItems.map((key, list) => MapEntry(key, list.length));
    final maxFrequency = frequencies.values.fold(0, (max, val) => val > max ? val : max);
    final frequencyScores = <String, double>{};
    if (maxFrequency > 0) {
      for (final key in frequencies.keys) {
        frequencyScores[key] = frequencies[key]! / maxFrequency;
      }
    }

    // 4. Recently Used score (20%)
    // Sort all items by createdAt/updatedAt descending to find recency of each path
    final sortedItems = List<StorageNodeEntity>.from(allItems)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recencyScores = <String, double>{};
    for (int i = 0; i < sortedItems.length; i++) {
      final item = sortedItems[i];
      final pathNodes = _repository.getPathToRoot(item);
      final parentNodes = pathNodes.where((n) => n.uuid != item.uuid).toList();
      if (parentNodes.isEmpty) continue;

      StorageNodeEntity? loc;
      StorageNodeEntity? sec;
      StorageNodeEntity? con;

      for (final node in parentNodes) {
        if (node.nodeType == NodeType.storageLocation.name) {
          loc = node;
        } else if (node.nodeType == NodeType.section.name) {
          sec = node;
        } else if (node.nodeType == NodeType.container.name) {
          con = node;
        }
      }
      if (loc == null) continue;

      final room = _roomRepository.getByUuid(item.roomUuid);
      if (room == null) continue;

      final displayStr = [
        room.name,
        loc.name,
        if (sec != null) sec.name,
        if (con != null) con.name,
      ].join(' → ');

      if (!recencyScores.containsKey(displayStr)) {
        // Higher score for items closer to index 0 (the newest item)
        recencyScores[displayStr] = (sortedItems.length - i) / sortedItems.length;
      }
    }

    // 5. Calculate weighted score for each path
    final pathScores = <String, double>{};
    for (final key in pathItems.keys) {
      final sim = similarityScores[key] ?? 0.0;
      final freq = frequencyScores[key] ?? 0.0;
      final rec = recencyScores[key] ?? 0.0;
      pathScores[key] = (sim * 0.50) + (freq * 0.30) + (rec * 0.20);
    }

    // Sort paths by score descending
    final sortedKeys = pathScores.keys.toList()
      ..sort((a, b) => pathScores[b]!.compareTo(pathScores[a]!));

    final results = <SuggestionPath>[];
    for (final key in sortedKeys) {
      final base = pathsMap[key]!;
      final simCount = similarityCounts[key] ?? 0;
      final totalCount = pathItems[key]?.length ?? 0;
      
      String label;
      String reason;

      if (simCount > 0) {
        label = 'Highly Recommended';
        reason = 'Used for $simCount similar ${simCount == 1 ? 'item' : 'items'}';
      } else if (totalCount == maxFrequency && maxFrequency > 0) {
        label = 'Frequently Used';
        reason = 'Most frequently used location';
      } else {
        label = 'Recently Used';
        reason = 'Recently selected';
      }

      results.add(SuggestionPath(
        room: base.room,
        location: base.location,
        section: base.section,
        container: base.container,
        label: label,
        reason: reason,
      ));
    }

    return results.take(3).toList();
  }
}

final suggestionServiceProvider = Provider<SuggestionService>((ref) {
  final repository = ref.read(storageNodeRepositoryProvider);
  final roomRepository = ref.read(roomRepositoryProvider);
  return SuggestionService(repository, roomRepository);
});
