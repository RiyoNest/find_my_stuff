import 'package:find_my_stuff/core/database/objectbox_service.dart';
import 'package:find_my_stuff/objectbox.g.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';

import '../enums/node_type.dart';

class StorageNodeRepository {
  final box = ObjectBoxService.store.box<StorageNodeEntity>();

  List<StorageNodeEntity> getStorageLocations(String roomUuid) {
    final query = box
        .query(
          StorageNodeEntity_.roomUuid.equals(roomUuid) &
              StorageNodeEntity_.parentUuid.isNull() &
              StorageNodeEntity_.nodeType.equals(NodeType.storageLocation.name),
        )
        .build();

    final result = query.find();
    query.close();

    return result;
  }

  List<StorageNodeEntity> getChildren(String parentUuid) {
    final query = box
        .query(StorageNodeEntity_.parentUuid.equals(parentUuid))
        .build();

    final result = query.find();

    query.close();

    return result;
  }

  StorageNodeEntity? getByUuid(String uuid) {
    final query = box.query(StorageNodeEntity_.uuid.equals(uuid)).build();

    final node = query.findFirst();

    query.close();

    return node;
  }

  List<StorageNodeEntity> getPathToRoot(StorageNodeEntity node) {
    final path = <StorageNodeEntity>[];

    StorageNodeEntity? current = node;

    while (current != null) {
      path.insert(0, current);

      if (current.parentUuid == null) {
        break;
      }

      current = getByUuid(current.parentUuid!);
    }

    return path;
  }

  Future<List<StorageNodeEntity>> searchItems(String query) async {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      return [];
    }

    return box.getAll().where((node) {
      final name = node.name.toLowerCase();

      final description = (node.description ?? '').toLowerCase();

      final tags = (node.tags ?? '').toLowerCase();

      return name.contains(q) || description.contains(q) || tags.contains(q);
    }).toList();
  }

  void markAsViewed(String uuid) {
    final node = getByUuid(uuid);

    if (node == null) {
      return;
    }

    node.viewedAt = DateTime.now();

    save(node);
  }

  List<StorageNodeEntity> getRecentlyViewed({int limit = 10}) {
    final items = box
        .getAll()
        .where((e) => e.nodeType == NodeType.item.name && e.viewedAt != null)
        .toList();

    items.sort((a, b) => b.viewedAt!.compareTo(a.viewedAt!));

    return items.take(limit).toList();
  }

  List<StorageNodeEntity> getForgottenItems({int limit = 10}) {
    final items = box
        .getAll()
        .where((e) => e.nodeType == NodeType.item.name && e.viewedAt != null)
        .toList();

    items.sort((a, b) => a.viewedAt!.compareTo(b.viewedAt!));

    return items.take(limit).toList();
  }

  int getTotalItems() {
    return box
        .query(StorageNodeEntity_.nodeType.equals(NodeType.item.name))
        .build()
        .count();
  }

  int getImportantItems() {
    return box
        .query(StorageNodeEntity_.isImportant.equals(true))
        .build()
        .count();
  }

  int getItemsWithPhotos() {
    return box
        .getAll()
        .where((e) => e.photoPath != null && e.photoPath!.isNotEmpty)
        .length;
  }

  int save(StorageNodeEntity node) {
    return box.put(node);
  }

  void delete(int id) {
    box.remove(id);
  }
}
