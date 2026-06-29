import 'package:find_my_stuff/core/database/objectbox_service.dart';
import 'package:find_my_stuff/objectbox.g.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/entities/room_entity.dart';
import 'package:find_my_stuff/shared/models/storage_path.dart';
import 'package:path/path.dart' as p;
import 'package:find_my_stuff/core/services/photo_storage_service.dart';

import '../enums/node_type.dart';

class StorageNodeRepository {
  final box = ObjectBoxService.store.box<StorageNodeEntity>();

  final Map<String, StoragePath> _pathCache = {};
  final Map<String, RoomEntity> _roomCache = {};

  void clearCache() {
    _pathCache.clear();
    _roomCache.clear();
  }

  StorageNodeEntity? _migrateNode(StorageNodeEntity? node) {
    if (node == null) return null;
    final photo = node.photoPath;
    if (photo != null && photo.isNotEmpty) {
      if (p.isAbsolute(photo)) {
        final relative = PhotoStorageService.tryMigrateToRelative(photo);
        if (relative != null && relative != photo) {
          node.photoPath = relative;
          box.put(node);
        }
      }
    }
    return node;
  }

  List<StorageNodeEntity> _migrateNodes(List<StorageNodeEntity> list) {
    for (final node in list) {
      _migrateNode(node);
    }
    return list;
  }

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

    return _migrateNodes(result);
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

    return _migrateNodes(result);
  }

  List<StorageNodeEntity> getValidMoveDestinations(StorageNodeEntity source) {
    final list = box.getAll().where((node) {
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
    return _migrateNodes(list);
  }

  StorageNodeEntity? getByUuid(String uuid) {
    final query = box.query(StorageNodeEntity_.uuid.equals(uuid)).build();

    final node = query.findFirst();

    query.close();

    return _migrateNode(node);
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

  StoragePath getStoragePath(StorageNodeEntity node) {
    if (_pathCache.containsKey(node.uuid)) {
      return _pathCache[node.uuid]!;
    }

    final segments = <StoragePathSegment>[];

    StorageNodeEntity? current = node;

    while (current != null) {
      if (current.uuid != node.uuid || current.nodeType != NodeType.item.name) {
        StoragePathSegmentType? type;
        if (current.nodeType == NodeType.storageLocation.name) {
          type = StoragePathSegmentType.storageLocation;
        } else if (current.nodeType == NodeType.section.name) {
          type = StoragePathSegmentType.section;
        } else if (current.nodeType == NodeType.container.name) {
          type = StoragePathSegmentType.container;
        }

        if (type != null) {
          segments.insert(
            0,
            StoragePathSegment(
              uuid: current.uuid,
              name: current.name,
              type: type,
            ),
          );
        }
      }

      if (current.parentUuid == null) {
        break;
      }

      current = getByUuid(current.parentUuid!);
    }

    final roomUuid = node.roomUuid;
    RoomEntity? room = _roomCache[roomUuid];
    if (room == null) {
      final roomBox = ObjectBoxService.store.box<RoomEntity>();
      final query = roomBox.query(RoomEntity_.uuid.equals(roomUuid)).build();
      room = query.findFirst();
      query.close();
      if (room != null) {
        _roomCache[roomUuid] = room;
      }
    }

    if (room != null) {
      segments.insert(
        0,
        StoragePathSegment(
          uuid: room.uuid,
          name: room.name,
          type: StoragePathSegmentType.room,
        ),
      );
    }

    final path = StoragePath(segments);
    _pathCache[node.uuid] = path;
    return path;
  }

  StoragePath getDestinationPath(StorageNodeEntity node) {
    return getStoragePath(node);
  }

  int countChildLocations(String uuid) {
    final query = box
        .query(
          StorageNodeEntity_.parentUuid.equals(uuid) &
              StorageNodeEntity_.isArchived.equals(false) &
              StorageNodeEntity_.nodeType.equals(NodeType.storageLocation.name),
        )
        .build();
    final count = query.count();
    query.close();
    return count;
  }

  int countChildSections(String uuid) {
    final query = box
        .query(
          StorageNodeEntity_.parentUuid.equals(uuid) &
              StorageNodeEntity_.isArchived.equals(false) &
              StorageNodeEntity_.nodeType.equals(NodeType.section.name),
        )
        .build();
    final count = query.count();
    query.close();
    return count;
  }

  int countChildContainers(String uuid) {
    final query = box
        .query(
          StorageNodeEntity_.parentUuid.equals(uuid) &
              StorageNodeEntity_.isArchived.equals(false) &
              StorageNodeEntity_.nodeType.equals(NodeType.container.name),
        )
        .build();
    final count = query.count();
    query.close();
    return count;
  }

  int countAttachedItems(String uuid) {
    final query = box
        .query(
          StorageNodeEntity_.parentUuid.equals(uuid) &
              StorageNodeEntity_.isArchived.equals(false) &
              StorageNodeEntity_.nodeType.equals(NodeType.item.name),
        )
        .build();
    final count = query.count();
    query.close();
    return count;
  }

  void deleteNode(String uuid) {
    clearCache();
    final node = getByUuid(uuid);
    if (node != null) {
      box.remove(node.id);
    }
  }

  String buildPath(StorageNodeEntity node) {
    return getStoragePath(node).displayString;
  }

  Future<List<StorageNodeEntity>> searchItems(String query) async {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      return [];
    }

    final list = box.getAll().where((node) {
      if (node.isArchived) return false;
      final name = node.name.toLowerCase();

      final description = (node.description ?? '').toLowerCase();

      final tags = (node.tags ?? '').toLowerCase();

      return name.contains(q) || description.contains(q) || tags.contains(q);
    }).toList();
    return _migrateNodes(list);
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

    return _migrateNodes(items.take(limit).toList());
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

    return _migrateNodes(items.take(limit).toList());
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
    return _migrateNodes(box.getAll().where((e) => e.isArchived).toList());
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

    return _migrateNodes(items.take(limit).toList());
  }

  List<StorageNodeEntity> getExpiringItems({int days = 30}) {
    final now = DateTime.now();

    final list = box.getAll().where((item) {
      if (item.isArchived) return false;

      if (!item.trackExpiry) return false;

      if (item.expiryDate == null) return false;

      final difference = item.expiryDate!.difference(now).inDays;

      return difference >= 0 && difference <= days;
    }).toList();
    return _migrateNodes(list);
  }

  List<StorageNodeEntity> getExpiredItems() {
    final now = DateTime.now();

    final list = box.getAll().where((item) {
      if (item.isArchived) return false;

      if (!item.trackExpiry) return false;

      if (item.expiryDate == null) return false;

      return item.expiryDate!.isBefore(now);
    }).toList();
    return _migrateNodes(list);
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
    final list = box.getAll().where((node) {
      return !node.isArchived &&
          node.roomUuid == roomUuid &&
          node.nodeType != 'item';
    }).toList();
    return _migrateNodes(list);
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
    final list = box.getAll().where((node) {
      return !node.isArchived && node.nodeType != NodeType.item.name;
    }).toList();
    return _migrateNodes(list);
  }

  List<StorageNodeEntity> getItemsWithPhotosList() {
    final items = box.getAll().where((node) {
      return node.nodeType == NodeType.item.name &&
          !node.isArchived &&
          node.photoPath != null &&
          node.photoPath!.isNotEmpty;
    }).toList();

    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return _migrateNodes(items);
  }

  List<StorageNodeEntity> getAllItems() {
    final list = box.getAll().where((node) {
      return node.nodeType == NodeType.item.name && !node.isArchived;
    }).toList();
    return _migrateNodes(list);
  }

  int save(StorageNodeEntity node) {
    clearCache();
    final photo = node.photoPath;
    if (photo != null && photo.isNotEmpty) {
      final relative = PhotoStorageService.tryMigrateToRelative(photo);
      if (relative != null && relative != photo) {
        node.photoPath = relative;
      }
    }
    return box.put(node);
  }

  void delete(int id) {
    clearCache();
    box.remove(id);
  }

  void deleteAll() {
    clearCache();
    box.removeAll();
  }
}
