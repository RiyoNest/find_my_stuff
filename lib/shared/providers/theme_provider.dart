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

/// Reactive provider that handles loading and persisting the selected ThemeMode.
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  
  // Auto-save any future changes to SharedPreferences
  ref.listenSelf((previous, next) {
    if (next != previous) {
      prefs.setInt('theme_mode', next.index);
    }
  });

  // Load the initial value from SharedPreferences
  final savedIndex = prefs.getInt('theme_mode');
  if (savedIndex != null && savedIndex >= 0 && savedIndex < ThemeMode.values.length) {
    return ThemeMode.values[savedIndex];
  }
  
  return ThemeMode.system;
});