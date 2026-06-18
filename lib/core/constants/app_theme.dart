import 'package:flutter/material.dart';

class RAppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.indigo,
      brightness: Brightness.light,
    );
  }
}