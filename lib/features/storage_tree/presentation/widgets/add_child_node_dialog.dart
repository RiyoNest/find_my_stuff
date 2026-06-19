import 'package:find_my_stuff/shared/enums/node_type.dart';
import 'package:find_my_stuff/shared/models/add_child_node_result.dart';
import 'package:flutter/material.dart';


class AddChildNodeDialog extends StatefulWidget {
  const AddChildNodeDialog({super.key});

  @override
  State<AddChildNodeDialog> createState() =>
      _AddChildNodeDialogState();
}

class _AddChildNodeDialogState
    extends State<AddChildNodeDialog> {
  final _controller = TextEditingController();

  NodeType _selectedType = NodeType.section;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();

    if (name.isEmpty) {
      return;
    }

    Navigator.pop(
      context,
      AddChildNodeResult(
        nodeType: _selectedType,
        name: name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Child'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization:
              TextCapitalization.words,
              decoration:
              const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _save(),
            ),

            const SizedBox(height: 16),

            RadioListTile<NodeType>(
              title: const Text('Section'),
              value: NodeType.section,
              groupValue: _selectedType,
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),

            RadioListTile<NodeType>(
              title: const Text('Container'),
              value: NodeType.container,
              groupValue: _selectedType,
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),

            RadioListTile<NodeType>(
              title: const Text('Item'),
              value: NodeType.item,
              groupValue: _selectedType,
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
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