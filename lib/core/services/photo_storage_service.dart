import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'crashlytics_service.dart';

class PhotoStorageService {
  static String? _documentsDirectoryPath;

  /// Initializes the service with the absolute path of the application documents directory.
  static void initialize(String documentsPath) {
    _documentsDirectoryPath = documentsPath;
  }

  /// Resolves a relative path (e.g. "item_photos/abc.jpg") to an absolute path synchronously.
  /// If the path is already absolute, it is returned as-is.
  static String resolvePath(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return '';
    if (p.isAbsolute(relativePath)) {
      return relativePath;
    }
    final docPath = _documentsDirectoryPath;
    if (docPath == null) {
      // Fallback if not initialized yet
      return relativePath;
    }
    return p.join(docPath, relativePath);
  }

  /// Safely detects old absolute paths and extracts/converts them to relative ones.
  static String? tryMigrateToRelative(String? path) {
    if (path == null || path.isEmpty) return null;

    final keyIndex = path.indexOf('item_photos/');
    if (keyIndex != -1) {
      return path.substring(keyIndex);
    }

    final fallbackIndex = path.indexOf('photos/');
    if (fallbackIndex != -1) {
      return path.substring(fallbackIndex);
    }

    if (p.isAbsolute(path)) {
      final filename = p.basename(path);
      return 'item_photos/$filename';
    }

    return path;
  }

  /// Synchronously checks if a photo file exists in local storage.
  static bool imageExists(String? path) {
    if (path == null || path.isEmpty) return false;
    try {
      final resolved = resolvePath(path);
      return File(resolved).existsSync();
    } catch (e, stack) {
      _logError('Error checking if image exists ($path)', e, stack);
      return false;
    }
  }

  /// Asynchronously checks if a photo file exists in local storage.
  static Future<bool> validateImage(String? path) async {
    if (path == null || path.isEmpty) return false;
    try {
      final resolved = resolvePath(path);
      return await File(resolved).exists();
    } catch (e, stack) {
      _logError('Error validating image asynchronously ($path)', e, stack);
      return false;
    }
  }

  /// Deletes a local photo file from the filesystem.
  static Future<void> deletePhoto(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final resolved = resolvePath(path);
      final file = File(resolved);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e, stack) {
      _logError('Failed to delete photo ($path)', e, stack);
    }
  }

  /// Logs a missing image file warning.
  static void logMissingFile(String path) {
    _logError('Image file does not exist at reference path', path);
  }

  /// Logs an image loading/decoding failure.
  static void logImageError(String path, dynamic error, StackTrace? stack) {
    _logError('Image decoding failure at reference path: $path', error, stack);
  }

  /// Copies a source photo into the local media folder and returns the relative path.
  static Future<String> savePhoto(String sourcePath) async {
    try {
      final docPath = _documentsDirectoryPath ?? (await getApplicationDocumentsDirectory()).path;
      final photoDir = Directory(p.join(docPath, 'item_photos'));

      if (!photoDir.existsSync()) {
        photoDir.createSync(recursive: true);
      }

      final extension = p.extension(sourcePath);
      final fileName = '${const Uuid().v4()}$extension';
      final destination = p.join(photoDir.path, fileName);

      await File(sourcePath).copy(destination);
      
      // Return the relative path
      return p.join('item_photos', fileName).replaceAll('\\', '/');
    } catch (e, stack) {
      _logError('Failed to save photo from source: $sourcePath', e, stack);
      rethrow;
    }
  }

  /// Centralized logging helper.
  static void _logError(String message, dynamic error, [StackTrace? stack]) {
    final msg = '[PhotoStorageService] $message: $error';
    debugPrint(msg);
    if (stack != null) {
      debugPrint(stack.toString());
    }
    try {
      CrashlyticsService.log(msg);
      if (error != null) {
        CrashlyticsService.recordError(error, stack ?? StackTrace.current);
      }
    } catch (e) {
      debugPrint('[PhotoStorageService] Log to Crashlytics failed: $e');
    }
  }
}