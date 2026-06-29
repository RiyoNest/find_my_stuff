import 'package:flutter/material.dart';
import 'package:find_my_stuff/shared/models/deletion_validation_result.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final String name;
  final String nodeType; // 'room', 'storageLocation', 'section', 'container', 'item'
  final DeletionValidationResult validation;
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({
    super.key,
    required this.name,
    required this.nodeType,
    required this.validation,
    required this.onConfirm,
  });

  String _readableNodeType() {
    switch (nodeType) {
      case 'room':
        return 'room';
      case 'storageLocation':
        return 'storage location';
      case 'section':
        return 'section';
      case 'container':
        return 'container';
      case 'item':
        return 'item';
      default:
        return 'item';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readableType = _readableNodeType();

    if (validation.canDelete) {
      return AlertDialog(
        title: Text('Delete "$name"'),
        content: Text(
          'This $readableType is empty. Are you sure you want to delete it?',
          style: context.bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirm();
            },
            child: const Text('Delete'),
          ),
        ],
      );
    } else {
      final List<String> lines = [];
      if (validation.locationCount > 0) {
        final count = validation.locationCount;
        lines.add('• $count Storage Location${count > 1 ? "s" : ""}');
      }
      if (validation.sectionCount > 0) {
        final count = validation.sectionCount;
        lines.add('• $count Section${count > 1 ? "s" : ""}');
      }
      if (validation.containerCount > 0) {
        final count = validation.containerCount;
        lines.add('• $count Container${count > 1 ? "s" : ""}');
      }
      if (validation.itemCount > 0) {
        final count = validation.itemCount;
        lines.add('• $count Item${count > 1 ? "s" : ""}');
      }

      return AlertDialog(
        title: Text('Cannot delete "$name"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reason: Contains',
              style: context.bodyStyle.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...lines.map((line) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                  child: Text(line, style: context.bodyStyle),
                )),
            const SizedBox(height: 12),
            Text(
              'Move or delete these first.',
              style: context.bodyStyle.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('OK'),
          ),
        ],
      );
    }
  }
}
