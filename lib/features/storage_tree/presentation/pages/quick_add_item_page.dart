// File: lib/features/storage_tree/presentation/pages/quick_add_item_page.dart
//
// CHANGES from your version:
//   - Wrapped fields in a Form with TextFormField + ValidationHelpers
//     validators (was: only an empty-string check on submit, and only
//     for name/destination).
//   - Replaced raw ScaffoldMessenger SnackBars with AppSnackBar
//     (success/error/warning) for consistent styling app-wide.
//   - Added character counters via maxLength on name/description/tags.
//   - Save button now runs full form validation, not just two ad-hoc checks.

import 'dart:io';

import 'package:find_my_stuff/core/services/photo_storage_service.dart';
import 'package:find_my_stuff/core/utils/validation_helpers.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/enums/node_type.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class QuickAddItemPage extends ConsumerStatefulWidget {
  const QuickAddItemPage({super.key});

  @override
  ConsumerState<QuickAddItemPage> createState() => _QuickAddItemPageState();
}

class _QuickAddItemPageState extends ConsumerState<QuickAddItemPage> {
  final _formKey = GlobalKey<FormState>();

  StorageNodeEntity? selectedDestination;
  String? _destinationError;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final tagsController = TextEditingController();

  bool isImportant = false;
  bool trackExpiry = false;
  DateTime? expiryDate;
  String? photoPath;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (file == null) return;

    final savedPath = await PhotoStorageService.savePhoto(file.path);

    setState(() => photoPath = savedPath);
  }

  Future<void> _takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (file == null) return;

    final savedPath = await PhotoStorageService.savePhoto(file.path);

    setState(() => photoPath = savedPath);
  }

  Future<void> _saveItem() async {
    setState(() {
      _destinationError =
      selectedDestination == null ? 'Please select a destination' : null;
    });

    final formValid = _formKey.currentState?.validate() ?? false;

    if (!formValid || selectedDestination == null) {
      if (selectedDestination == null) {
        AppSnackBar.warning(context, 'Please select a destination for this item');
      } else {
        AppSnackBar.warning(context, 'Please fix the highlighted fields');
      }
      return;
    }

    if (trackExpiry && expiryDate == null) {
      AppSnackBar.warning(context, 'Please select an expiry date, or turn off Track Expiry');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(storageNodeRepositoryProvider);

      final item = StorageNodeEntity(
        uuid: const Uuid().v4(),
        roomUuid: selectedDestination!.roomUuid,
        parentUuid: selectedDestination!.uuid,
        nodeType: NodeType.item.name,
        name: ValidationHelpers.sanitize(nameController.text),
        description: descriptionController.text.trim(),
        tags: tagsController.text.trim(),
        photoPath: photoPath,
        isImportant: isImportant,
        trackExpiry: trackExpiry,
        expiryDate: expiryDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      repo.save(item);

      ref.read(storageRefreshProvider.notifier).state++;

      if (mounted) {
        AppSnackBar.success(context, '"${item.name}" added successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, "Couldn't save item. Please try again.");
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinationsAsync = ref.watch(quickAddDestinationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quick Add Item')),
      body: destinationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Couldn't load destinations: $e"),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => ref.invalidate(quickAddDestinationsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (destinations) {
          final repo = ref.read(storageNodeRepositoryProvider);

          destinations.sort(
                (a, b) => repo
                .getPathToRoot(b)
                .length
                .compareTo(repo.getPathToRoot(a).length),
          );

          if (destinations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_off_outlined, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'No locations available yet',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Create a Room and a Location first, then come back here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Item To',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_destinationError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _destinationError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  ...destinations.map((destination) {
                    final path = repo.buildPath(destination);

                    return RadioListTile<StorageNodeEntity>(
                      value: destination,
                      groupValue: selectedDestination,
                      title: Text(destination.name),
                      subtitle: Text(path),
                      onChanged: (value) {
                        setState(() {
                          selectedDestination = value;
                          _destinationError = null;
                        });
                      },
                    );
                  }),

                  const Divider(height: 32),

                  TextFormField(
                    controller: nameController,
                    maxLength: ValidationHelpers.maxItemNameLength,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Item Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: ValidationHelpers.validateItemName,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    validator: ValidationHelpers.validateDescription,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: tagsController,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Tags',
                      hintText: 'comma, separated, tags',
                      border: OutlineInputBorder(),
                    ),
                    validator: ValidationHelpers.validateTags,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),

                  const SizedBox(height: 16),

                  Text('Photo', style: Theme.of(context).textTheme.titleMedium),

                  const SizedBox(height: 12),

                  if (photoPath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(photoPath!),
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
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _takePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  SwitchListTile(
                    value: isImportant,
                    title: const Text('Important Item'),
                    onChanged: (value) => setState(() => isImportant = value),
                  ),

                  SwitchListTile(
                    value: trackExpiry,
                    title: const Text('Track Expiry'),
                    onChanged: (value) {
                      setState(() {
                        trackExpiry = value;
                        if (!value) expiryDate = null;
                      });
                    },
                  ),

                  if (trackExpiry)
                    ListTile(
                      title: Text(
                        expiryDate == null
                            ? 'Select Expiry Date'
                            : expiryDate.toString().split(' ').first,
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          initialDate: DateTime.now(),
                        );

                        if (picked != null) {
                          setState(() => expiryDate = picked);
                        }
                      },
                    ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveItem,
                      icon: _isSaving
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save Item'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}