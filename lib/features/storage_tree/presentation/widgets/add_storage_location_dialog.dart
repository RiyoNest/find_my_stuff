import 'package:flutter/material.dart';

class AddStorageLocationDialog extends StatefulWidget {
  const AddStorageLocationDialog({super.key});

  @override
  State<AddStorageLocationDialog> createState() =>
      _AddStorageLocationDialogState();
}

class _AddStorageLocationDialogState
    extends State<AddStorageLocationDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final storageLocationName = _controller.text.trim();

    if (storageLocationName.isEmpty) {
      return;
    }

    Navigator.pop(
      context,
      storageLocationName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Storage Location'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Wardrobe',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}