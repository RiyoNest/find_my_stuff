import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/room_entity.dart';
import '../repositories/room_repository.dart';

final roomRepositoryProvider =
Provider<RoomRepository>(
      (ref) => RoomRepository(),
);

final roomRefreshProvider =
StateProvider<int>((ref) => 0);

final roomListProvider =
FutureProvider.family<List<RoomEntity>, String>(
      (ref, placeUuid) async {
    ref.watch(roomRefreshProvider);

    final repo =
    ref.read(roomRepositoryProvider);

    return repo.getRoomsByPlace(placeUuid);
  },
);

final roomDetailsProvider =
FutureProvider.family<RoomEntity?, String>(
      (ref, roomUuid) async {
    final repo =
    ref.read(roomRepositoryProvider);

    return repo.getByUuid(roomUuid);
  },
);