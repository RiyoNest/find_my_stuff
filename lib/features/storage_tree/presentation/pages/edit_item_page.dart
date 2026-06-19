import 'dart:io';
import 'package:find_my_stuff/core/services/photo_storage_service.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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

  late String? _photoPath;

  final ImagePicker _picker = ImagePicker();

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

    _photoPath = widget.node.photoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();

    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (file == null) return;

    final savedPath =
    await PhotoStorageService.savePhoto(
      file.path,
    );

    setState(() {
      _photoPath = savedPath;
    });
  }

  Future<void> _takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (file == null) return;

    final savedPath =
    await PhotoStorageService.savePhoto(
      file.path,
    );

    setState(() {
      _photoPath = savedPath;
    });
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
      photoPath: _photoPath,
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

            const SizedBox(height: 16),

            Text(
              'Photo',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),

            const SizedBox(height: 12),

            if (_photoPath != null)
              ClipRRect(
                borderRadius:
                BorderRadius.circular(12),
                child: Image.file(
                  File(_photoPath!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(
                      Icons.photo_library,
                    ),
                    label: const Text(
                      'Gallery',
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(
                      Icons.camera_alt,
                    ),
                    label: const Text(
                      'Camera',
                    ),
                  ),
                ),
              ],
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