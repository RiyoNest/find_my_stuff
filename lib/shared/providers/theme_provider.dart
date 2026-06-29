// File: lib/shared/providers/theme_provider.dart
//
// App-wide theme mode state. main.dart watches this to set
// MaterialApp.router's themeMode; AppDrawer reads/writes it.
// Theme selection persists automatically using SharedPreferences.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for SharedPreferences instance. Must be overridden in main.dart on startup.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden inside the ProviderScope');
});

/// Notifier that handles loading and persisting the selected ThemeMode.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Only read SharedPreferences (no watch/subscription required)
    final prefs = ref.read(sharedPreferencesProvider);
    final savedIndex = prefs.getInt('theme_mode');
    if (savedIndex != null && savedIndex >= 0 && savedIndex < ThemeMode.values.length) {
      return ThemeMode.values[savedIndex];
    }
    return ThemeMode.system;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setInt('theme_mode', mode.index);
  }
}

/// Reactive provider that handles loading and persisting the selected ThemeMode.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);