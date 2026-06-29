import 'package:flutter/material.dart';
import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';

class ItemBottomActionBar extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onMove;
  final VoidCallback onShare;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const ItemBottomActionBar({
    super.key,
    required this.onEdit,
    required this.onMove,
    required this.onShare,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacingM,
          vertical: context.spacingS,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Primary Actions group
              Semantics(
                label: 'Edit item details',
                button: true,
                child: Tooltip(
                  message: 'Edit details',
                  child: FilledButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
              ),
              SizedBox(width: context.spacingS),
              Semantics(
                label: 'Move item location',
                button: true,
                child: Tooltip(
                  message: 'Change location',
                  child: FilledButton.tonalIcon(
                    onPressed: onMove,
                    icon: const Icon(Icons.drive_file_move_outlined, size: 18),
                    label: const Text('Move'),
                  ),
                ),
              ),
              SizedBox(width: context.spacingS),
              
              // Secondary Actions group
              Semantics(
                label: 'Share item',
                button: true,
                child: Tooltip(
                  message: 'Share',
                  child: OutlinedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share'),
                  ),
                ),
              ),
              SizedBox(width: context.spacingS),
              Semantics(
                label: 'Archive item',
                button: true,
                child: Tooltip(
                  message: 'Archive',
                  child: OutlinedButton.icon(
                    onPressed: onArchive,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: RAppColors.warning,
                      side: BorderSide(
                        color: RAppColors.warning.withValues(alpha: 0.5),
                      ),
                    ),
                    icon: const Icon(Icons.archive_outlined, size: 18),
                    label: const Text('Archive'),
                  ),
                ),
              ),
              
              // Destructive Action group (visually separated)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.spacingS),
                child: Container(
                  width: 1,
                  height: 24,
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              Semantics(
                label: 'Delete item permanently',
                button: true,
                child: Tooltip(
                  message: 'Delete permanently',
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      backgroundColor: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                      side: BorderSide(
                        color: theme.colorScheme.error,
                        width: 1.5,
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
