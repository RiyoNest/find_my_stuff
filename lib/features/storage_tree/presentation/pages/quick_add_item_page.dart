// File: lib/features/storage_tree/presentation/pages/quick_add_item_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:find_my_stuff/shared/widgets/permission_dialog.dart';
import 'package:find_my_stuff/shared/providers/permission_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colours.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/validation_helpers.dart';
import '../../../../shared/entities/place_entity.dart';
import '../../../../shared/entities/room_entity.dart';
import '../../../../shared/entities/storage_node_entity.dart';
import '../../../../shared/enums/node_type.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/providers/room_providers.dart';
import '../../../../shared/providers/storage_node_providers.dart';
import '../../../../shared/repositories/place_repository.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/quick_add_sheet.dart';
import '../../../../shared/widgets/safe_image_widget.dart';
import '../controllers/quick_add_wizard_controller.dart';
import '../models/quick_add_draft.dart';
import '../../../../core/services/suggestion_service.dart';

class QuickAddItemPage extends ConsumerStatefulWidget {
  final QuickAddDraft? initialDraft;
  const QuickAddItemPage({super.key, this.initialDraft});

  @override
  ConsumerState<QuickAddItemPage> createState() => _QuickAddItemPageState();
}

class _QuickAddItemPageState extends ConsumerState<QuickAddItemPage> {
  late final PageController _pageController;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;

  final _picker = ImagePicker();

  final _placeRepo = PlaceRepository();
  late final PlaceEntity _currentPlace;

  // Local navigation helper to track if sections/containers are skipped
  bool _skipSection = false;
  bool _skipContainer = false;
  bool _hasManuallyEditedPath = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Get current place (default to first seeded place)
    final places = _placeRepo.getAll();
    if (places.isNotEmpty) {
      _currentPlace = places.first;
    }

    final initialDraft = widget.initialDraft ?? const QuickAddDraft();
    _nameController = TextEditingController(text: initialDraft.itemName);
    _descriptionController = TextEditingController(text: initialDraft.description);
    _tagsController = TextEditingController(text: initialDraft.tags);

    // Sync form inputs to Riverpod controller
    _nameController.addListener(() {
      final controller = ref.read(quickAddWizardProvider(widget.initialDraft).notifier);
      final draft = ref.read(quickAddWizardProvider(widget.initialDraft)).draft;
      controller.updateDraft(draft.copyWith(itemName: _nameController.text));
    });
    _descriptionController.addListener(() {
      final controller = ref.read(quickAddWizardProvider(widget.initialDraft).notifier);
      final draft = ref.read(quickAddWizardProvider(widget.initialDraft)).draft;
      controller.updateDraft(draft.copyWith(description: _descriptionController.text));
    });
    _tagsController.addListener(() {
      final controller = ref.read(quickAddWizardProvider(widget.initialDraft).notifier);
      final draft = ref.read(quickAddWizardProvider(widget.initialDraft)).draft;
      controller.updateDraft(draft.copyWith(tags: _tagsController.text));
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    await PermissionRequestHelper.request(
      context: context,
      service: ref.read(permissionServiceProvider),
      type: AppPermissionType.gallery,
      onGranted: () async {
        final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (file == null) return;
        if (!context.mounted) return;
        final controller = ref.read(quickAddWizardProvider(widget.initialDraft).notifier);
        await controller.attachPhoto(file.path);
      },
    );
  }

  Future<void> _takePhoto() async {
    await PermissionRequestHelper.request(
      context: context,
      service: ref.read(permissionServiceProvider),
      type: AppPermissionType.camera,
      onGranted: () async {
        final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
        if (file == null) return;
        if (!context.mounted) return;
        final controller = ref.read(quickAddWizardProvider(widget.initialDraft).notifier);
        await controller.attachPhoto(file.path);
      },
    );
  }

  void _onBackPress(QuickAddWizardState state, QuickAddWizardController controller) {
    if (state.step == QuickAddWizardStep.storagePath) {
      controller.previousStep();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quickAddWizardProvider(widget.initialDraft));
    final controller = ref.read(quickAddWizardProvider(widget.initialDraft).notifier);
    final theme = Theme.of(context);

    // Listens to validation errors and triggers snackbar
    ref.listen<QuickAddWizardState>(quickAddWizardProvider(widget.initialDraft), (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        AppSnackBar.error(context, next.errorMessage!);
      }
      if (previous?.step != next.step) {
        final targetPage = next.step == QuickAddWizardStep.itemDetails ? 0 : 1;
        _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.step == QuickAddWizardStep.itemDetails ? 'Add Item' : 'Select Location',
          style: context.titleStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _onBackPress(state, controller),
        ),
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(context.spacingM),
              child: _buildStepTracker(state.step),
            ),
            const Divider(height: 1),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Details(state, controller),
                  _buildStep2Path(state, controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTracker(QuickAddWizardStep currentStep) {
    final isStep1 = currentStep == QuickAddWizardStep.itemDetails;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: primaryColor,
                child: isStep1
                    ? Text('1', style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 12, fontWeight: FontWeight.bold))
                    : Icon(Icons.check, color: theme.colorScheme.onPrimary, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'Item Details',
                style: TextStyle(
                  fontWeight: isStep1 ? FontWeight.bold : FontWeight.normal,
                  color: isStep1 ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 40,
          height: 2,
          color: isStep1 ? theme.colorScheme.outlineVariant : primaryColor,
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isStep1 ? theme.colorScheme.outlineVariant : primaryColor,
                child: Text(
                  '2',
                  style: TextStyle(
                    color: isStep1 ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Location',
                style: TextStyle(
                  fontWeight: !isStep1 ? FontWeight.bold : FontWeight.normal,
                  color: !isStep1 ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep1Details(QuickAddWizardState state, QuickAddWizardController controller) {
    final theme = Theme.of(context);
    final draft = state.draft;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(RAppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What are you adding?', style: context.titleStyle.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: RAppSpacing.xs),
            Text(
              'Enter details for your new item.',
              style: context.bodyStyle.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: RAppSpacing.lg),

            // Item Name
            TextFormField(
              controller: _nameController,
              autofocus: widget.initialDraft == null,
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

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: RAppSpacing.md),

            // Photos
            Text('Photos', style: context.titleStyle.copyWith(fontSize: 16)),
            const SizedBox(height: RAppSpacing.sm),
            if (draft.photos.isNotEmpty) ...[
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: draft.photos.length,
                  itemBuilder: (context, idx) {
                    final p = draft.photos[idx];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          SafeImageWidget(
                            photoPath: p,
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(RAppRadius.md),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.black.withValues(alpha: 0.6),
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 14, color: Colors.white),
                                padding: EdgeInsets.zero,
                                onPressed: () => controller.removePhoto(p),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
            const SizedBox(height: RAppSpacing.md),

            // Tags
            TextFormField(
              controller: _tagsController,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'comma, separated, tags',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: RAppSpacing.md),

            // Option switches
            SwitchListTile(
              value: draft.isImportant,
              title: const Text('Mark as Important'),
              secondary: const Icon(Icons.star_outline),
              onChanged: (v) => controller.updateDraft(draft.copyWith(isImportant: v)),
            ),
            SwitchListTile(
              value: draft.expiryEnabled,
              title: const Text('Track Expiry'),
              secondary: const Icon(Icons.schedule_outlined),
              onChanged: (v) => controller.updateDraft(
                draft.copyWith(expiryEnabled: v, clearExpiryDate: !v),
              ),
            ),

            if (draft.expiryEnabled) ...[
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  draft.expiryDate == null
                      ? 'Select Expiry Date'
                      : draft.expiryDate.toString().split(' ').first,
                  style: draft.expiryDate == null ? TextStyle(color: RAppColors.textSecondary) : null,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                    initialDate: draft.expiryDate ?? DateTime.now(),
                  );
                  if (picked != null) {
                    controller.updateDraft(draft.copyWith(expiryDate: picked));
                  }
                },
              ),
            ],
            const SizedBox(height: RAppSpacing.lg),

            // Next button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    controller.nextStep();
                  }
                },
                child: Text('Next: Choose Location', style: context.buttonStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Path(QuickAddWizardState state, QuickAddWizardController controller) {
    final theme = Theme.of(context);
    final draft = state.draft;

    final roomsAsync = ref.watch(roomListProvider(_currentPlace.uuid));

    // Watch child nodes at the top level to avoid nested loaders and enable autocommit skip
    final sectionsAsync = draft.locationUuid != null
        ? ref.watch(childNodesProvider(draft.locationUuid!))
        : null;
    final sections = sectionsAsync?.value?.where((c) => c.nodeType == NodeType.section.name).toList() ?? [];
    final isSectionSkipped = _skipSection || sections.isEmpty;

    final containerParentUuid = draft.sectionUuid ?? (isSectionSkipped ? draft.locationUuid : null);
    final containersAsync = containerParentUuid != null
        ? ref.watch(childNodesProvider(containerParentUuid))
        : null;
    final containers = containersAsync?.value?.where((c) => c.nodeType == NodeType.container.name).toList() ?? [];
    final isContainerSkipped = _skipContainer || containers.isEmpty;

    final suggestionService = ref.watch(suggestionServiceProvider);
    final suggestions = !_hasManuallyEditedPath && draft.itemName.trim().isNotEmpty
        ? suggestionService.getSuggestions(draft.itemName)
        : <SuggestionPath>[];
    final frequentlyUsed = suggestionService.getFrequentlyUsedLocations();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(RAppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Where is it stored?', style: context.titleStyle.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: RAppSpacing.xs),
                Text(
                  'Assign or create a place for this item.',
                  style: context.bodyStyle.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: RAppSpacing.lg),

                if (!_hasManuallyEditedPath && suggestions.isNotEmpty) ...[
                  _buildSuggestionsSection(suggestions, controller),
                  const SizedBox(height: RAppSpacing.lg),
                ],

                if (frequentlyUsed.isNotEmpty) ...[
                  _buildFrequentlyUsedSection(frequentlyUsed, controller),
                  const SizedBox(height: RAppSpacing.lg),
                ],

                // ─── ROOM SELECTION ───
                roomsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading rooms: $e'),
                  data: (rooms) => _buildSelectionSection<RoomEntity>(
                    title: 'Room',
                    subtitle: 'Choose which room this item lives in.',
                    items: rooms,
                    selectedUuid: draft.roomUuid,
                    getName: (r) => r.name,
                    getUuid: (r) => r.uuid,
                    onSelected: (uuid) {
                      controller.selectRoom(uuid);
                      setState(() {
                        _skipSection = false;
                        _skipContainer = false;
                        _hasManuallyEditedPath = true;
                      });
                    },
                    onCreateNew: () => _createRoomInline(controller),
                    helperText: 'No rooms yet. Create one to begin.',
                  ),
                ),

                // ─── STORAGE LOCATION SELECTION ───
                if (draft.roomUuid != null) ...[
                  const SizedBox(height: RAppSpacing.lg),
                  ref.watch(storageLocationsProvider(draft.roomUuid!)).when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error loading locations: $e'),
                        data: (locations) => _buildSelectionSection<StorageNodeEntity>(
                          title: 'Location',
                          subtitle: 'e.g. Wardrobe, Pantry, Desk',
                          items: locations,
                          selectedUuid: draft.locationUuid,
                          getName: (l) => l.name,
                          getUuid: (l) => l.uuid,
                          onSelected: (uuid) {
                            controller.selectLocation(uuid);
                            setState(() {
                              _skipSection = false;
                              _skipContainer = false;
                              _hasManuallyEditedPath = true;
                            });
                          },
                          onCreateNew: () => _createLocationInline(controller, draft.roomUuid!),
                          helperText: 'No locations yet. Create one to continue.',
                        ),
                      ),
                ],

                // ─── SECTION SELECTION ───
                if (draft.locationUuid != null) ...[
                  const SizedBox(height: RAppSpacing.lg),
                  if (sectionsAsync != null && sectionsAsync.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (sectionsAsync != null && sectionsAsync.hasError)
                    Text('Error loading sections: ${sectionsAsync.error}')
                  else
                    _buildSelectionSection<StorageNodeEntity>(
                      title: 'Section (Optional)',
                      subtitle: 'e.g. Top Shelf, Drawer 2',
                      items: sections,
                      selectedUuid: draft.sectionUuid,
                      getName: (s) => s.name,
                      getUuid: (s) => s.uuid,
                      isSkipped: isSectionSkipped,
                      onSkipChanged: (skip) {
                        setState(() {
                          _skipSection = skip;
                          if (skip) {
                            controller.selectSection(null);
                          }
                        });
                      },
                      skipLabel: 'No Section',
                      helperText: 'No sections yet. Create one if needed, or continue without one.',
                      onSelected: (uuid) {
                        controller.selectSection(uuid);
                        setState(() {
                          _skipSection = false;
                          _skipContainer = false;
                          _hasManuallyEditedPath = true;
                        });
                      },
                      onCreateNew: () => _createSectionInline(controller, draft.roomUuid!, draft.locationUuid!),
                    ),
                ],

                // ─── CONTAINER SELECTION ───
                if (draft.locationUuid != null && (draft.sectionUuid != null || isSectionSkipped)) ...[
                  const SizedBox(height: RAppSpacing.lg),
                  if (containersAsync != null && containersAsync.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (containersAsync != null && containersAsync.hasError)
                    Text('Error loading containers: ${containersAsync.error}')
                  else
                    _buildSelectionSection<StorageNodeEntity>(
                      title: 'Container (Optional)',
                      subtitle: 'e.g. Blue Box, Plastic Pouch',
                      items: containers,
                      selectedUuid: draft.containerUuid,
                      getName: (c) => c.name,
                      getUuid: (c) => c.uuid,
                      isSkipped: isContainerSkipped,
                      onSkipChanged: (skip) {
                        setState(() {
                          _skipContainer = skip;
                          if (skip) {
                            controller.selectContainer(null);
                          }
                        });
                      },
                      skipLabel: 'No Container',
                      helperText: 'No containers yet. Create one if needed, or continue without one.',
                      onSelected: (uuid) {
                        controller.selectContainer(uuid);
                        setState(() {
                          _skipContainer = false;
                          _hasManuallyEditedPath = true;
                        });
                      },
                      onCreateNew: () => _createContainerInline(
                        controller,
                        draft.roomUuid!,
                        draft.sectionUuid ?? draft.locationUuid!,
                      ),
                    ),
                ],
                const SizedBox(height: RAppSpacing.lg),
              ],
            ),
          ),
        ),

        // Live Path Summary Card and Save button fixed at the bottom
        Container(
          padding: const EdgeInsets.all(RAppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dynamic summary card
              _buildPathSummaryCard(draft),
              const SizedBox(height: RAppSpacing.sm),

              // Action buttons row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.previousStep,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: RAppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: state.isSaving || !_isHierarchyValid(draft) ? null : () => _onSave(controller),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: state.isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Item'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionSection<T>({
    required String title,
    required String subtitle,
    required List<T> items,
    required String? selectedUuid,
    required String Function(T) getName,
    required String Function(T) getUuid,
    required void Function(String?) onSelected,
    required VoidCallback onCreateNew,
    bool isSkipped = false,
    void Function(bool)? onSkipChanged,
    String skipLabel = 'None',
    String? helperText,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.titleStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: context.bodyStyle.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (items.isEmpty && helperText != null) ...[
          Text(
            helperText,
            style: context.bodyStyle.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...items.map((item) {
              final uuid = getUuid(item);
              final isSel = selectedUuid == uuid && !isSkipped;
              return ChoiceChip(
                label: Text(getName(item)),
                selected: isSel,
                selectedColor: theme.colorScheme.primaryContainer,
                onSelected: (selected) {
                  onSelected(selected ? uuid : null);
                },
              );
            }),
            if (onSkipChanged != null)
              ChoiceChip(
                label: Text(skipLabel),
                selected: isSkipped,
                selectedColor: theme.colorScheme.secondaryContainer,
                onSelected: (selected) {
                  onSkipChanged(selected);
                },
              ),
            ActionChip(
              avatar: Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
              label: Text(
                'Create New',
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
              ),
              onPressed: onCreateNew,
              backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFFFF5F8),
              side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPathSummaryCard(QuickAddDraft draft) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final repo = ref.read(storageNodeRepositoryProvider);
    final roomRepo = ref.read(roomRepositoryProvider);

    final roomName = draft.roomUuid != null ? roomRepo.getByUuid(draft.roomUuid!)?.name : null;
    final locationName = draft.locationUuid != null ? repo.getByUuid(draft.locationUuid!)?.name : null;
    final sectionName = draft.sectionUuid != null ? repo.getByUuid(draft.sectionUuid!)?.name : null;
    final containerName = draft.containerUuid != null ? repo.getByUuid(draft.containerUuid!)?.name : null;

    final pathParts = <String>[];
    if (roomName != null) pathParts.add(roomName);
    if (locationName != null) pathParts.add(locationName);
    if (sectionName != null) pathParts.add(sectionName);
    if (containerName != null) pathParts.add(containerName);

    final isPathEmpty = pathParts.isEmpty;
    final pathText = isPathEmpty ? 'No location selected' : pathParts.join('  ›  ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: RAppSpacing.md, vertical: RAppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4) : const Color(0xFFFFF5F8),
        borderRadius: BorderRadius.circular(RAppRadius.md),
        border: Border.all(
          color: isDark ? theme.colorScheme.outline.withValues(alpha: 0.2) : const Color(0xFFF8D7E3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPathEmpty ? Icons.info_outline : Icons.location_on,
            color: isPathEmpty ? theme.colorScheme.outline : theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pathText,
              style: context.bodyStyle.copyWith(
                fontWeight: isPathEmpty ? FontWeight.normal : FontWeight.w600,
                color: isPathEmpty ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  bool _isHierarchyValid(QuickAddDraft draft) {
    return draft.roomUuid != null && draft.locationUuid != null;
  }

  Future<void> _onSave(QuickAddWizardController controller) async {
    final success = await controller.saveItem();
    if (success && mounted) {
      AppSnackBar.success(context, 'Item saved successfully');
      Navigator.pop(context);
    }
  }

  // Inline creation implementations reusing existing services/dialogs/repositories
  Future<void> _createRoomInline(QuickAddWizardController controller) async {
    final roomName = await QuickAddSheet.show(
      context,
      title: 'Add Room',
      hintText: 'e.g. Living Room, Bedroom',
      labelText: 'Room Name',
      maxLength: ValidationHelpers.maxRoomNameLength,
      validator: ValidationHelpers.validateRoomName,
    );

    if (roomName == null || roomName.trim().isEmpty) return;

    try {
      final room = RoomEntity(
        uuid: const Uuid().v4(),
        placeUuid: _currentPlace.uuid,
        name: roomName.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(roomRepositoryProvider).save(room);
      ref.read(roomRefreshProvider.notifier).state++;
      controller.selectRoom(room.uuid);
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, "Couldn't add room. Please try again.");
      }
    }
  }

  Future<void> _createLocationInline(QuickAddWizardController controller, String roomUuid) async {
    final name = await QuickAddSheet.show(
      context,
      title: 'Add Location',
      hintText: 'e.g. Wardrobe, Pantry',
      labelText: 'Location Name',
      maxLength: ValidationHelpers.maxRoomNameLength,
      validator: ValidationHelpers.validateRoomName,
    );

    if (name == null || name.trim().isEmpty) return;

    try {
      final node = StorageNodeEntity(
        uuid: const Uuid().v4(),
        roomUuid: roomUuid,
        parentUuid: null,
        nodeType: NodeType.storageLocation.name,
        name: name.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(storageNodeRepositoryProvider).save(node);
      ref.read(storageRefreshProvider.notifier).state++;
      controller.selectLocation(node.uuid);
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, "Couldn't add location.");
      }
    }
  }

  Future<void> _createSectionInline(
    QuickAddWizardController controller,
    String roomUuid,
    String locationUuid,
  ) async {
    final name = await QuickAddSheet.show(
      context,
      title: 'Add Section',
      hintText: 'e.g. Top Shelf, Left Side',
      labelText: 'Section Name',
      maxLength: ValidationHelpers.maxRoomNameLength,
      validator: ValidationHelpers.validateRoomName,
    );

    if (name == null || name.trim().isEmpty) return;

    try {
      final node = StorageNodeEntity(
        uuid: const Uuid().v4(),
        roomUuid: roomUuid,
        parentUuid: locationUuid,
        nodeType: NodeType.section.name,
        name: name.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(storageNodeRepositoryProvider).save(node);
      ref.read(storageRefreshProvider.notifier).state++;
      controller.selectSection(node.uuid);
      setState(() {
        _skipSection = false;
      });
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, "Couldn't add section.");
      }
    }
  }

  Future<void> _createContainerInline(
    QuickAddWizardController controller,
    String roomUuid,
    String parentUuid,
  ) async {
    final name = await QuickAddSheet.show(
      context,
      title: 'Add Container',
      hintText: 'e.g. Blue Box, Plastic Pouch',
      labelText: 'Container Name',
      maxLength: ValidationHelpers.maxRoomNameLength,
      validator: ValidationHelpers.validateRoomName,
    );

    if (name == null || name.trim().isEmpty) return;

    try {
      final node = StorageNodeEntity(
        uuid: const Uuid().v4(),
        roomUuid: roomUuid,
        parentUuid: parentUuid,
        nodeType: NodeType.container.name,
        name: name.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(storageNodeRepositoryProvider).save(node);
      ref.read(storageRefreshProvider.notifier).state++;
      controller.selectContainer(node.uuid);
      setState(() {
        _skipContainer = false;
      });
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, "Couldn't add container.");
      }
    }
  }

  Widget _buildSuggestionsSection(List<SuggestionPath> suggestions, QuickAddWizardController controller) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: context.borderRadiusM,
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Intelligent Suggestions',
                  style: context.titleStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...suggestions.map((s) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: InkWell(
                  borderRadius: context.borderRadiusS,
                  onTap: () {
                    controller.updateDraft(ref.read(quickAddWizardProvider(widget.initialDraft)).draft.copyWith(
                      roomUuid: s.room.uuid,
                      locationUuid: s.location?.uuid,
                      sectionUuid: s.section?.uuid,
                      containerUuid: s.container?.uuid,
                    ));
                    setState(() {
                      _hasManuallyEditedPath = false;
                    });
                    AppSnackBar.success(context, 'Location set: ${s.displayString}');
                  },
                  child: Container(
                    padding: EdgeInsets.all(context.spacingS),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      borderRadius: context.borderRadiusS,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.displayString,
                                style: context.bodyStyle.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              if (s.reason.isNotEmpty)
                                Text(
                                  s.reason,
                                  style: context.captionStyle.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: context.borderRadiusS,
                          ),
                          child: Text(
                            s.label,
                            style: context.captionStyle.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequentlyUsedSection(List<SuggestionPath> paths, QuickAddWizardController controller) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: context.borderRadiusM,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_outline_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Frequently Used Locations',
                  style: context.titleStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...paths.map((s) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: InkWell(
                  borderRadius: context.borderRadiusS,
                  onTap: () {
                    controller.updateDraft(ref.read(quickAddWizardProvider(widget.initialDraft)).draft.copyWith(
                      roomUuid: s.room.uuid,
                      locationUuid: s.location?.uuid,
                      sectionUuid: s.section?.uuid,
                      containerUuid: s.container?.uuid,
                    ));
                    setState(() {
                      _hasManuallyEditedPath = false;
                    });
                    AppSnackBar.success(context, 'Location set: ${s.displayString}');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: context.borderRadiusS,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_right_alt_rounded, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.displayString,
                            style: context.bodyStyle.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}