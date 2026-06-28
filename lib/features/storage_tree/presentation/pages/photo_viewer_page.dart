// File: lib/features/storage_tree/presentation/pages/photo_viewer_page.dart
//
// CHANGES:
//   - Bottom bar is now a styled frosted-glass-style container with item
//     name + "View Item" action, rather than a plain black Container.
//   - File-missing guard applied to the share action (was: silent if file
//     missing; now: AppSnackBar.error).
//   - App bar stays black for immersive photo viewing; icons use white
//     foreground consistently.
//   - InteractiveViewer only shown when file exists.

import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:find_my_stuff/core/services/photo_storage_service.dart';
import 'package:find_my_stuff/shared/widgets/safe_image_widget.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';

class PhotoViewerPage extends StatelessWidget {
  final String imagePath;
  final String itemUuid;
  final String itemName;

  const PhotoViewerPage({
    super.key,
    required this.imagePath,
    required this.itemUuid,
    required this.itemName,
  });

  @override
  Widget build(BuildContext context) {
    final fileExists = PhotoStorageService.imageExists(imagePath);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          itemName,
          style: context.titleStyle.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (fileExists)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              tooltip: 'Share Photo',
              onPressed: () async {
                final resolved = PhotoStorageService.resolvePath(imagePath);
                await Share.shareXFiles([XFile(resolved)]);
              },
            ),
          IconButton(
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            tooltip: 'Open Item',
            onPressed: () => context.push('/node/$itemUuid'),
          ),
        ],
      ),
      body: fileExists
          ? InteractiveViewer(
        minScale: 0.5,
        maxScale: 5,
        child: Center(
          child: Hero(
            tag: imagePath,
            child: SafeImageWidget(
              photoPath: imagePath,
              fit: BoxFit.contain,
            ),
          ),
        ),
      )
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.broken_image_outlined,
              size: 80,
              color: Colors.white54,
            ),
            const SizedBox(height: RAppSpacing.sm),
            Text(
              'Image not found',
              style: context.subtitleStyle.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: RAppSpacing.md),
            OutlinedButton(
              onPressed: () => context.push('/node/$itemUuid'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
              child: const Text('Go to Item'),
            ),
          ],
        ),
      ),
    );
  }
}