// File: lib/shared/providers/theme_provider.dart
//
// App-wide theme mode state. main.dart watches this to set
// MaterialApp.router's themeMode; AppDrawer reads/writes it.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);