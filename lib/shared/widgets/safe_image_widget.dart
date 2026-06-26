import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/services/photo_storage_service.dart';

class SafeImageWidget extends StatelessWidget {
  final String? photoPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadiusGeometry? borderRadius;
  final Widget? placeholder;

  const SafeImageWidget({
    super.key,
    required this.photoPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (photoPath == null || photoPath!.isEmpty) {
      return _buildPlaceholder(context);
    }

    final resolvedPath = PhotoStorageService.resolvePath(photoPath);
    final file = File(resolvedPath);

    if (!file.existsSync()) {
      // Log the missing file safely
      PhotoStorageService.logMissingFile(photoPath!);
      return _buildPlaceholder(context);
    }

    final imageWidget = Image.file(
      file,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Log the decoding failure safely
        PhotoStorageService.logImageError(photoPath!, error, stackTrace);
        return _buildPlaceholder(context);
      },
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder != null) {
      return placeholder!;
    }
    // Default fallback placeholder (vibrant primary colors matching existing aesthetics/theme)
    final theme = Theme.of(context);
    return Container(
      width: width ?? double.infinity,
      height: height ?? 150,
      color: theme.colorScheme.surfaceContainerLow,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: theme.colorScheme.outline,
          size: (width != null && width! < 60) ? 24 : 40,
        ),
      ),
    );
  }
}
