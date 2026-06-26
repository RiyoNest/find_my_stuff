import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ItemActivityTile extends ConsumerStatefulWidget {
  final StorageNodeEntity item;

  const ItemActivityTile({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<ItemActivityTile> createState() => _ItemActivityTileState();
}

class _ItemActivityTileState extends ConsumerState<ItemActivityTile> {
  bool _isHovered = false;

  String _getTimeAgo(DateTime? date) {
    if (date == null) return 'Never viewed';
    final difference = DateTime.now().difference(date);
    if (difference.inDays >= 365) return 'Viewed ${(difference.inDays / 365).floor()}y ago';
    if (difference.inDays >= 30) return 'Viewed ${(difference.inDays / 30).floor()}mo ago';
    if (difference.inDays >= 1) return 'Viewed ${difference.inDays}d ago';
    if (difference.inHours >= 1) return 'Viewed ${difference.inHours}h ago';
    if (difference.inMinutes >= 1) return 'Viewed ${difference.inMinutes}m ago';
    return 'Viewed just now';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final repo = ref.read(storageNodeRepositoryProvider);
    final path = repo.buildPath(widget.item);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.00,
        duration: const Duration(milliseconds: 150),
        child: Semantics(
          label: 'Activity item ${widget.item.name}',
          button: true,
          child: Tooltip(
            message: 'View details for ${widget.item.name}',
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: _isHovered ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark 
                      ? theme.colorScheme.outline.withOpacity(0.2) 
                      : const Color(0xFFF8D7E3).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () => context.push('/node/${widget.item.uuid}'),
                borderRadius: BorderRadius.circular(16),
                hoverColor: const Color(0xFFD10047).withOpacity(0.02),
                splashColor: const Color(0xFFD10047).withOpacity(0.08),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD10047).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xFFD10047),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (path.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark 
                                          ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5) 
                                          : const Color(0xFFFFF5F8),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDark 
                                            ? theme.colorScheme.outline.withOpacity(0.1) 
                                            : const Color(0xFFF8D7E3).withOpacity(0.6),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      path,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? theme.colorScheme.onSurface : const Color(0xFF374151),
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark 
                                        ? theme.colorScheme.surfaceContainer.withOpacity(0.8) 
                                        : const Color(0xFFECEFF1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark ? theme.colorScheme.outline.withOpacity(0.1) : const Color(0xFFCFD8DC),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    _getTimeAgo(widget.item.viewedAt),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}