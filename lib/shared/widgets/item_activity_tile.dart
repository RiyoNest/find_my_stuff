import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';

class ItemActivityTile extends ConsumerStatefulWidget {
  final StorageNodeEntity item;
  final String? customTimeText;

  const ItemActivityTile({
    super.key,
    required this.item,
    this.customTimeText,
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
                borderRadius: context.borderRadiusL,
                side: BorderSide(
                  color: isDark 
                      ? theme.colorScheme.outline.withValues(alpha: 0.2) 
                      : const Color(0xFFF8D7E3).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () => context.push('/node/${widget.item.uuid}'),
                borderRadius: context.borderRadiusL,
                hoverColor: const Color(0xFFD10047).withValues(alpha: 0.02),
                splashColor: const Color(0xFFD10047).withValues(alpha: 0.08),
                child: Padding(
                  padding: context.cardPadding,
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD10047).withValues(alpha: 0.08),
                          borderRadius: context.borderRadiusM,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: const Color(0xFFD10047),
                            size: context.iconMedium,
                          ),
                        ),
                      ),
                      SizedBox(width: context.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoSizeText(
                              widget.item.name,
                              maxLines: 1,
                              minFontSize: 12,
                              overflow: TextOverflow.ellipsis,
                              style: context.titleStyle.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: context.spacingXS),
                            Wrap(
                              spacing: context.spacingS,
                              runSpacing: context.spacingXS,
                              children: [
                                if (path.isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.spacingS,
                                      vertical: context.spacingXS,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark 
                                          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) 
                                          : const Color(0xFFFFF5F8),
                                      borderRadius: context.borderRadiusS,
                                      border: Border.all(
                                        color: isDark 
                                            ? theme.colorScheme.outline.withValues(alpha: 0.1) 
                                            : const Color(0xFFF8D7E3).withValues(alpha: 0.6),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      path,
                                      style: context.captionStyle.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? theme.colorScheme.onSurface : const Color(0xFF374151),
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.spacingS,
                                    vertical: context.spacingXS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark 
                                        ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.8) 
                                        : const Color(0xFFECEFF1),
                                    borderRadius: context.borderRadiusS,
                                    border: Border.all(
                                      color: isDark ? theme.colorScheme.outline.withValues(alpha: 0.1) : const Color(0xFFCFD8DC),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    widget.customTimeText ?? _getTimeAgo(widget.item.viewedAt),
                                    style: context.captionStyle.copyWith(
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
                        size: context.iconMedium,
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