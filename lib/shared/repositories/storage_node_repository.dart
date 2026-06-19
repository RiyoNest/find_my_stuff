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
              StorageNodeEntity_.isArchived.equals(false) &
              StorageNodeEntity_.nodeType.equals(NodeType.storageLocation.name),
        )
        .build();

    final result = query.find();
    query.close();

    return result;
  }

  List<StorageNodeEntity> getChildren(String parentUuid) {
    final query = box
        .query(
          StorageNodeEntity_.parentUuid.equals(parentUuid) &
              StorageNodeEntity_.isArchived.equals(false),
        )
        .build();

    final result = query.find();

    query.close();

    return result;
  }

  List<StorageNodeEntity> getValidMoveDestinations(StorageNodeEntity source) {
    return box.getAll().where((node) {
      if (node.isArchived) {
        return false;
      }

      if (node.roomUuid != source.roomUuid) {
        return false;
      }

      // Can't move into itself
      if (node.uuid == source.uuid) {
        return false;
      }

      // Can't move into descendants
      if (isDescendant(source.uuid, node.uuid)) {
        return false;
      }

      switch (source.nodeType) {
        // ITEM
        case 'item':
          return node.nodeType != 'item';

        // CONTAINER
        case 'container':
          return node.nodeType == 'storageLocation' ||
              node.nodeType == 'section' ||
              node.nodeType == 'container';

        // SECTION
        case 'section':
          return node.nodeType == 'storageLocation';

        // STORAGE LOCATION
        case 'storageLocation':
          return false;

        default:
          return false;
      }
    }).toList();
  }

  StorageNodeEntity? getByUuid(String uuid) {
    final query = box.query(StorageNodeEntity_.uuid.equals(uuid)).build();

    final node = query.findFirst();

    query.close();

    return node;
  }

  bool isDescendant(String sourceUuid, String destinationUuid) {
    final destination = getByUuid(destinationUuid);

    if (destination == null) {
      return false;
    }

    StorageNodeEntity? current = destination;

    while (current != null) {
      if (current.uuid == sourceUuid) {
        return true;
      }

      if (current.parentUuid == null) {
        break;
      }

      current = getByUuid(current.parentUuid!);
    }

    return false;
  }

  bool canMoveNode(String sourceUuid, String destinationUuid) {
    if (sourceUuid == destinationUuid) {
      return false;
    }

    if (isDescendant(sourceUuid, destinationUuid)) {
      return false;
    }

    return true;
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

  String buildPath(StorageNodeEntity node) {
    final path = getPathToRoot(node);

    return path.map((e) => e.name).join(' > ');
  }

  Future<List<StorageNodeEntity>> searchItems(String query) async {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      return [];
    }

    return box.getAll().where((node) {
      if (node.isArchived) return false;
      final name = node.name.toLowerCase();

      final description = (node.description ?? '').toLowerCase();

      final tags = (node.tags ?? '').toLowerCase();

      return name.contains(q) || description.contains(q) || tags.contains(q);
    }).toList();
  }

  void markAsViewed(String uuid) {
    final node = getByUuid(uuid);

    if (node == null || node.isArchived) {
      return;
    }

    node.viewedAt = DateTime.now();

    save(node);
  }

  List<StorageNodeEntity> getRecentlyViewed({int limit = 10}) {
    final items = box
        .getAll()
        .where(
          (e) =>
              e.nodeType == NodeType.item.name &&
              !e.isArchived &&
              e.viewedAt != null,
        )
        .toList();

    items.sort((a, b) => b.viewedAt!.compareTo(a.viewedAt!));

    return items.take(limit).toList();
  }

  List<StorageNodeEntity> getForgottenItems({int limit = 10}) {
    final items = box
        .getAll()
        .where(
          (e) =>
              e.nodeType == NodeType.item.name &&
              !e.isArchived &&
              e.viewedAt != null,
        )
        .toList();

    items.sort((a, b) => a.viewedAt!.compareTo(b.viewedAt!));

    return items.take(limit).toList();
  }

  int getTotalItems() {
    return box
        .query(
          StorageNodeEntity_.nodeType.equals(NodeType.item.name) &
              StorageNodeEntity_.isArchived.equals(false),
        )
        .build()
        .count();
  }

  int getImportantItemCount() {
    return box
        .getAll()
        .where(
          (e) =>
              e.nodeType == NodeType.item.name &&
              e.isImportant &&
              !e.isArchived,
        )
        .length;
  }

  int getItemsWithPhotos() {
    return box
        .getAll()
        .where(
          (e) =>
              !e.isArchived && e.photoPath != null && e.photoPath!.isNotEmpty,
        )
        .length;
  }

  List<StorageNodeEntity> getArchivedItems() {
    return box.getAll().where((e) => e.isArchived).toList();
  }

  List<StorageNodeEntity> getImportantItems({int limit = 10}) {
    final items = box
        .getAll()
        .where(
          (e) =>
              e.nodeType == NodeType.item.name &&
              e.isImportant &&
              !e.isArchived,
        )
        .toList();

    items.sort((a, b) => a.name.compareTo(b.name));

    return items.take(limit).toList();
  }

  List<StorageNodeEntity> getExpiringItems({int days = 30}) {
    final now = DateTime.now();

    return box.getAll().where((item) {
      if (item.isArchived) return false;

      if (!item.trackExpiry) return false;

      if (item.expiryDate == null) return false;

      final difference = item.expiryDate!.difference(now).inDays;

      return difference >= 0 && difference <= days;
    }).toList();
  }

  List<StorageNodeEntity> getExpiredItems() {
    final now = DateTime.now();

    return box.getAll().where((item) {
      if (item.isArchived) return false;

      if (!item.trackExpiry) return false;

      if (item.expiryDate == null) return false;

      return item.expiryDate!.isBefore(now);
    }).toList();
  }

  void archiveItem(String uuid) {
    final item = getByUuid(uuid);

    if (item == null) return;

    item.isArchived = true;

    save(item);
  }

  void restoreItem(String uuid) {
    final item = getByUuid(uuid);

    if (item == null) return;

    item.isArchived = false;

    save(item);
  }

  List<StorageNodeEntity> getAllPossibleParents(String roomUuid) {
    return box.getAll().where((node) {
      return !node.isArchived &&
          node.roomUuid == roomUuid &&
          node.nodeType != 'item';
    }).toList();
  }

  void moveNode(String sourceUuid, String destinationUuid) {
    final source = getByUuid(sourceUuid);

    if (source == null) {
      return;
    }

    if (!canMoveNode(sourceUuid, destinationUuid)) {
      return;
    }

    source.parentUuid = destinationUuid;

    source.updatedAt = DateTime.now();

    save(source);
  }

  List<StorageNodeEntity> getQuickAddDestinations() {
    return box.getAll().where((node) {
      return !node.isArchived && node.nodeType != NodeType.item.name;
    }).toList();
  }

  int save(StorageNodeEntity node) {
    return box.put(node);
  }

  void delete(int id) {
    box.remove(id);
  }
}
