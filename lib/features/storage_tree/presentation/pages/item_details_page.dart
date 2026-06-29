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

import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/providers/storage_path_provider.dart';
import 'package:find_my_stuff/shared/providers/room_providers.dart';
import 'package:find_my_stuff/shared/widgets/custom_snackbar.dart';
import 'package:find_my_stuff/shared/widgets/loading_state_widget.dart';
import 'package:find_my_stuff/shared/widgets/error_state_widget.dart';
import 'package:find_my_stuff/shared/widgets/delete_action.dart';
import 'package:find_my_stuff/shared/models/storage_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'edit_item_page.dart';
import 'move_node_page.dart';
import '../widgets/item_hero_header.dart';
import '../widgets/item_quick_actions.dart';
import '../widgets/item_info_card.dart';
import '../widgets/storage_details_card.dart';
import '../widgets/item_description_card.dart';
import '../widgets/item_photo_card.dart';
import '../widgets/item_bottom_action_bar.dart';
import '../widgets/item_quick_facts_card.dart';

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



  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final nodeAsync = ref.watch(storageNodeProvider(widget.nodeUuid));
    final pathAsync = ref.watch(storagePathProvider(widget.nodeUuid));

    final theme = Theme.of(context);

    return nodeAsync.when(
      loading: () => const Scaffold(
        body: LoadingStateWidget(type: LoadingType.details),
      ),
      error: (e, _) => Scaffold(
        body: ErrorStateWidget(
          description: "We couldn't load this item.",
          onRetry: () => ref.invalidate(storageNodeProvider(widget.nodeUuid)),
        ),
      ),
      data: (node) {
        if (node == null) {
          return Scaffold(
            body: ErrorStateWidget(
              description: 'Item not found',
              secondaryAction: TextButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ),
          );
        }

        final path = pathAsync.value ?? const StoragePath([]);
        final roomAsync = ref.watch(roomDetailsProvider(node.roomUuid));
        final storageCardKey = GlobalKey<StorageDetailsCardState>();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              node.name,
              style: context.titleStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            scrolledUnderElevation: 0,
          ),
          bottomNavigationBar: ItemBottomActionBar(
            onEdit: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditItemPage(node: node),
                ),
              );
              ref.invalidate(storageNodeProvider(widget.nodeUuid));
            },
            onMove: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MoveNodePage(node: node),
                ),
              );
              ref.read(storageRefreshProvider.notifier).state++;
              if (mounted) {
                ref.invalidate(storageNodeProvider(widget.nodeUuid));
              }
            },
            onShare: () {
              AppSnackBar.info(context, 'Sharing feature coming soon!');
            },
            onArchive: () => _onArchive(context, node.name, node.uuid),
            onDelete: () {
              DeleteAction.execute(
                context: context,
                ref: ref,
                nodeType: 'item',
                uuid: node.uuid,
                displayName: node.name,
              );
            },
          ),
          body: SingleChildScrollView(
            padding: context.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ItemHeroHeader(
                  node: node,
                  path: path,
                ),
                SizedBox(height: context.spacingM),
                ItemQuickFactsCard(
                  item: node,
                  pathString: path.displayString,
                ),
                SizedBox(height: context.spacingM),
                ItemQuickActions(
                  onEdit: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditItemPage(node: node),
                      ),
                    );
                    ref.invalidate(storageNodeProvider(widget.nodeUuid));
                  },
                  onMove: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MoveNodePage(node: node),
                      ),
                    );
                    ref.read(storageRefreshProvider.notifier).state++;
                    if (mounted) {
                      ref.invalidate(storageNodeProvider(widget.nodeUuid));
                    }
                  },
                  onLocate: () {
                    final keyContext = storageCardKey.currentContext;
                    if (keyContext != null) {
                      Scrollable.ensureVisible(
                        keyContext,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                      storageCardKey.currentState?.highlight();
                    }
                  },
                ),
                SizedBox(height: context.spacingM),
                if (node.trackExpiry && node.expiryDate != null) ...[
                  _ExpiryCard(expiryDate: node.expiryDate!),
                  SizedBox(height: context.spacingM),
                ],
                ItemInfoCard(
                  node: node,
                  formatDate: _formatDate,
                ),
                SizedBox(height: context.spacingM),
                StorageDetailsCard(
                  key: storageCardKey,
                  roomName: roomAsync.value?.name,
                  path: path,
                  onMove: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MoveNodePage(node: node),
                      ),
                    );
                    ref.read(storageRefreshProvider.notifier).state++;
                    if (mounted) {
                      ref.invalidate(storageNodeProvider(widget.nodeUuid));
                    }
                  },
                ),
                SizedBox(height: context.spacingM),
                ItemDescriptionCard(description: node.description),
                SizedBox(height: context.spacingM),
                ItemPhotoCard(
                  photoPath: node.photoPath,
                  itemName: node.name,
                  itemUuid: node.uuid,
                ),
              ],
            ),
          ),
        );
      },
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
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(RAppRadius.sm),
            ),
            child: Text(
              status,
              style: context.labelStyle.copyWith(
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}