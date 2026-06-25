// File: lib/core/constants/app_theme.dart
//
// CHANGE from your version: RAppTextStyles was defined but never attached
// to ThemeData — every Theme.of(context).textTheme.titleLarge call across
// the app (including in the Home page redesign) was silently falling back
// to Flutter's default Material type scale instead of your brand styles.
// Added a `_textTheme()` helper that maps RAppTextStyles onto TextTheme
// with proper colorScheme-aware colors, and wired it into both themes.
//
// Adjust the import path below if RAppTextStyles lives in a differently
// named file than app_text_styles.dart.

import 'package:flutter/material.dart';

import 'app_colours.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

class RAppTheme {
  RAppTheme._();

  static TextTheme _textTheme(ColorScheme colorScheme) {
    return TextTheme(
      titleLarge: RAppTextStyles.titleLarge.copyWith(
        color: colorScheme.onSurface,
      ),
      titleMedium: RAppTextStyles.titleMedium.copyWith(
        color: colorScheme.onSurface,
      ),
      titleSmall: RAppTextStyles.titleSmall.copyWith(
        color: colorScheme.onSurface,
      ),
      bodyLarge: RAppTextStyles.bodyLarge.copyWith(
        color: colorScheme.onSurface,
      ),
      bodyMedium: RAppTextStyles.bodyMedium.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      labelMedium: RAppTextStyles.labelMedium.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: RAppColors.primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme(colorScheme),

      scaffoldBackgroundColor: RAppColors.lightBackground,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: RAppColors.lightBackground,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: RAppTextStyles.titleMedium.copyWith(
          color: colorScheme.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: RAppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RAppRadius.lg),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: RAppColors.primary,
        foregroundColor: Colors.white,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RAppRadius.md),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RAppRadius.md),
          borderSide: const BorderSide(color: RAppColors.border),
        ),
      ),

      searchBarTheme: SearchBarThemeData(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RAppRadius.xl),
          ),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      dividerTheme: const DividerThemeData(thickness: 1),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RAppRadius.md),
            ),
          ),
        ),
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor: RAppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(RAppRadius.lg),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: RAppColors.primary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme(colorScheme),

      scaffoldBackgroundColor: RAppColors.darkBackground,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: RAppColors.darkBackground,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: RAppTextStyles.titleMedium.copyWith(
          color: colorScheme.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: RAppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RAppRadius.lg),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: RAppColors.primary,
        foregroundColor: Colors.white,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RAppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RAppRadius.md),
        ),
      ),

      searchBarTheme: SearchBarThemeData(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RAppRadius.xl),
          ),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      dividerTheme: const DividerThemeData(thickness: 1),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RAppRadius.md),
            ),
          ),
        ),
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor: RAppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(RAppRadius.lg),
          ),
        ),
      ),
    );
  }
}