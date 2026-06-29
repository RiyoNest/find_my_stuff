import 'package:find_my_stuff/shared/models/deletion_validation_result.dart';
import 'package:find_my_stuff/shared/repositories/room_repository.dart';
import 'package:find_my_stuff/shared/repositories/storage_node_repository.dart';

class DeletionValidator {
  final StorageNodeRepository _nodeRepository;
  final RoomRepository _roomRepository;

  DeletionValidator(this._nodeRepository, this._roomRepository);

  DeletionValidationResult validateRoom(String uuid) {
    final locationCount = _roomRepository.countLocations(uuid);
    final itemCount = _roomRepository.countItems(uuid);

    final canDelete = locationCount == 0 && itemCount == 0;

    return DeletionValidationResult(
      canDelete: canDelete,
      locationCount: locationCount,
      itemCount: itemCount,
      reason: canDelete ? null : 'This room contains items or storage locations.',
    );
  }

  DeletionValidationResult validateStorageLocation(String uuid) {
    final sectionCount = _nodeRepository.countChildSections(uuid);
    final containerCount = _nodeRepository.countChildContainers(uuid);
    final itemCount = _nodeRepository.countAttachedItems(uuid);

    final canDelete = sectionCount == 0 && containerCount == 0 && itemCount == 0;

    return DeletionValidationResult(
      canDelete: canDelete,
      sectionCount: sectionCount,
      containerCount: containerCount,
      itemCount: itemCount,
      reason: canDelete ? null : 'This location is not empty.',
    );
  }

  DeletionValidationResult validateSection(String uuid) {
    final containerCount = _nodeRepository.countChildContainers(uuid);
    final itemCount = _nodeRepository.countAttachedItems(uuid);

    final canDelete = containerCount == 0 && itemCount == 0;

    return DeletionValidationResult(
      canDelete: canDelete,
      containerCount: containerCount,
      itemCount: itemCount,
      reason: canDelete ? null : 'This section contains items or containers.',
    );
  }

  DeletionValidationResult validateContainer(String uuid) {
    final itemCount = _nodeRepository.countAttachedItems(uuid);

    final canDelete = itemCount == 0;

    return DeletionValidationResult(
      canDelete: canDelete,
      itemCount: itemCount,
      reason: canDelete ? null : 'This container contains items.',
    );
  }

  DeletionValidationResult validateItem(String uuid) {
    return const DeletionValidationResult(
      canDelete: true,
    );
  }
}
