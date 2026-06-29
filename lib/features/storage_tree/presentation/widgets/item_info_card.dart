import 'package:flutter/material.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';

class ItemInfoCard extends StatelessWidget {
  final StorageNodeEntity node;
  final String Function(DateTime) formatDate;

  const ItemInfoCard({
    super.key,
    required this.node,
    required this.formatDate,
  });

  String _describeDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(dt.year, dt.month, dt.day);
    
    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return formatDate(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTags = node.tags != null && node.tags!.trim().isNotEmpty;
    final hasExpiry = node.trackExpiry && node.expiryDate != null;

    final tagsList = hasTags
        ? node.tags!
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList()
        : <String>[];

    final List<Widget> items = [];

    // 1. Created Row
    items.add(_MetadataBlock(
      icon: Icons.calendar_today_outlined,
      label: 'Created',
      value: Text(
        _describeDate(node.createdAt),
        style: context.bodyStyle.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    ));

    // 2. Updated Row
    items.add(_MetadataBlock(
      icon: Icons.update_outlined,
      label: 'Updated',
      value: Text(
        _describeDate(node.updatedAt),
        style: context.bodyStyle.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    ));

    // 3. Expiry Row (if tracked)
    if (hasExpiry) {
      items.add(_MetadataBlock(
        icon: Icons.alarm_on_rounded,
        label: 'Expiry',
        value: Text(
          _describeDate(node.expiryDate!),
          style: context.bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ));
    }

    // 4. Tags Row (Always displayed - shows placeholder if empty to prevent layout jumping)
    items.add(_MetadataBlock(
      icon: Icons.local_offer_outlined,
      label: 'Tags',
      value: tagsList.isNotEmpty
          ? Wrap(
              spacing: context.spacingXS,
              runSpacing: context.spacingXS,
              children: tagsList.map((t) => Chip(
                label: Text(t, style: context.bodySmallStyle.copyWith(fontWeight: FontWeight.w500)),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            )
          : Text(
              'No tags added',
              style: context.bodyStyle.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
    ));

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
              'Information',
              style: context.titleStyle.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => SizedBox(height: context.spacingM),
              itemBuilder: (_, index) => items[index],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget value;

  const _MetadataBlock({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: context.bodySmallStyle.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 24.0),
          child: value,
        ),
      ],
    );
  }
}
