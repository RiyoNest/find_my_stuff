// File: lib/features/archive/presentation/pages/archived_items_page.dart
//
// CHANGES:
//   - Empty state replaced with illustrated CTA.
//   - Error state shows retry instead of raw error string.
//   - Tile now shows location path as subtitle (was: description).
//   - Restore action wrapped in try/catch with AppSnackBar feedback.
//   - Uses RAppSpacing/RAppRadius/RAppColors tokens throughout.

import 'dart:io';

import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArchivedItemsPage extends ConsumerWidget {
  const ArchivedItemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedAsync = ref.watch(archivedItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Archived Items')),
      body: archivedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(RAppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: RAppSpacing.sm),
                Text(
                  "Couldn't load archived items",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: RAppSpacing.md),
                TextButton.icon(
                  onPressed: () => ref.invalidate(archivedItemsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(RAppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: RAppSpacing.md),
                    Text(
                      'Nothing archived yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: RAppSpacing.xs),
                    Text(
                      'Items you archive will appear here.\nYou can restore them at any time.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: RAppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: RAppSpacing.md,
              vertical: RAppSpacing.sm,
            ),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: RAppSpacing.sm),
            itemBuilder: (_, index) {
              final item = items[index];
              return _ArchivedItemTile(item: item);
            },
          );
        },
      ),
    );
  }
}

class _ArchivedItemTile extends ConsumerWidget {
  final StorageNodeEntity item;

  const _ArchivedItemTile({required this.item});

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(storageNodeRepositoryProvider);
      repo.restoreItem(item.uuid);
      ref.invalidate(archivedItemsProvider);
      ref.read(storageRefreshProvider.notifier).state++;

      if (context.mounted) {
        AppSnackBar.success(context, '"${item.name}" restored');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, "Couldn't restore item. Please try again.");
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.read(storageNodeRepositoryProvider);
    final path = repo.buildPath(item);
    final hasPhoto =
        item.photoPath != null &&
            item.photoPath!.isNotEmpty &&
            File(item.photoPath!).existsSync();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RAppSpacing.md,
          vertical: RAppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            // Thumbnail or icon
            ClipRRect(
              borderRadius: BorderRadius.circular(RAppRadius.sm),
              child: hasPhoto
                  ? Image.file(
                File(item.photoPath!),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 48,
                height: 48,
                color: theme.colorScheme.surfaceContainerHigh,
                child: Icon(
                  Icons.archive_outlined,
                  color: RAppColors.textSecondary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: RAppSpacing.sm + 4),

            // Name + path
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (path.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      path,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: RAppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (item.isImportant) ...[
                    const SizedBox(height: RAppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: RAppSpacing.xs + 2,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: RAppColors.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(RAppRadius.sm),
                      ),
                      child: Text(
                        'Important',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: RAppColors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Restore button
            IconButton(
              icon: const Icon(Icons.unarchive_outlined),
              tooltip: 'Restore',
              color: theme.colorScheme.primary,
              onPressed: () => _restore(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}