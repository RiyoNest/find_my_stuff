// File: lib/shared/enums/content_sort_order.dart

enum ContentSortOrder {
  nameAsc,
  nameDesc,
  newestFirst,
  oldestFirst,
  recentlyViewed,
}

extension ContentSortOrderExtension on ContentSortOrder {
  String get label {
    return switch (this) {
      ContentSortOrder.nameAsc        => 'Name (A → Z)',
      ContentSortOrder.nameDesc       => 'Name (Z → A)',
      ContentSortOrder.newestFirst    => 'Date Created (Newest)',
      ContentSortOrder.oldestFirst    => 'Date Created (Oldest)',
      ContentSortOrder.recentlyViewed => 'Recently Viewed',
    };
  }

  String get shortLabel {
    return switch (this) {
      ContentSortOrder.nameAsc        => 'A → Z',
      ContentSortOrder.nameDesc       => 'Z → A',
      ContentSortOrder.newestFirst    => 'Newest',
      ContentSortOrder.oldestFirst    => 'Oldest',
      ContentSortOrder.recentlyViewed => 'Recent',
    };
  }
}
