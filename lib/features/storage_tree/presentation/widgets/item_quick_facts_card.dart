import 'package:flutter/material.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';

class ItemQuickFactsCard extends StatelessWidget {
  final StorageNodeEntity item;
  final String pathString;

  const ItemQuickFactsCard({
    super.key,
    required this.item,
    required this.pathString,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Not set';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatRelativeTime(DateTime? dt) {
    if (dt == null) return 'Never';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(itemDay).inDays;

    if (diffDays == 0) {
      final diffMin = now.difference(dt).inMinutes;
      if (diffMin < 1) return 'Just now';
      if (diffMin < 60) return '$diffMin minutes ago';
      final diffHrs = now.difference(dt).inHours;
      return '$diffHrs ${diffHrs == 1 ? 'hour' : 'hours'} ago';
    } else if (diffDays == 1) {
      return 'Yesterday';
    } else if (diffDays < 7) {
      return '$diffDays days ago';
    } else {
      return _formatDate(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasPhotos = item.photoPath != null && item.photoPath!.trim().isNotEmpty;
    final photoCountText = hasPhotos ? '1 attached' : 'None';

    final facts = [
      ('Storage', pathString.isNotEmpty ? pathString : 'Not assigned', Icons.location_on_outlined),
      ('Status', item.isArchived ? 'Archived' : (item.isImportant ? 'Important' : 'Standard'), Icons.info_outline),
      ('Created', _formatDate(item.createdAt), Icons.calendar_today_outlined),
      ('Last Updated', _formatRelativeTime(item.updatedAt), Icons.edit_note_outlined),
      ('Last Opened', _formatRelativeTime(item.viewedAt), Icons.visibility_outlined),
      ('Photos', photoCountText, Icons.photo_library_outlined),
      ('Expiry', item.trackExpiry && item.expiryDate != null ? _formatDate(item.expiryDate) : 'Not tracked', Icons.alarm),
    ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: context.borderRadiusL,
        side: BorderSide(
          color: isDark ? theme.colorScheme.outline.withValues(alpha: 0.3) : const Color(0xFFF8D7E3),
          width: 0.6,
        ),
      ),
      child: Padding(
        padding: context.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: 'Item Quick Facts header',
              child: Row(
                children: [
                  Icon(
                    Icons.dashboard_customize_outlined,
                    size: context.iconMedium,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Facts',
                    style: context.titleStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            
            // Grid of Fact Cards
            LayoutBuilder(
              builder: (context, constraints) {
                // If width is narrow, list view layout, otherwise two column grid
                final useColumns = constraints.maxWidth > 400;
                
                if (useColumns) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 8,
                      childAspectRatio: 4.5,
                    ),
                    itemCount: facts.length,
                    itemBuilder: (context, index) {
                      return _buildFactRow(context, facts[index]);
                    },
                  );
                } else {
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: facts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      return _buildFactRow(context, facts[index]);
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactRow(BuildContext context, (String, String, IconData) fact) {
    final theme = Theme.of(context);
    
    return Semantics(
      label: 'Fact: ${fact.$1} value ${fact.$2}',
      child: Tooltip(
        message: '${fact.$1}: ${fact.$2}',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(context.spacingXS),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: context.borderRadiusS,
              ),
              child: Icon(
                fact.$3,
                size: 14,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fact.$1,
                    style: context.bodySmallStyle.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    fact.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.bodySmallStyle.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
