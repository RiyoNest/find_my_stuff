import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:find_my_stuff/shared/models/deletion_validation_result.dart';
import 'package:find_my_stuff/shared/services/deletion_validator.dart';
import 'package:find_my_stuff/shared/providers/room_providers.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/widgets/delete_confirmation_dialog.dart';
import 'package:find_my_stuff/shared/widgets/custom_snackbar.dart';

class DeleteAction {
  static Future<void> execute({
    required BuildContext context,
    required WidgetRef ref,
    required String nodeType, // 'room', 'storageLocation', 'section', 'container', 'item'
    required String uuid,
    required String displayName,
  }) async {
    final roomRepo = ref.read(roomRepositoryProvider);
    final nodeRepo = ref.read(storageNodeRepositoryProvider);

    final validator = DeletionValidator(nodeRepo, roomRepo);
    final DeletionValidationResult validationResult;

    switch (nodeType) {
      case 'room':
        validationResult = validator.validateRoom(uuid);
        break;
      case 'storageLocation':
        validationResult = validator.validateStorageLocation(uuid);
        break;
      case 'section':
        validationResult = validator.validateSection(uuid);
        break;
      case 'container':
        validationResult = validator.validateContainer(uuid);
        break;
      case 'item':
        validationResult = validator.validateItem(uuid);
        break;
      default:
        validationResult = const DeletionValidationResult(canDelete: false, reason: 'Invalid node type.');
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => DeleteConfirmationDialog(
        name: displayName,
        nodeType: nodeType,
        validation: validationResult,
        onConfirm: () {},
      ),
    );

    if (confirmed == true && validationResult.canDelete) {
      try {
        if (nodeType == 'room') {
          roomRepo.deleteRoom(uuid);
          ref.read(roomRefreshProvider.notifier).state++;
        } else {
          nodeRepo.deleteNode(uuid);
          ref.read(storageRefreshProvider.notifier).state++;
        }

        if (context.mounted) {
          final typeLabel = _readableTypeLabel(nodeType);
          AppSnackBar.success(context, '$typeLabel deleted');
          
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackBar.error(context, 'Failed to delete: $e');
        }
      }
    }
  }

  static String _readableTypeLabel(String type) {
    switch (type) {
      case 'room':
        return 'Room';
      case 'storageLocation':
        return 'Storage Location';
      case 'section':
        return 'Section';
      case 'container':
        return 'Container';
      case 'item':
        return 'Item';
      default:
        return 'Item';
    }
  }
}
