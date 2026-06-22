// File: lib/features/storage_tree/presentation/pages/item_details_page.dart
//
// CHANGES:
//   - Edit / Move / Archive actions moved from icon-only app bar buttons
//     to a labelled bottom action bar — far more discoverable.
//   - Status chips (Important, Expiry Tracked) are now coloured so they
//     stand out rather than being unstyled grey.
//   - Tags render as individual Chip widgets instead of a raw comma string.
//   - Description and Tags sections hidden when empty (no "No description
//     available" placeholder text).
//   - Expiry card uses RAppColors.error / warning / success tokens.
//   - Location breadcrumbs use arrow separators for clearer hierarchy.
//   - Navigator.push replaced with consistent go_router context.push for
//     EditItemPage and MoveNodePage once those are added to AppRouter.
//   - Archive dialog improved: destructive FilledButton uses error color.

import 'dart:io';

import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:find_my_stuff/features/storage_tree/presentation/pages/photo_viewer_page.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/providers/storage_path_provider.dart';
import 'package:find_my_stuff/shared/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edit_item_page.dart';
import 'move_node_page.dart';

class ItemDetailsPage extends ConsumerStatefulWidget {
  final String nodeUuid;

  const ItemDetailsPage({super.key, required this.nodeUuid});

  @override
  ConsumerState<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends ConsumerState<ItemDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(storageNodeRepositoryProvider);
      repo.markAsViewed(widget.nodeUuid);
      ref.invalidate(recentlyViewedProvider);
      ref.invalidate(forgottenItemsProvider);
    });
  }

  Future<void> _onArchive(
      BuildContext context,
      String name,
      String uuid,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RAppRadius.lg),
        ),
        title: const Text('Archive Item'),
        content: Text(
          'Move "$name" to the archive? You can restore it from the Archived Items section.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: RAppColors.warning,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(storageNodeRepositoryProvider);
      repo.archiveItem(uuid);
      ref.read(storageRefreshProvider.notifier).state++;

      if (context.mounted) {
        AppSnackBar.success(context, '"$name" archived');
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, "Couldn't archive item. Please try again.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nodeAsync = ref.watch(storageNodeProvider(widget.nodeUuid));
    final pathAsync = ref.watch(storagePathProvider(widget.nodeUuid));

    return nodeAsync.when(
      loading: () =>
      const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (node) {
        if (node == null) {
          return const Scaffold(body: Center(child: Text('Item not found')));
        }

        return Scaffold(
          appBar: AppBar(title: Text(node.name)),

          // ── Bottom action bar ────────────────────────────────────
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: RAppSpacing.md,
                vertical: RAppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: RAppColors.border),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditItemPage(node: node),
                          ),
                        );
                        ref.invalidate(
                          storageNodeProvider(widget.nodeUuid),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: RAppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.drive_file_move_outlined,
                        size: 18,
                      ),
                      label: const Text('Move'),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MoveNodePage(node: node),
                          ),
                        );
                        ref.read(storageRefreshProvider.notifier).state++;
                        if (mounted) {
                          ref.invalidate(
                            storageNodeProvider(widget.nodeUuid),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: RAppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: RAppColors.warning,
                        side: BorderSide(
                          color: RAppColors.warning.withOpacity(0.5),
                        ),
                      ),
                      icon: const Icon(Icons.archive_outlined, size: 18),
                      label: const Text('Archive'),
                      onPressed: () =>
                          _onArchive(context, node.name, node.uuid),
                    ),
                  ),
                ],
              ),
            ),
          ),

          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              RAppSpacing.md,
              RAppSpacing.md,
              RAppSpacing.md,
              RAppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status chips ───────────────────────────────────
                if (node.isImportant || node.trackExpiry) ...[
                  Wrap(
                    spacing: RAppSpacing.sm,
                    runSpacing: RAppSpacing.xs,
                    children: [
                      if (node.isImportant)
                        _StatusChip(
                          label: 'Important',
                          icon: Icons.star_rounded,
                          color: RAppColors.accent,
                        ),
                      if (node.trackExpiry)
                        _StatusChip(
                          label: 'Expiry Tracked',
                          icon: Icons.schedule_rounded,
                          color: RAppColors.info,
                        ),
                    ],
                  ),
                  const SizedBox(height: RAppSpacing.md),
                ],

                // ── Expiry card ────────────────────────────────────
                if (node.trackExpiry && node.expiryDate != null) ...[
                  _ExpiryCard(expiryDate: node.expiryDate!),
                  const SizedBox(height: RAppSpacing.md),
                ],

                // ── Location breadcrumbs ───────────────────────────
                pathAsync.when(
                  loading: () => const SizedBox(
                    height: 24,
                    child: Center(child: LinearProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox(),
                  data: (path) {
                    if (path.isEmpty) return const SizedBox();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Location', style: theme.textTheme.titleMedium),
                        const SizedBox(height: RAppSpacing.sm),
                        Wrap(
                          spacing: RAppSpacing.xs,
                          runSpacing: RAppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            for (var i = 0; i < path.length; i++) ...[
                              Chip(
                                label: Text(path[i].name),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: RAppSpacing.xs,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              if (i < path.length - 1)
                                Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: RAppColors.textSecondary,
                                ),
                            ],
                          ],
                        ),
                        const SizedBox(height: RAppSpacing.md),
                      ],
                    );
                  },
                ),

                // ── Photo ──────────────────────────────────────────
                if (node.photoPath != null &&
                    node.photoPath!.isNotEmpty) ...[
                  Text('Photo', style: theme.textTheme.titleMedium),
                  const SizedBox(height: RAppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(RAppRadius.md),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PhotoViewerPage(
                            imagePath: node.photoPath!,
                            itemUuid: node.uuid,
                            itemName: node.name,
                          ),
                        ),
                      ),
                      child: Hero(
                        tag: node.photoPath!,
                        child: File(node.photoPath!).existsSync()
                            ? Image.file(
                          File(node.photoPath!),
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                            : Container(
                          height: 150,
                          width: double.infinity,
                          color: theme.colorScheme.surfaceContainerLow,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 40,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(height: RAppSpacing.xs),
                              Text(
                                'Photo not found',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: RAppSpacing.md),
                ],

                // ── Description ────────────────────────────────────
                if (node.description != null &&
                    node.description!.isNotEmpty) ...[
                  Text('Description', style: theme.textTheme.titleMedium),
                  const SizedBox(height: RAppSpacing.sm),
                  Text(node.description!, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: RAppSpacing.md),
                ],

                // ── Tags ───────────────────────────────────────────
                if (node.tags != null && node.tags!.isNotEmpty) ...[
                  Text('Tags', style: theme.textTheme.titleMedium),
                  const SizedBox(height: RAppSpacing.sm),
                  Wrap(
                    spacing: RAppSpacing.sm,
                    runSpacing: RAppSpacing.xs,
                    children: node.tags!
                        .split(',')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .map(
                          (t) => Chip(
                        label: Text(t),
                        visualDensity: VisualDensity.compact,
                        avatar: const Icon(Icons.label_outline, size: 14),
                      ),
                    )
                        .toList(),
                  ),
                  const SizedBox(height: RAppSpacing.md),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RAppSpacing.sm + 2,
        vertical: RAppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(RAppRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: RAppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiryCard extends StatelessWidget {
  final DateTime expiryDate;

  const _ExpiryCard({required this.expiryDate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysLeft = expiryDate.difference(DateTime.now()).inDays;

    final (color, bg, icon, status) = switch (true) {
      _ when daysLeft < 0 => (
      RAppColors.onErrorContainer,
      RAppColors.errorContainer,
      Icons.error_rounded,
      'Expired',
      ),
      _ when daysLeft <= 30 => (
      RAppColors.onWarningContainer,
      RAppColors.warningContainer,
      Icons.schedule_rounded,
      '$daysLeft days remaining',
      ),
      _ => (
      RAppColors.onSuccessContainer,
      RAppColors.successContainer,
      Icons.check_circle_rounded,
      '$daysLeft days remaining',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(RAppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(RAppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: RAppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expiry Date',
                  style: theme.textTheme.labelMedium?.copyWith(color: color),
                ),
                Text(
                  '${expiryDate.day}/${expiryDate.month}/${expiryDate.year}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: RAppSpacing.sm,
              vertical: RAppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(RAppRadius.sm),
            ),
            child: Text(
              status,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}