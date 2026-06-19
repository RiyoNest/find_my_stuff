import 'package:flutter/material.dart';

import 'app_colours.dart';
import 'app_radius.dart';

class RAppTheme {
  RAppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: RAppColors.primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      scaffoldBackgroundColor:
      RAppColors.lightBackground,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor:
        RAppColors.lightBackground,
        foregroundColor:
        colorScheme.onSurface,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: RAppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            RAppRadius.lg,
          ),
        ),
      ),

      floatingActionButtonTheme:
      FloatingActionButtonThemeData(
        backgroundColor:
        RAppColors.primary,
        foregroundColor: Colors.white,
      ),

      inputDecorationTheme:
      InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            RAppRadius.md,
          ),
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            RAppRadius.md,
          ),
          borderSide: const BorderSide(
            color: RAppColors.border,
          ),
        ),
      ),

      searchBarTheme: SearchBarThemeData(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              RAppRadius.xl,
            ),
          ),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding:
        EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
      ),

      dividerTheme: const DividerThemeData(
        thickness: 1,
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

      scaffoldBackgroundColor:
      RAppColors.darkBackground,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor:
        RAppColors.darkBackground,
        foregroundColor:
        colorScheme.onSurface,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: RAppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            RAppRadius.lg,
          ),
        ),
      ),

      floatingActionButtonTheme:
      FloatingActionButtonThemeData(
        backgroundColor:
        RAppColors.primary,
        foregroundColor: Colors.white,
      ),

      inputDecorationTheme:
      InputDecorationTheme(
        filled: true,
        fillColor: RAppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            RAppRadius.md,
          ),
        ),
      ),

      searchBarTheme: SearchBarThemeData(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              RAppRadius.xl,
            ),
          ),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding:
        EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
      ),
    );
  }
}