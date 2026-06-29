import 'package:find_my_stuff/shared/repositories/storage_node_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';

class MoveService {
  final StorageNodeRepository _repository;

  MoveService(this._repository);

  /// Validates if a node can be moved to a destination.
  /// A node cannot be moved into itself, into its own descendants, or if the destination doesn't exist.
  bool isValidDestination(String sourceUuid, String destinationUuid) {
    if (sourceUuid == destinationUuid) return false;
    return _repository.canMoveNode(sourceUuid, destinationUuid);
  }

  /// Executes the move operation in the repository.
  /// Throws an [ArgumentError] if the destination is invalid.
  Future<void> executeMove(String sourceUuid, String destinationUuid) async {
    if (!isValidDestination(sourceUuid, destinationUuid)) {
      throw ArgumentError(
        "Can't move here — a node cannot be moved into itself or its own descendants",
      );
    }
    
    // Future: Add move history database logging / analytics here
    _repository.moveNode(sourceUuid, destinationUuid);
  }
}

final moveServiceProvider = Provider<MoveService>((ref) {
  final repository = ref.read(storageNodeRepositoryProvider);
  return MoveService(repository);
});
