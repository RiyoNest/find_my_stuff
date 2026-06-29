class DeletionValidationResult {
  final bool canDelete;
  final int locationCount;
  final int sectionCount;
  final int containerCount;
  final int itemCount;
  final String? reason;

  const DeletionValidationResult({
    required this.canDelete,
    this.locationCount = 0,
    this.sectionCount = 0,
    this.containerCount = 0,
    this.itemCount = 0,
    this.reason,
  });

  bool get hasChildren => locationCount > 0 || sectionCount > 0 || containerCount > 0;
  bool get hasItems => itemCount > 0;
  int get totalDependencies => locationCount + sectionCount + containerCount + itemCount;

  DeletionValidationResult copyWith({
    bool? canDelete,
    int? locationCount,
    int? sectionCount,
    int? containerCount,
    int? itemCount,
    String? reason,
  }) {
    return DeletionValidationResult(
      canDelete: canDelete ?? this.canDelete,
      locationCount: locationCount ?? this.locationCount,
      sectionCount: sectionCount ?? this.sectionCount,
      containerCount: containerCount ?? this.containerCount,
      itemCount: itemCount ?? this.itemCount,
      reason: reason ?? this.reason,
    );
  }
}
