import 'package:uuid/uuid.dart';

import '../../shared/entities/place_entity.dart';
import '../../shared/repositories/place_repository.dart';

class DatabaseSeed {
  static Future<void> seed() async {
    final repo = PlaceRepository();

    if (repo.getAll().isNotEmpty) {
      return;
    }

    repo.save(
      PlaceEntity(
        uuid: const Uuid().v4(),
        name: 'My Home',
        type: 'home',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}