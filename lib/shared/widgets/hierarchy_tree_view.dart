// File: lib/shared/widgets/hierarchy_tree_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/storage_node_providers.dart';
import '../entities/storage_node_entity.dart';
import '../enums/node_type.dart';
import 'safe_image_widget.dart';
import '../extensions/context_extensions.dart';

class HierarchyTreeView extends ConsumerWidget {
  final String rootUuid;
  final String? activeNodeUuid;

  const HierarchyTreeView({
    super.key,
    required this.rootUuid,
    this.activeNodeUuid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(nodeChildrenProvider(rootUuid));
    final theme = Theme.of(context);

    return childrenAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => Center(child: Text('Error loading tree: $e')),
      data: (children) {
        if (children.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Center(
              child: Text(
                'No contents inside this location',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          itemBuilder: (context, index) {
            return TreeNodeWidget(
              node: children[index],
              activeNodeUuid: activeNodeUuid,
            );
          },
        );
      },
    );
  }
}

class TreeNodeWidget extends ConsumerStatefulWidget {
  final StorageNodeEntity node;
  final String? activeNodeUuid;

  const TreeNodeWidget({
    super.key,
    required this.node,
    this.activeNodeUuid,
  });

  @override
  ConsumerState<TreeNodeWidget> createState() => _TreeNodeWidgetState();
}

class _TreeNodeWidgetState extends ConsumerState<TreeNodeWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final isTerminal = node.nodeType == NodeType.item.name;
    final isActive = widget.activeNodeUuid == node.uuid;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textStyle = context.bodyStyle.copyWith(
      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
      color: isActive ? const Color(0xFFD10047) : theme.colorScheme.onSurface,
    );

    final activeBgColor = isActive
        ? (isDark ? theme.colorScheme.primary.withOpacity(0.15) : const Color(0xFFFFF5F8))
        : Colors.transparent;

    if (isTerminal) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: activeBgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 12.0, right: 12.0),
          leading: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: activeBgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: SafeImageWidget(
              photoPath: node.photoPath,
              borderRadius: BorderRadius.circular(4),
              placeholder: Icon(
                Icons.label_outline,
                size: 16,
                color: isActive ? const Color(0xFFD10047) : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          title: Text(
            node.name,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: isActive ? const Color(0xFFD10047) : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
          onTap: () => context.push('/node/${node.uuid}'),
        ),
      );
    }

    final childrenAsync = ref.watch(nodeChildrenProvider(node.uuid));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: activeBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        // Clean up theme to remove default dividers in ExpansionTile
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: const Color(0xFFD10047),
          collapsedIconColor: theme.colorScheme.onSurfaceVariant,
          title: Row(
            children: [
              Icon(
                node.nodeType == NodeType.container.name
                    ? Icons.inventory_2_outlined
                    : Icons.view_agenda_outlined,
                size: 18,
                color: isActive ? const Color(0xFFD10047) : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.name,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          leading: Container(
            decoration: BoxDecoration(
              color: activeBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: isActive ? const Color(0xFFD10047) : theme.colorScheme.onSurfaceVariant,
              ),
              tooltip: 'Open',
              onPressed: () => context.push('/node/${node.uuid}'),
            ),
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          children: [
            if (_isExpanded)
              childrenAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Error: $e',
                    style: context.bodySmallStyle.copyWith(color: Colors.red),
                  ),
                ),
                data: (children) {
                  if (children.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(54, 4, 16, 12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 12, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            'Empty Location',
                            style: context.bodySmallStyle.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }
                  // Visual Indentation line
                  return Container(
                    margin: const EdgeInsets.only(left: 36.0, right: 12.0),
                    padding: const EdgeInsets.only(left: 4.0),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: isDark ? theme.colorScheme.outline.withOpacity(0.3) : const Color(0xFFF8D7E3),
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: children.length,
                      itemBuilder: (context, index) {
                        return TreeNodeWidget(
                          node: children[index],
                          activeNodeUuid: widget.activeNodeUuid,
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
