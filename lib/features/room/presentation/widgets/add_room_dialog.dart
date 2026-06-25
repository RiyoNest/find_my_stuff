// File: lib/features/room/presentation/widgets/add_room_dialog.dart
//
// CHANGE from your version: added real validation (via ValidationHelpers)
// instead of just checking for empty string, with inline error text and
// a live character counter. Save button is disabled while the field is
// invalid instead of silently no-op'ing on submit.

import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/utils/validation_helpers.dart';
import 'package:flutter/material.dart';

class AddRoomDialog extends StatefulWidget {
  const AddRoomDialog({super.key});

  @override
  State<AddRoomDialog> createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends State<AddRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      _errorText = ValidationHelpers.validateRoomName(value);
    });
  }

  void _save() {
    final error = ValidationHelpers.validateRoomName(_controller.text);

    setState(() => _errorText = error);

    if (error != null) return;

    Navigator.pop(context, ValidationHelpers.sanitize(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final isValid = ValidationHelpers.validateRoomName(_controller.text) == null;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RAppRadius.lg),
      ),
      title: const Text('Add Room'),
      content: Form(
        key: _formKey,
        child: TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: ValidationHelpers.maxRoomNameLength,
          decoration: InputDecoration(
            hintText: 'Bedroom',
            border: const OutlineInputBorder(),
            errorText: _errorText,
          ),
          onChanged: _onChanged,
          onSubmitted: (_) => _save(),
        ),
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
