// File: lib/shared/providers/content_preferences_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../enums/content_view_mode.dart';
import '../enums/content_sort_order.dart';
import '../enums/content_filter.dart';
import 'theme_provider.dart'; // import sharedPreferencesProvider

class ContentPreferences {
  final ContentViewMode viewMode;
  final ContentSortOrder sortOrder;
  final ContentFilter filter;
  
  // Hidden placeholders (architecture-ready)
  final bool showArchived;
  final bool showPhotosOnly;
  final bool showExpiring;

  ContentPreferences({
    required this.viewMode,
    required this.sortOrder,
    required this.filter,
    this.showArchived = false,
    this.showPhotosOnly = false,
    this.showExpiring = false,
  });

  ContentPreferences copyWith({
    ContentViewMode? viewMode,
    ContentSortOrder? sortOrder,
    ContentFilter? filter,
    bool? showArchived,
    bool? showPhotosOnly,
    bool? showExpiring,
  }) {
    return ContentPreferences(
      viewMode: viewMode ?? this.viewMode,
      sortOrder: sortOrder ?? this.sortOrder,
      filter: filter ?? this.filter,
      showArchived: showArchived ?? this.showArchived,
      showPhotosOnly: showPhotosOnly ?? this.showPhotosOnly,
      showExpiring: showExpiring ?? this.showExpiring,
    );
  }
}

class ContentPreferencesNotifier extends StateNotifier<ContentPreferences> {
  final SharedPreferences _prefs;

  ContentPreferencesNotifier(this._prefs)
      : super(ContentPreferences(
          viewMode: _loadViewMode(_prefs),
          sortOrder: _loadSortOrder(_prefs),
          filter: _loadFilter(_prefs),
          showArchived: _prefs.getBool('pref_show_archived') ?? false,
          showPhotosOnly: _prefs.getBool('pref_show_photos_only') ?? false,
          showExpiring: _prefs.getBool('pref_show_expiring') ?? false,
        ));

  static ContentViewMode _loadViewMode(SharedPreferences prefs) {
    final index = prefs.getInt('pref_view_mode') ?? 0;
    if (index >= 0 && index < ContentViewMode.values.length) {
      return ContentViewMode.values[index];
    }
    return ContentViewMode.list;
  }

  static ContentSortOrder _loadSortOrder(SharedPreferences prefs) {
    final index = prefs.getInt('pref_sort_order') ?? 0;
    if (index >= 0 && index < ContentSortOrder.values.length) {
      return ContentSortOrder.values[index];
    }
    return ContentSortOrder.nameAsc;
  }

  static ContentFilter _loadFilter(SharedPreferences prefs) {
    final index = prefs.getInt('pref_filter') ?? 0;
    if (index >= 0 && index < ContentFilter.values.length) {
      return ContentFilter.values[index];
    }
    return ContentFilter.all;
  }

  void setViewMode(ContentViewMode mode) {
    state = state.copyWith(viewMode: mode);
    _prefs.setInt('pref_view_mode', mode.index);
  }

  void setSortOrder(ContentSortOrder order) {
    state = state.copyWith(sortOrder: order);
    _prefs.setInt('pref_sort_order', order.index);
  }

  void setFilter(ContentFilter filter) {
    state = state.copyWith(filter: filter);
    _prefs.setInt('pref_filter', filter.index);
  }

  void setShowArchived(bool show) {
    state = state.copyWith(showArchived: show);
    _prefs.setBool('pref_show_archived', show);
  }

  void setShowPhotosOnly(bool show) {
    state = state.copyWith(showPhotosOnly: show);
    _prefs.setBool('pref_show_photos_only', show);
  }

  void setShowExpiring(bool show) {
    state = state.copyWith(showExpiring: show);
    _prefs.setBool('pref_show_expiring', show);
  }
}

final contentPreferencesProvider =
    StateNotifierProvider<ContentPreferencesNotifier, ContentPreferences>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ContentPreferencesNotifier(prefs);
});
