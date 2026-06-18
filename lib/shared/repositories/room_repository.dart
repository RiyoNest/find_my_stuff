import 'package:find_my_stuff/core/database/objectbox_service.dart';
import 'package:find_my_stuff/objectbox.g.dart';
import 'package:find_my_stuff/shared/entities/room_entity.dart';

class RoomRepository {
  final box = ObjectBoxService.store.box<RoomEntity>();

  List<RoomEntity> getRoomsByPlace(String placeUuid) {
    final query = box.query(
      RoomEntity_.placeUuid.equals(placeUuid),
    ).build();

    final rooms = query.find();

    query.close();

    return rooms;
  }

  RoomEntity? getByUuid(String uuid) {
    final query = box.query(
      RoomEntity_.uuid.equals(uuid),
    ).build();

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
}