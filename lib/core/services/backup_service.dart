import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../shared/entities/place_entity.dart';
import '../../shared/entities/room_entity.dart';
import '../../shared/entities/storage_node_entity.dart';
import '../../shared/repositories/place_repository.dart';
import '../../shared/repositories/room_repository.dart';
import '../../shared/repositories/storage_node_repository.dart';
import 'photo_storage_service.dart';

class BackupService {
  static Future<void> exportBackup() async {
    final placeRepo = PlaceRepository();
    final roomRepo = RoomRepository();
    final nodeRepo = StorageNodeRepository();

    final places = placeRepo.getAll();

    final rooms = roomRepo.box.getAll();

    final nodes = nodeRepo.box.getAll();

    final backup = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'places': places.map(_placeToJson).toList(),
      'rooms': rooms.map(_roomToJson).toList(),
      'nodes': nodes.map(_nodeToJson).toList(),
    };

    final directory = await getApplicationDocumentsDirectory();

    final file = File(
      '${directory.path}/find_my_stuff_backup.json',
    );

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(backup),
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Find My Stuff Backup',
    );
  }

  static Map<String, dynamic> _placeToJson(
      PlaceEntity place,
      ) {
    return {
      'uuid': place.uuid,
      'name': place.name,
      'type': place.type,
      'createdAt': place.createdAt.toIso8601String(),
      'updatedAt': place.updatedAt.toIso8601String(),
    };
  }

  static Map<String, dynamic> _roomToJson(
      RoomEntity room,
      ) {
    return {
      'uuid': room.uuid,
      'placeUuid': room.placeUuid,
      'name': room.name,
      'createdAt': room.createdAt.toIso8601String(),
      'updatedAt': room.updatedAt.toIso8601String(),
    };
  }

  static Map<String, dynamic> _nodeToJson(
      StorageNodeEntity node,
      ) {
    return {
      'uuid': node.uuid,
      'roomUuid': node.roomUuid,
      'parentUuid': node.parentUuid,
      'nodeType': node.nodeType,
      'name': node.name,
      'description': node.description,
      'photoPath': PhotoStorageService.tryMigrateToRelative(node.photoPath),
      'tags': node.tags,
      'isImportant': node.isImportant,
      'isArchived': node.isArchived,
      'trackExpiry': node.trackExpiry,
      'expiryDate': node.expiryDate?.toIso8601String(),
      'createdAt': node.createdAt.toIso8601String(),
      'updatedAt': node.updatedAt.toIso8601String(),
      'viewedAt': node.viewedAt?.toIso8601String(),
      'sortOrder': node.sortOrder,
      'syncStatus': node.syncStatus,
    };
  }

  static Future<void> importBackup() async {
    final result =  await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) {
      return;
    }

    final path = result.files.single.path;

    if (path == null) {
      return;
    }

    final file = File(path);

    final jsonString = await file.readAsString();

    final backup = jsonDecode(jsonString);

    if (backup['version'] != 1) {
      throw Exception('Unsupported backup version');
    }

    final placeRepo = PlaceRepository();
    final roomRepo = RoomRepository();
    final nodeRepo = StorageNodeRepository();

    nodeRepo.deleteAll();
    roomRepo.deleteAll();
    placeRepo.deleteAll();

    for (final placeJson in backup['places']) {
      placeRepo.save(
        PlaceEntity(
          uuid: placeJson['uuid'],
          name: placeJson['name'],
          type: placeJson['type'],
          createdAt: DateTime.parse(placeJson['createdAt']),
          updatedAt: DateTime.parse(placeJson['updatedAt']),
        ),
      );
    }

    for (final roomJson in backup['rooms']) {
      roomRepo.save(
        RoomEntity(
          uuid: roomJson['uuid'],
          placeUuid: roomJson['placeUuid'],
          name: roomJson['name'],
          createdAt: DateTime.parse(roomJson['createdAt']),
          updatedAt: DateTime.parse(roomJson['updatedAt']),
        ),
      );
    }

    for (final nodeJson in backup['nodes']) {
      nodeRepo.save(
        StorageNodeEntity(
          uuid: nodeJson['uuid'],
          roomUuid: nodeJson['roomUuid'],
          parentUuid: nodeJson['parentUuid'],
          nodeType: nodeJson['nodeType'],
          name: nodeJson['name'],
          description: nodeJson['description'],
          photoPath: PhotoStorageService.tryMigrateToRelative(nodeJson['photoPath']),
          tags: nodeJson['tags'],
          isImportant: nodeJson['isImportant'] ?? false,
          isArchived: nodeJson['isArchived'] ?? false,
          trackExpiry: nodeJson['trackExpiry'] ?? false,
          expiryDate: nodeJson['expiryDate'] == null
              ? null
              : DateTime.parse(nodeJson['expiryDate']),
          createdAt: DateTime.parse(nodeJson['createdAt']),
          updatedAt: DateTime.parse(nodeJson['updatedAt']),
          viewedAt: nodeJson['viewedAt'] == null
              ? null
              : DateTime.parse(nodeJson['viewedAt']),
          sortOrder: nodeJson['sortOrder'] ?? 0,
          syncStatus: nodeJson['syncStatus'] ?? 0,
        ),
      );
    }


  }
}