import 'package:find_my_stuff/shared/entities/place_entity.dart';

import '../../core/database/objectbox_service.dart';
import '../../objectbox.g.dart';

class PlaceRepository {
  final box = ObjectBoxService.store.box<PlaceEntity>();

  List<PlaceEntity> getAll() {
    return box.getAll();
  }

  PlaceEntity? getByUuid(String uuid) {
    final query = box.query(
      PlaceEntity_.uuid.equals(uuid),
    ).build();

    final result = query.findFirst();
    query.close();

    return result;
  }

  int save(PlaceEntity place) {
    return box.put(place);
  }

  void delete(int id) {
    box.remove(id);
  }
}