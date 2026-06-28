import 'package:flutter/material.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';
import 'package:find_my_stuff/shared/widgets/safe_image_widget.dart';
import 'package:find_my_stuff/features/storage_tree/presentation/pages/photo_viewer_page.dart';

class ItemPhotoCard extends StatelessWidget {
  final String? photoPath;
  final String itemName;
  final String itemUuid;

  const ItemPhotoCard({
    super.key,
    this.photoPath,
    required this.itemName,
    required this.itemUuid,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = photoPath != null && photoPath!.trim().isNotEmpty;
    final photoCount = hasPhoto ? 1 : 0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: context.borderRadiusL,
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: context.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Photos ($photoCount)',
              style: context.titleStyle.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 12),
            
            if (!hasPhoto)
              Semantics(
                label: 'No photos placeholder',
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: context.spacingXL),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: context.borderRadiusM,
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 32,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add photos to recognize this item faster.',
                        style: context.bodyStyle.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Photo Gallery Layout (Future-ready for multiple photos)
              // Currently displays a single large preview, but ready to become a GridView or Row
              ClipRRect(
                borderRadius: context.borderRadiusM,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoViewerPage(
                          imagePath: photoPath!,
                          itemUuid: itemUuid,
                          itemName: itemName,
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: photoPath!,
                    child: SafeImageWidget(
                      photoPath: photoPath,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
