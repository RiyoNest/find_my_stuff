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

  int save(StorageNodeEntity node) {
    return box.put(node);
  }

  void delete(int id) {
    box.remove(id);
  }
}
