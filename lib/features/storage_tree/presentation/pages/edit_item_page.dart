import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditItemPage extends ConsumerStatefulWidget {
  final StorageNodeEntity node;

  const EditItemPage({
    super.key,
    required this.node,
  });

  @override
  ConsumerState<EditItemPage> createState() =>
      _EditItemPageState();
}

class _EditItemPageState
    extends ConsumerState<EditItemPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;

  late bool _isImportant;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.node.name,
    );

    _descriptionController =
        TextEditingController(
          text: widget.node.description ?? '',
        );

    _tagsController = TextEditingController(
      text: widget.node.tags ?? '',
    );

    _isImportant = widget.node.isImportant;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    final updatedNode = StorageNodeEntity(
      uuid: widget.node.uuid,
      roomUuid: widget.node.roomUuid,
      parentUuid: widget.node.parentUuid,
      nodeType: widget.node.nodeType,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      photoPath: widget.node.photoPath,
      tags: _tagsController.text.trim().isEmpty
          ? null
          : _tagsController.text.trim(),
      isImportant: _isImportant,
      isArchived: widget.node.isArchived,
      syncStatus: widget.node.syncStatus,
      createdAt: widget.node.createdAt,
      updatedAt: DateTime.now(),
      viewedAt: widget.node.viewedAt,
      sortOrder: widget.node.sortOrder,
    )..id = widget.node.id;

    final repo = ref.read(
      storageNodeRepositoryProvider,
    );

    repo.save(updatedNode);

    ref.read(
      storageRefreshProvider.notifier,
    ).state++;

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Item',
        ),
      ),
      body: SingleChildScrollView(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            TextField(
              controller:
              _nameController,
              decoration:
              const InputDecoration(
                labelText: 'Item Name',
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller:
              _descriptionController,
              maxLines: 4,
              decoration:
              const InputDecoration(
                labelText:
                'Description',
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller:
              _tagsController,
              decoration:
              const InputDecoration(
                labelText:
                'Tags (comma separated)',
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text(
                'Mark as Important',
              ),
              value: _isImportant,
              onChanged: (value) {
                setState(() {
                  _isImportant = value;
                });
              },
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text(
                  'Save',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}