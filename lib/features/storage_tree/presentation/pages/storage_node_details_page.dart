// File: lib/features/storage_tree/presentation/pages/storage_node_details_page.dart
//
// CHANGES:
//   - Children renamed "Contents" (less technical for a household app).
//   - Child cards now show type-appropriate icons and a colored type badge
//     instead of all showing Icons.folder_outlined + raw nodeType string.
//   - Redundant double .when() for count label collapsed into a single one.
//   - Empty state replaced with an illustrated CTA instead of plain Text.
//   - Error state for childrenAsync now visible instead of just Text(e).
//   - Uses RAppSpacing/RAppRadius/RAppColors tokens throughout.
//   - AppSnackBar on add-child error.

import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:find_my_stuff/features/storage_tree/presentation/pages/item_details_page.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/enums/node_type.dart';
import 'package:find_my_stuff/shared/models/add_child_node_result.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../widgets/add_child_node_dialog.dart';

class StorageNodeDetailsPage extends ConsumerStatefulWidget {
  final String nodeUuid;

  const StorageNodeDetailsPage({super.key, required this.nodeUuid});

  @override
  ConsumerState<StorageNodeDetailsPage> createState() =>
      _StorageNodeDetailsPageState();
}

class _StorageNodeDetailsPageState
    extends ConsumerState<StorageNodeDetailsPage> {

  Future<void> _addChildNode(StorageNodeEntity parentNode) async {
    final result = await showDialog<AddChildNodeResult>(
      context: context,
      builder: (_) => const AddChildNodeDialog(),
    );

    if (result == null) return;

    try {
      final childNode = StorageNodeEntity(
        uuid: const Uuid().v4(),
        roomUuid: parentNode.roomUuid,
        parentUuid: parentNode.uuid,
        nodeType: result.nodeType.name,
        name: result.name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(storageNodeRepositoryProvider).save(childNode);
      ref.read(storageRefreshProvider.notifier).state++;

      if (mounted) {
        AppSnackBar.success(context, '"${result.name}" added');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, "Couldn't add item. Please try again.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nodeAsync = ref.watch(storageNodeProvider(widget.nodeUuid));

    return nodeAsync.when(
      loading: () =>
      const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (node) {
        if (node == null) {
          return const Scaffold(
            body: Center(child: Text('Node not found')),
          );
        }

        // Items are terminal — delegate to ItemDetailsPage.
        if (node.nodeType == NodeType.item.name) {
          return ItemDetailsPage(nodeUuid: node.uuid);
        }

        final childrenAsync = ref.watch(childNodesProvider(node.uuid));

        return Scaffold(
          appBar: AppBar(title: Text(node.name)),
          floatingActionButton: FloatingActionButton(
            heroTag: 'node_add_child',
            onPressed: () => _addChildNode(node),
            tooltip: 'Add to ${node.name}',
            child: const Icon(Icons.add),
          ),
          body: childrenAsync.when(
            loading: () =>
            const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(RAppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Couldn't load contents",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: RAppSpacing.sm),
                    TextButton.icon(
                      onPressed: () =>
                          ref.invalidate(childNodesProvider(node.uuid)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (children) {
              if (children.isEmpty) {
                return _EmptyContentsState(
                  parentName: node.name,
                  onAdd: () => _addChildNode(node),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      RAppSpacing.md,
                      RAppSpacing.md,
                      RAppSpacing.md,
                      RAppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Contents',
                          style:
                          Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(width: RAppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: RAppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHigh,
                            borderRadius:
                            BorderRadius.circular(RAppRadius.sm),
                          ),
                          child: Text(
                            '${children.length}',
                            style:
                            Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        RAppSpacing.md,
                        0,
                        RAppSpacing.md,
                        100,
                      ),
                      itemCount: children.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: RAppSpacing.sm),
                      itemBuilder: (_, index) {
                        final child = children[index];
                        return _ChildNodeCard(
                          node: child,
                          onTap: () =>
                              context.push('/node/${child.uuid}'),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _ChildNodeCard extends StatelessWidget {
  final StorageNodeEntity node;
  final VoidCallback onTap;

  const _ChildNodeCard({required this.node, required this.onTap});

  static _NodeMeta _meta(String nodeType) {
    if (nodeType == NodeType.item.name) {
      return (Icons.label_rounded, RAppColors.primary, 'Item');
    }
    if (nodeType == NodeType.container.name) {
      return (Icons.inventory_2_rounded, RAppColors.accent, 'Container');
    }
    return (Icons.view_agenda_rounded, RAppColors.secondary, 'Section');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color, label) = _meta(node.nodeType);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RAppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RAppSpacing.md,
            vertical: RAppSpacing.sm + 4,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(RAppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: RAppSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: RAppSpacing.xs + 2,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius:
                        BorderRadius.circular(RAppRadius.sm),
                      ),
                      child: Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

// Type alias for the (icon, color, label) triple used by _ChildNodeCard.
typedef _NodeMeta = (IconData, Color, String);

class _EmptyContentsState extends StatelessWidget {
  final String parentName;
  final VoidCallback onAdd;

  const _EmptyContentsState({
    required this.parentName,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(RAppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: RAppSpacing.md),
            Text('"$parentName" is empty', style: theme.textTheme.titleMedium),
            const SizedBox(height: RAppSpacing.xs),
            Text(
              'Add a section, container, or item\nto start organising this space.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: RAppSpacing.md),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Something'),
            ),
          ],
        ),
      ),
    );
  }
}