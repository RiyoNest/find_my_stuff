// File: lib/features/storage_tree/presentation/pages/quick_add_item_page.dart
//
// CHANGES in this version:
//   - "Add Item To" destination list is now a fixed-height card with its
//     own internal scroll + live search filter. Previously the radio list
//     grew unbounded (every room × location × section × container), so
//     at 10+ destinations the user had to scroll past the entire list
//     before reaching the form fields. Now the picker is always 220px,
//     the rest of the form is immediately reachable, and the user can
//     type to filter destinations instead of scrolling.
//   - Selected destination shown as a highlighted chip above the list
//     so the user can always see their choice even after scrolling away.
//   - Everything else (validation, AppSnackBar, loading state on save
//     button) is unchanged from the previous version.

import 'dart:io';

import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
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

  StorageNodeEntity? _selectedDestination;
  String? _destinationError;

  // Separate controller for the destination search field —
  // kept out of the Form so it doesn't interfere with form validation.
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _isImportant = false;
  bool _trackExpiry = false;
  DateTime? _expiryDate;
  String? _photoPath;
  bool _isSaving = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _saveItem() async {
    setState(() {
      _destinationError =
      _selectedDestination == null ? 'Please select a destination' : null;
    });

    final formValid = _formKey.currentState?.validate() ?? false;

    if (!formValid || _selectedDestination == null) {
      if (_selectedDestination == null) {
        AppSnackBar.warning(
          context,
          'Please select a destination for this item',
        );
      } else {
        AppSnackBar.warning(context, 'Please fix the highlighted fields');
      }
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
      final repo = ref.read(storageNodeRepositoryProvider);

      final item = StorageNodeEntity(
        uuid: const Uuid().v4(),
        roomUuid: _selectedDestination!.roomUuid,
        parentUuid: _selectedDestination!.uuid,
        nodeType: NodeType.item.name,
        name: ValidationHelpers.sanitize(_nameController.text),
        description: _descriptionController.text.trim(),
        tags: _tagsController.text.trim(),
        photoPath: _photoPath,
        isImportant: _isImportant,
        trackExpiry: _trackExpiry,
        expiryDate: _expiryDate,
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
            padding: const EdgeInsets.all(RAppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Couldn't load destinations: $e"),
                const SizedBox(height: RAppSpacing.sm),
                TextButton.icon(
                  onPressed: () =>
                      ref.invalidate(quickAddDestinationsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (destinations) {
          final repo = ref.read(storageNodeRepositoryProvider);

          // Sort deepest paths first (most specific destination at top).
          destinations.sort(
                (a, b) => repo
                .getPathToRoot(b)
                .length
                .compareTo(repo.getPathToRoot(a).length),
          );

          if (destinations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(RAppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_off_outlined, size: 48),
                    const SizedBox(height: RAppSpacing.sm),
                    const Text(
                      'No locations available yet',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: RAppSpacing.xs),
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

          // Apply search filter.
          final filtered = _searchQuery.isEmpty
              ? destinations
              : destinations.where((d) {
            final path = repo.buildPath(d).toLowerCase();
            return d.name.toLowerCase().contains(_searchQuery) ||
                path.contains(_searchQuery);
          }).toList();

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(RAppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Destination Picker ──────────────────────────────
                  Text(
                    'Add Item To',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: RAppSpacing.xs),
                  Text(
                    'Choose where this item will be stored',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  // Selected destination summary chip.
                  if (_selectedDestination != null) ...[
                    const SizedBox(height: RAppSpacing.sm),
                    Chip(
                      avatar: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: RAppColors.success,
                      ),
                      label: Text(
                        _selectedDestination!.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => setState(() {
                        _selectedDestination = null;
                        _destinationError = 'Please select a destination';
                      }),
                    ),
                  ],

                  if (_destinationError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: RAppSpacing.xs),
                      child: Text(
                        _destinationError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  const SizedBox(height: RAppSpacing.sm),

                  // Fixed-height searchable list card.
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(color: RAppColors.border),
                      borderRadius: BorderRadius.circular(RAppRadius.md),
                    ),
                    child: Column(
                      children: [
                        // Search field pinned at top of the card.
                        Padding(
                          padding: const EdgeInsets.all(RAppSpacing.sm),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search locations...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: RAppSpacing.sm,
                                vertical: RAppSpacing.sm,
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(RAppRadius.sm),
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        // Scrollable list of matching destinations.
                        Expanded(
                          child: filtered.isEmpty
                              ? Center(
                            child: Text(
                              'No matches for "$_searchQuery"',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                color: RAppColors.textSecondary,
                              ),
                            ),
                          )
                              : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: filtered.length,
                            itemBuilder: (_, index) {
                              final dest = filtered[index];
                              final path = repo.buildPath(dest);
                              final isSelected =
                                  _selectedDestination?.uuid == dest.uuid;

                              return InkWell(
                                onTap: () => setState(() {
                                  _selectedDestination = dest;
                                  _destinationError = null;
                                }),
                                child: Container(
                                  color: isSelected
                                      ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withOpacity(0.4)
                                      : null,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: RAppSpacing.md,
                                    vertical: RAppSpacing.sm,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons
                                            .radio_button_unchecked,
                                        size: 20,
                                        color: isSelected
                                            ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            : RAppColors.textSecondary,
                                      ),
                                      const SizedBox(
                                        width: RAppSpacing.sm,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              dest.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : null,
                                              ),
                                              maxLines: 1,
                                              overflow:
                                              TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              path,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium
                                                  ?.copyWith(
                                                color: RAppColors
                                                    .textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow:
                                              TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: RAppSpacing.lg),

                  // ── Item Details ────────────────────────────────────
                  Text(
                    'Item Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
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
                    maxLines: 3,
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

                  // ── Photo ───────────────────────────────────────────
                  Text(
                    'Photo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
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
                      style: TextButton.styleFrom(
                        foregroundColor: RAppColors.error,
                      ),
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

                  const SizedBox(height: RAppSpacing.sm),

                  // ── Options ─────────────────────────────────────────
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

                  if (_trackExpiry)
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        _expiryDate == null
                            ? 'Select Expiry Date'
                            : _expiryDate.toString().split(' ').first,
                        style: _expiryDate == null
                            ? TextStyle(color: RAppColors.textSecondary)
                            : null,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          initialDate: _expiryDate ?? DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _expiryDate = picked);
                        }
                      },
                    ),

                  const SizedBox(height: RAppSpacing.lg),

                  // ── Save ────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveItem,
                      icon: _isSaving
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                        CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save Item'),
                    ),
                  ),

                  const SizedBox(height: RAppSpacing.xl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}