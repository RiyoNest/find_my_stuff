import 'package:find_my_stuff/core/database/objectbox_service.dart';
import 'package:find_my_stuff/objectbox.g.dart';
import 'package:find_my_stuff/shared/entities/room_entity.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/enums/node_type.dart';

class RoomRepository {
  final box = ObjectBoxService.store.box<RoomEntity>();

  List<RoomEntity> getRoomsByPlace(String placeUuid) {
    final query = box.query(RoomEntity_.placeUuid.equals(placeUuid)).build();

    final rooms = query.find();

    query.close();

    return rooms;
  }

  RoomEntity? getByUuid(String uuid) {
    final query = box.query(RoomEntity_.uuid.equals(uuid)).build();

    final room = query.findFirst();

    query.close();

    return room;
  }

  int save(RoomEntity room) {
    return box.put(room);
  }

  void delete(int id) {
    box.remove(id);
  }

  void deleteAll() {
    box.removeAll();
  }

  int countLocations(String roomUuid) {
    final nodeBox = ObjectBoxService.store.box<StorageNodeEntity>();
    final query = nodeBox
        .query(
          StorageNodeEntity_.roomUuid.equals(roomUuid) &
              StorageNodeEntity_.nodeType.equals(NodeType.storageLocation.name) &
              StorageNodeEntity_.isArchived.equals(false),
        )
        .build();
    final count = query.count();
    query.close();
    return count;
  }

  int countItems(String roomUuid) {
    final nodeBox = ObjectBoxService.store.box<StorageNodeEntity>();
    final query = nodeBox
        .query(
          StorageNodeEntity_.roomUuid.equals(roomUuid) &
              StorageNodeEntity_.nodeType.equals(NodeType.item.name) &
              StorageNodeEntity_.isArchived.equals(false),
        )
        .build();
    final count = query.count();
    query.close();
    return count;
  }

  void deleteRoom(String uuid) {
    final room = getByUuid(uuid);
    if (room != null) {
      box.remove(room.id);
    }
  }
}
