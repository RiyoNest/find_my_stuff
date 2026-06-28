import 'package:flutter/material.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';
import 'package:find_my_stuff/shared/widgets/safe_image_widget.dart';
import 'package:find_my_stuff/features/storage_tree/presentation/pages/photo_viewer_page.dart';

class ItemHeroHeader extends StatelessWidget {
  final StorageNodeEntity node;
  final List<StorageNodeEntity> path;

  const ItemHeroHeader({
    super.key,
    required this.node,
    required this.path,
  });

  String _categoryLabel() => 'Uncategorized';

  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);
    
    if (difference.inDays >= 365) {
      final years = (difference.inDays / 365).floor();
      return 'Updated $years year${years > 1 ? "s" : ""} ago';
    } else if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return 'Updated $months month${months > 1 ? "s" : ""} ago';
    } else if (difference.inDays >= 1) {
      if (difference.inDays == 1) {
        return 'Updated yesterday';
      }
      return 'Updated ${difference.inDays} days ago';
    } else if (difference.inHours >= 1) {
      return 'Updated ${difference.inHours} hour${difference.inHours > 1 ? "s" : ""} ago';
    } else if (difference.inMinutes >= 1) {
      return 'Updated ${difference.inMinutes} minute${difference.inMinutes > 1 ? "s" : ""} ago';
    } else {
      return 'Updated just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasThumbnail = node.photoPath != null && node.photoPath!.isNotEmpty;
    
    // Only show Room and Location for the compact storage summary
    final compactPath = path
        .where((e) => e.uuid != node.uuid)
        .take(2)
        .map((e) => e.name)
        .join(' › ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: context.spacingXS,
                runSpacing: context.spacingXS,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (node.isImportant)
                    Semantics(
                      label: 'Important tag',
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.spacingS + 2,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: context.borderRadiusM,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Important',
                              style: context.labelStyle.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Semantics(
                    label: 'Category tag',
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.spacingS + 2,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: context.borderRadiusM,
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _categoryLabel(),
                            style: context.labelStyle.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.spacingM),
              Text(
                node.name,
                style: context.headlineStyle.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  height: 1.2,
                ),
              ),
              if (compactPath.isNotEmpty) ...[
                SizedBox(height: context.spacingXS),
                Text(
                  compactPath,
                  style: context.subtitleStyle.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              SizedBox(height: context.spacingXS),
              Text(
                _timeAgo(node.updatedAt),
                style: context.captionStyle.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (hasThumbnail) ...[
          SizedBox(width: context.spacingM),
          Semantics(
            label: 'Item thumbnail',
            child: Tooltip(
              message: 'View Image',
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PhotoViewerPage(
                        imagePath: node.photoPath!,
                        itemUuid: node.uuid,
                        itemName: node.name,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: context.borderRadiusL,
                  child: SafeImageWidget(
                    photoPath: node.photoPath,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
