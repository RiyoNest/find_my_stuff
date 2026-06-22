// File: lib/features/storage_tree/presentation/pages/edit_item_page.dart
//
// CHANGES:
//   - Wrapped fields in a Form with TextFormField + ValidationHelpers
//     validators. Previously empty name saved silently.
//   - Added loading state on the Save button.
//   - AppSnackBar replaces raw ScaffoldMessenger.
//   - Added "Remove photo" button.
//   - Uses RAppSpacing/RAppRadius/RAppColors tokens throughout.
//   - Expiry date tile now shows a styled card instead of a plain button.

import 'dart:io';

import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:find_my_stuff/core/services/photo_storage_service.dart';
import 'package:find_my_stuff/core/utils/validation_helpers.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class EditItemPage extends ConsumerStatefulWidget {
  final StorageNodeEntity node;

  const EditItemPage({super.key, required this.node});

  @override
  ConsumerState<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends ConsumerState<EditItemPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;

  late bool _isImportant;
  late bool _trackExpiry;
  DateTime? _expiryDate;
  String? _photoPath;
  bool _isSaving = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.node.name);
    _descriptionController = TextEditingController(
      text: widget.node.description ?? '',
    );
    _tagsController = TextEditingController(text: widget.node.tags ?? '');
    _isImportant = widget.node.isImportant;
    _trackExpiry = widget.node.trackExpiry;
    _expiryDate = widget.node.expiryDate;
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
    final saved = await PhotoStorageService.savePhoto(file.path);
    setState(() => _photoPath = saved);
  }

  Future<void> _takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (file == null) return;
    final saved = await PhotoStorageService.savePhoto(file.path);
    setState(() => _photoPath = saved);
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _save() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) {
      AppSnackBar.warning(context, 'Please fix the highlighted fields');
      return;
    }

    if (_trackExpiry && _expiryDate == null) {
      AppSnackBar.warning(
        context,
        'Please select an expiry date, or turn off Track Expiry',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedNode = StorageNodeEntity(
        uuid: widget.node.uuid,
        roomUuid: widget.node.roomUuid,
        parentUuid: widget.node.parentUuid,
        nodeType: widget.node.nodeType,
        name: ValidationHelpers.sanitize(_nameController.text),
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
        expiryDate: _trackExpiry ? _expiryDate : null,
        trackExpiry: _trackExpiry,
      )..id = widget.node.id;

      ref.read(storageNodeRepositoryProvider).save(updatedNode);
      ref.read(storageRefreshProvider.notifier).state++;

      if (mounted) {
        AppSnackBar.success(context, '"${updatedNode.name}" updated');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, "Couldn't save changes. Please try again.");
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Item')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(RAppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Item Details ──────────────────────────────────────
              Text('Details', style: theme.textTheme.titleLarge),
              const SizedBox(height: RAppSpacing.md),

              TextFormField(
                controller: _nameController,
                maxLength: ValidationHelpers.maxItemNameLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  border: OutlineInputBorder(),
                ),
                validator: ValidationHelpers.validateItemName,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),

              const SizedBox(height: RAppSpacing.md),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: ValidationHelpers.validateDescription,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),

              const SizedBox(height: RAppSpacing.md),

              TextFormField(
                controller: _tagsController,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'comma, separated, tags',
                  border: OutlineInputBorder(),
                ),
                validator: ValidationHelpers.validateTags,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),

              const SizedBox(height: RAppSpacing.md),

              // ── Options ───────────────────────────────────────────
              Text('Options', style: theme.textTheme.titleLarge),

              SwitchListTile(
                value: _isImportant,
                title: const Text('Mark as Important'),
                secondary: const Icon(Icons.star_outline),
                onChanged: (v) => setState(() => _isImportant = v),
              ),

              SwitchListTile(
                value: _trackExpiry,
                title: const Text('Track Expiry'),
                secondary: const Icon(Icons.schedule_outlined),
                onChanged: (v) => setState(() {
                  _trackExpiry = v;
                  if (!v) _expiryDate = null;
                }),
              ),

              if (_trackExpiry) ...[
                const SizedBox(height: RAppSpacing.sm),
                InkWell(
                  onTap: _selectExpiryDate,
                  borderRadius: BorderRadius.circular(RAppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: RAppSpacing.md,
                      vertical: RAppSpacing.sm + 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: RAppColors.border),
                      borderRadius: BorderRadius.circular(RAppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: RAppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expiry Date',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: RAppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _expiryDate == null
                                    ? 'Tap to select a date'
                                    : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _expiryDate == null
                                      ? RAppColors.textSecondary
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: RAppSpacing.sm),
              ],

              const SizedBox(height: RAppSpacing.md),

              // ── Photo ─────────────────────────────────────────────
              Text('Photo', style: theme.textTheme.titleLarge),
              const SizedBox(height: RAppSpacing.sm),

              if (_photoPath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(RAppRadius.md),
                  child: Image.file(
                    File(_photoPath!),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: RAppSpacing.sm),
                TextButton.icon(
                  onPressed: () => setState(() => _photoPath = null),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remove photo'),
                  style:
                  TextButton.styleFrom(foregroundColor: RAppColors.error),
                ),
                const SizedBox(height: RAppSpacing.sm),
              ],

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ),
                  const SizedBox(width: RAppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: RAppSpacing.lg),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                ),
              ),

              const SizedBox(height: RAppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}