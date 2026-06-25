// File: lib/shared/widgets/item_activity_tile.dart
//
// CHANGES: Gradient left accent bar + colored emoji icon container
// instead of a plain grey Icon. Important items get an amber accent,
// others get the brand red. Replaces the flat Card + ListTile.

import 'package:find_my_stuff/core/constants/app_gradients.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ItemActivityTile extends StatelessWidget {
  final StorageNodeEntity item;

  const ItemActivityTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = item.isImportant
        ? RAppGradients.important
        : RAppGradients.items;
    final emoji = item.isImportant ? '⭐' : '📦';

    return Padding(
      padding: const EdgeInsets.only(bottom: RAppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(RAppRadius.lg),
        onTap: () => context.push('/node/${item.uuid}'),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(RAppRadius.lg),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              // Gradient left accent bar
              Container(
                width: 5,
                height: 60,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(RAppRadius.lg),
                    bottomLeft: Radius.circular(RAppRadius.lg),
                  ),
                ),
              ),
              const SizedBox(width: RAppSpacing.sm + 2),
              // Emoji icon in a gradient container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(RAppRadius.sm),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: RAppSpacing.sm + 4),
              // Name + tags
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.tags != null && item.tags!.isNotEmpty)
                      Text(
                        item.tags!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: RAppSpacing.sm),
                child: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.outline,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}