import 'package:flutter/material.dart';

class ResponsiveLayout {
  ResponsiveLayout._();

  /// Gets the column count based on width breakpoints:
  /// Mobile (<600): 1 Column
  /// Tablet (600-899): 2 Columns
  /// Large Tablet (900-1199): 3 Columns
  /// Desktop (1200+): 4 Columns
  static int getColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    return 4;
  }

  /// Calculates the child aspect ratio for room cards
  static double getRoomCardAspectRatio(int cols) {
    if (cols == 1) return 2.8;
    if (cols == 2) return 1.4;
    if (cols == 3) return 1.2;
    return 1.1;
  }

  /// Calculates the child aspect ratio for general node/item cards (Grid view)
  static double getItemCardAspectRatio(int cols) {
    if (cols == 1) return 2.6;
    if (cols == 2) return 1.2;
    if (cols == 3) return 1.1;
    return 1.0;
  }

  /// Calculates the child aspect ratio for photo gallery cards
  static double getPhotoCardAspectRatio(int cols) {
    if (cols == 1) return 1.8;
    if (cols == 2) return 1.1;
    if (cols == 3) return 1.0;
    return 0.9;
  }
}
