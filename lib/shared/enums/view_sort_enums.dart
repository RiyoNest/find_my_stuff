// File: lib/shared/enums/view_sort_enums.dart
//
// Enums for content view mode and sort order.
// Used by ContentToolbar and ViewOptionsSheet across all list pages.

enum ContentViewMode { list, grid, tree }

enum ContentSortOrder {
  nameAsc,
  nameDesc,
  createdNewest,
  createdOldest,
  modifiedRecent,
}

extension ContentSortOrderLabel on ContentSortOrder {
  String get label {
    return switch (this) {
      ContentSortOrder.nameAsc       => 'Name (A → Z)',
      ContentSortOrder.nameDesc      => 'Name (Z → A)',
      ContentSortOrder.createdNewest => 'Date Created (Newest)',
      ContentSortOrder.createdOldest => 'Date Created (Oldest)',
      ContentSortOrder.modifiedRecent => 'Recently Modified',
    };
  }

  String get shortLabel {
    return switch (this) {
      ContentSortOrder.nameAsc        => 'A → Z',
      ContentSortOrder.nameDesc       => 'Z → A',
      ContentSortOrder.createdNewest  => 'Newest',
      ContentSortOrder.createdOldest  => 'Oldest',
      ContentSortOrder.modifiedRecent => 'Modified',
    };
  }
}