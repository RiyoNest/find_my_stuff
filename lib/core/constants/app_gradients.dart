// File: lib/core/constants/app_gradients.dart
//
// Single source of truth for every gradient used in the app.
// Centralised here so swapping a palette only requires one file change.

import 'package:flutter/material.dart';

class RAppGradients {
  RAppGradients._();

  // ── Stat card gradients ─────────────────────────────────────────────────

  static const LinearGradient items = LinearGradient(
    colors: [Color(0xFFB11226), Color(0xFFE65100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient important = LinearGradient(
    colors: [Color(0xFFE65100), Color(0xFFFFB703)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient photos = LinearGradient(
    colors: [Color(0xFF3F51B5), Color(0xFF7B1FA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient archived = LinearGradient(
    colors: [Color(0xFF546E7A), Color(0xFF37474F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Room palette — rotates by index ────────────────────────────────────

  static const List<LinearGradient> _roomPalette = [
    LinearGradient(
      colors: [Color(0xFFE91E63), Color(0xFFFF5722)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF1565C0), Color(0xFF00ACC1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF2E7D32), Color(0xFF00897B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFF57C00), Color(0xFFF9A825)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF6A1B9A), Color(0xFF283593)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF00695C), Color(0xFF0277BD)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  static LinearGradient roomGradient(int index) =>
      _roomPalette[index % _roomPalette.length];

  // ── Misc ────────────────────────────────────────────────────────────────

  static const LinearGradient emptyStateBg = LinearGradient(
    colors: [Color(0x14B11226), Color(0x083F51B5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}