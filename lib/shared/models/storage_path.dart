enum StoragePathSegmentType {
  room,
  storageLocation,
  section,
  container,
}

class StoragePathSegment {
  final String uuid;
  final String name;
  final StoragePathSegmentType type;

  const StoragePathSegment({
    required this.uuid,
    required this.name,
    required this.type,
  });
}

class StoragePath {
  final List<StoragePathSegment> segments;

  const StoragePath(this.segments);

  StoragePathSegment? _findSegment(StoragePathSegmentType type) {
    for (final s in segments) {
      if (s.type == type) return s;
    }
    return null;
  }

  StoragePathSegment? get room => _findSegment(StoragePathSegmentType.room);
  StoragePathSegment? get storageLocation => _findSegment(StoragePathSegmentType.storageLocation);
  StoragePathSegment? get section => _findSegment(StoragePathSegmentType.section);
  StoragePathSegment? get container => _findSegment(StoragePathSegmentType.container);

  bool get isEmpty => segments.isEmpty;
  bool get isNotEmpty => segments.isNotEmpty;

  String get displayString => join(' › ');

  String join(String separator) {
    return segments.map((s) => s.name).join(separator);
  }
}
