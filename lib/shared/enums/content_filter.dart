// File: lib/shared/enums/content_filter.dart

enum ContentFilter {
  all,
  itemsOnly,
  containersOnly,
  sectionsOnly,
}

extension ContentFilterExtension on ContentFilter {
  String get label {
    return switch (this) {
      ContentFilter.all            => 'All',
      ContentFilter.itemsOnly      => 'Items Only',
      ContentFilter.containersOnly => 'Containers Only',
      ContentFilter.sectionsOnly   => 'Sections Only',
    };
  }
}
