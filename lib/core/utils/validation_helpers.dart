// File: lib/core/utils/validation_helpers.dart
//
// Input validation utilities for room names, item names, and general text.
// Used across the app to ensure consistent validation rules and error messages.

class ValidationHelpers {
  static const int minRoomNameLength = 1;
  static const int maxRoomNameLength = 50;
  static const int minItemNameLength = 1;
  static const int maxItemNameLength = 100;

  /// Validates a room name. Returns error message or null if valid.
  static String? validateRoomName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Room name is required';
    }

    final trimmed = value.trim();

    if (trimmed.length < minRoomNameLength) {
      return 'Room name must be at least $minRoomNameLength character';
    }

    if (trimmed.length > maxRoomNameLength) {
      return 'Room name cannot exceed $maxRoomNameLength characters';
    }

    if (!_isValidText(trimmed)) {
      return 'Room name contains invalid characters';
    }

    return null;
  }

  /// Validates an item name. Returns error message or null if valid.
  static String? validateItemName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Item name is required';
    }

    final trimmed = value.trim();

    if (trimmed.length < minItemNameLength) {
      return 'Item name must be at least $minItemNameLength character';
    }

    if (trimmed.length > maxItemNameLength) {
      return 'Item name cannot exceed $maxItemNameLength characters';
    }

    if (!_isValidText(trimmed)) {
      return 'Item name contains invalid characters';
    }

    return null;
  }

  /// Validates a description field (optional). Returns error message or null if valid.
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) return null;

    if (value.length > 500) {
      return 'Description cannot exceed 500 characters';
    }

    return null;
  }

  /// Validates tags field (optional). Returns error message or null if valid.
  static String? validateTags(String? value) {
    if (value == null || value.isEmpty) return null;

    if (value.length > 200) {
      return 'Tags cannot exceed 200 characters';
    }

    return null;
  }

  /// Generic text validation: allows letters, numbers, spaces, and some punctuation.
  static bool _isValidText(String text) {
    final validPattern =
    RegExp("^[a-zA-Z0-9\\s\\-.,&'\\\"()\\u00C0-\\u017F]+\$");
    return validPattern.hasMatch(text);
  }

  /// Sanitizes input by trimming and removing multiple spaces.
  static String sanitize(String input) {
    return input.trim().replaceAll(RegExp(r' +'), ' ');
  }

  /// Checks if a string is empty or only whitespace.
  static bool isEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// Checks if a string exceeds max length.
  static bool exceedsMaxLength(String? value, int maxLength) {
    return value != null && value.length > maxLength;
  }
}