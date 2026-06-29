// File: lib/features/storage_tree/presentation/models/quick_add_draft.dart

class QuickAddDraft {
  final String itemName;
  final String description;
  final List<String> photos;
  final String tags;
  final bool isImportant;
  final bool expiryEnabled;
  final DateTime? expiryDate;

  // Hierarchy
  final String? roomUuid;
  final String? locationUuid;
  final String? sectionUuid;
  final String? containerUuid;

  const QuickAddDraft({
    this.itemName = '',
    this.description = '',
    this.photos = const [],
    this.tags = '',
    this.isImportant = false,
    this.expiryEnabled = false,
    this.expiryDate,
    this.roomUuid,
    this.locationUuid,
    this.sectionUuid,
    this.containerUuid,
  });

  QuickAddDraft copyWith({
    String? itemName,
    String? description,
    List<String>? photos,
    String? tags,
    bool? isImportant,
    bool? expiryEnabled,
    DateTime? expiryDate,
    String? roomUuid,
    String? locationUuid,
    String? sectionUuid,
    String? containerUuid,
    bool clearExpiryDate = false,
    bool clearRoom = false,
    bool clearLocation = false,
    bool clearSection = false,
    bool clearContainer = false,
  }) {
    return QuickAddDraft(
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      photos: photos ?? this.photos,
      tags: tags ?? this.tags,
      isImportant: isImportant ?? this.isImportant,
      expiryEnabled: expiryEnabled ?? this.expiryEnabled,
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      roomUuid: clearRoom ? null : (roomUuid ?? this.roomUuid),
      locationUuid: clearLocation ? null : (locationUuid ?? this.locationUuid),
      sectionUuid: clearSection ? null : (sectionUuid ?? this.sectionUuid),
      containerUuid: clearContainer ? null : (containerUuid ?? this.containerUuid),
    );
  }
}
