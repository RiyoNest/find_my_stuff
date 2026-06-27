// File: lib/features/storage_tree/presentation/controllers/quick_add_wizard_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/quick_add_draft.dart';
import '../../../../shared/entities/storage_node_entity.dart';
import '../../../../shared/enums/node_type.dart';
import '../../../../shared/providers/storage_node_providers.dart';
import '../../../../core/services/photo_storage_service.dart';
import '../../../../core/utils/validation_helpers.dart';

enum QuickAddWizardStep {
  itemDetails,
  storagePath,
}

class QuickAddWizardState {
  final QuickAddWizardStep step;
  final QuickAddDraft draft;
  final bool isSaving;
  final String? errorMessage;
  final List<String> tempPhotoPaths;

  const QuickAddWizardState({
    this.step = QuickAddWizardStep.itemDetails,
    this.draft = const QuickAddDraft(),
    this.isSaving = false,
    this.errorMessage,
    this.tempPhotoPaths = const [],
  });

  QuickAddWizardState copyWith({
    QuickAddWizardStep? step,
    QuickAddDraft? draft,
    bool? isSaving,
    String? errorMessage,
    List<String>? tempPhotoPaths,
  }) {
    return QuickAddWizardState(
      step: step ?? this.step,
      draft: draft ?? this.draft,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
      tempPhotoPaths: tempPhotoPaths ?? this.tempPhotoPaths,
    );
  }
}

class QuickAddWizardController extends StateNotifier<QuickAddWizardState> {
  final Ref ref;
  bool _isSaved = false;

  QuickAddWizardController(this.ref, [QuickAddDraft? initialDraft])
      : super(QuickAddWizardState(
          draft: initialDraft ?? const QuickAddDraft(),
        ));

  void nextStep() {
    if (state.step == QuickAddWizardStep.itemDetails) {
      final draft = state.draft;
      final nameError = ValidationHelpers.validateItemName(draft.itemName);
      if (nameError != null) {
        state = state.copyWith(errorMessage: nameError);
        return;
      }
      state = state.copyWith(
        step: QuickAddWizardStep.storagePath,
        errorMessage: null,
      );
    }
  }

  void previousStep() {
    if (state.step == QuickAddWizardStep.storagePath) {
      state = state.copyWith(
        step: QuickAddWizardStep.itemDetails,
        errorMessage: null,
      );
    }
  }

  void updateDraft(QuickAddDraft updated) {
    state = state.copyWith(draft: updated);
  }

  Future<void> attachPhoto(String sourcePath) async {
    try {
      final savedPath = await PhotoStorageService.savePhoto(sourcePath);
      final newPhotos = [...state.draft.photos, savedPath];
      final newTemp = [...state.tempPhotoPaths, savedPath];
      state = state.copyWith(
        draft: state.draft.copyWith(photos: newPhotos),
        tempPhotoPaths: newTemp,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: "Failed to save photo: $e");
    }
  }

  Future<void> removePhoto(String photoPath) async {
    final newPhotos = state.draft.photos.where((p) => p != photoPath).toList();
    state = state.copyWith(
      draft: state.draft.copyWith(photos: newPhotos),
    );
  }

  void selectRoom(String? roomUuid) {
    if (roomUuid == state.draft.roomUuid) return;
    state = state.copyWith(
      draft: state.draft.copyWith(
        roomUuid: roomUuid,
        clearLocation: true,
        clearSection: true,
        clearContainer: true,
      ),
    );
  }

  void selectLocation(String? locationUuid) {
    if (locationUuid == state.draft.locationUuid) return;
    state = state.copyWith(
      draft: state.draft.copyWith(
        locationUuid: locationUuid,
        clearSection: true,
        clearContainer: true,
      ),
    );
  }

  void selectSection(String? sectionUuid) {
    if (sectionUuid == state.draft.sectionUuid) return;
    state = state.copyWith(
      draft: state.draft.copyWith(
        sectionUuid: sectionUuid,
        clearContainer: true,
      ),
    );
  }

  void selectContainer(String? containerUuid) {
    if (containerUuid == state.draft.containerUuid) return;
    state = state.copyWith(
      draft: state.draft.copyWith(
        containerUuid: containerUuid,
      ),
    );
  }

  Future<bool> saveItem() async {
    final draft = state.draft;

    final nameError = ValidationHelpers.validateItemName(draft.itemName);
    if (nameError != null) {
      state = state.copyWith(errorMessage: nameError);
      return false;
    }

    if (draft.roomUuid == null) {
      state = state.copyWith(errorMessage: 'Please select a Room');
      return false;
    }
    if (draft.locationUuid == null) {
      state = state.copyWith(errorMessage: 'Please select a Storage Location');
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final parentUuid = draft.containerUuid ?? draft.sectionUuid ?? draft.locationUuid!;
      final firstPhoto = draft.photos.isNotEmpty ? draft.photos.first : null;

      final item = StorageNodeEntity(
        uuid: const Uuid().v4(),
        roomUuid: draft.roomUuid!,
        parentUuid: parentUuid,
        nodeType: NodeType.item.name,
        name: ValidationHelpers.sanitize(draft.itemName),
        description: draft.description.trim(),
        tags: draft.tags.trim(),
        photoPath: firstPhoto,
        isImportant: draft.isImportant,
        trackExpiry: draft.expiryEnabled,
        expiryDate: draft.expiryEnabled ? draft.expiryDate : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repo = ref.read(storageNodeRepositoryProvider);
      repo.save(item);

      _isSaved = true;

      // Clean up unused photos from local filesystem
      for (final path in state.tempPhotoPaths) {
        if (!draft.photos.contains(path)) {
          await PhotoStorageService.deletePhoto(path);
        }
      }

      ref.read(storageRefreshProvider.notifier).state++;
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: "Failed to save item: $e");
      return false;
    }
  }

  @override
  void dispose() {
    if (!_isSaved) {
      for (final path in state.tempPhotoPaths) {
        PhotoStorageService.deletePhoto(path);
      }
    }
    super.dispose();
  }
}

final quickAddWizardProvider = StateNotifierProvider.autoDispose.family<
    QuickAddWizardController, QuickAddWizardState, QuickAddDraft?>((ref, initialDraft) {
  return QuickAddWizardController(ref, initialDraft);
});
