// File: lib/features/storage_tree/presentation/widgets/add_storage_location_dialog.dart
//
// CHANGES: Real validation via ValidationHelpers, live character counter,
// Save button disabled until valid — matches the AddRoomDialog pattern.

import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/utils/validation_helpers.dart';
import 'package:flutter/material.dart';

class AddStorageLocationDialog extends StatefulWidget {
  const AddStorageLocationDialog({super.key});

  @override
  State<AddStorageLocationDialog> createState() =>
      _AddStorageLocationDialogState();
}

class _AddStorageLocationDialogState extends State<AddStorageLocationDialog> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _errorText = ValidationHelpers.validateRoomName(value));
  }

  void _save() {
    final error = ValidationHelpers.validateRoomName(_controller.text);
    setState(() => _errorText = error);
    if (error != null) return;
    Navigator.pop(context, ValidationHelpers.sanitize(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final isValid =
        ValidationHelpers.validateRoomName(_controller.text) == null;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RAppRadius.lg),
      ),
      title: const Text('Add Storage Location'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: ValidationHelpers.maxRoomNameLength,
        decoration: InputDecoration(
          hintText: 'Wardrobe',
          border: const OutlineInputBorder(),
          errorText: _errorText,
        ),
        onChanged: _onChanged,
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: isValid ? _save : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}