import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';
import 'package:find_my_stuff/shared/entities/room_entity.dart';

class RoomCard extends StatefulWidget {
  final RoomEntity room;
  final int itemCount;
  final int containerCount;
  final VoidCallback onTap;

  const RoomCard({
    super.key,
    required this.room,
    required this.itemCount,
    required this.containerCount,
    required this.onTap,
  });

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final roomName = widget.room.name.toLowerCase().trim();

    // Default Visual Style (Hall/Default)
    Color bgColor = isDark ? const Color(0xFF2C1E23) : const Color(0xFFFFF5F8);
    Color tintColor = const Color(0xFFD10047);
    Color borderColor = isDark ? const Color(0xFF4C1E2B) : const Color(0xFFF8D7E3);
    String emoji = '🚪';

    // Parse room type heuristics for premium styling
    if (roomName.contains('bedroom') || roomName.contains('bed room') || roomName.contains('bed')) {
      bgColor = isDark ? const Color(0xFF3B1E22) : const Color(0xFFFFF0F2);
      tintColor = const Color(0xFFD10047);
      borderColor = isDark ? const Color(0xFF5A1E26) : const Color(0xFFF8D7E3);
      emoji = '🛏️';
    } else if (roomName.contains('kitchen') || roomName.contains('cook')) {
      bgColor = isDark ? const Color(0xFF3E2C1A) : const Color(0xFFFFF8E1);
      tintColor = const Color(0xFFE65100);
      borderColor = isDark ? const Color(0xFF5C3F24) : const Color(0xFFFFE082);
      emoji = '🍳';
    } else if (roomName.contains('garage') || roomName.contains('car')) {
      bgColor = isDark ? const Color(0xFF263238) : const Color(0xFFECEFF1);
      tintColor = const Color(0xFF455A64);
      borderColor = isDark ? const Color(0xFF37474F) : const Color(0xFFCFD8DC);
      emoji = '🚗';
    } else if (roomName.contains('office') || roomName.contains('study') || roomName.contains('desk') || roomName.contains('work')) {
      bgColor = isDark ? const Color(0xFF1E3A20) : const Color(0xFFE8F5E9);
      tintColor = const Color(0xFF2E7D32);
      borderColor = isDark ? const Color(0xFF2E5E32) : const Color(0xFFC8E6C9);
      emoji = '💻';
    } else if (roomName.contains('bathroom') || roomName.contains('bath') || roomName.contains('toilet') || roomName.contains('wash') || roomName.contains('shower')) {
      bgColor = isDark ? const Color(0xFF113D40) : const Color(0xFFE0F7FA);
      tintColor = const Color(0xFF00838F);
      borderColor = isDark ? const Color(0xFF1F5E63) : const Color(0xFFB2EBF2);
      emoji = '🚿';
    } else if (roomName.contains('store') || roomName.contains('pantry') || roomName.contains('closet') || roomName.contains('wardrobe') || roomName.contains('utility')) {
      bgColor = isDark ? const Color(0xFF2E2421) : const Color(0xFFEFEBE9);
      tintColor = const Color(0xFF5D4037);
      borderColor = isDark ? const Color(0xFF4A3B37) : const Color(0xFFD7CCC8);
      emoji = '📦';
    } else if (roomName.contains('living') || roomName.contains('hall') || roomName.contains('lounge') || roomName.contains('sitting') || roomName.contains('tv')) {
      bgColor = isDark ? const Color(0xFF221A30) : const Color(0xFFEDE7F6);
      tintColor = const Color(0xFF651FFF);
      borderColor = isDark ? const Color(0xFF382A52) : const Color(0xFFD1C4E9);
      emoji = '🛋️';
    } else if (roomName.contains('dining')) {
      bgColor = isDark ? const Color(0xFF23301D) : const Color(0xFFF1F8E9);
      tintColor = const Color(0xFF33691E);
      borderColor = isDark ? const Color(0xFF374D2E) : const Color(0xFFDCEDC8);
      emoji = '🍽️';
    } else if (roomName.contains('balcony') || roomName.contains('terrace') || roomName.contains('garden') || roomName.contains('yard')) {
      bgColor = isDark ? const Color(0xFF1B331E) : const Color(0xFFE8F5E9);
      tintColor = const Color(0xFF1B5E20);
      borderColor = isDark ? const Color(0xFF2A4D2E) : const Color(0xFFC8E6C9);
      emoji = '🏡';
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.00,
        duration: const Duration(milliseconds: 180),
        child: Semantics(
          label: '${widget.room.name} room card',
          button: true,
          child: Tooltip(
            message: 'View details of ${widget.room.name}',
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: context.borderRadiusL,
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                    blurRadius: _isHovered ? 10 : 5,
                    offset: Offset(0, _isHovered ? 5 : 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: context.borderRadiusL,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  borderRadius: context.borderRadiusL,
                  onTap: widget.onTap,
                  hoverColor: tintColor.withOpacity(0.04),
                  splashColor: tintColor.withOpacity(0.1),
                  child: Padding(
                    padding: context.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              emoji,
                              style: TextStyle(fontSize: context.iconLarge),
                            ),
                            // Metadata Chips row
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildBadgeChip(context, '📦', widget.itemCount, isDark, theme),
                                SizedBox(width: context.spacingXS),
                                _buildBadgeChip(context, '🗂', widget.containerCount, isDark, theme),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: context.spacingM),
                        AutoSizeText(
                          widget.room.name,
                          maxLines: 1,
                          minFontSize: 12,
                          overflow: TextOverflow.ellipsis,
                          style: context.titleStyle.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeChip(BuildContext context, String icon, int count, bool isDark, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.spacingXS + 2, vertical: context.spacingXS),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.4) : Colors.white.withOpacity(0.8),
        borderRadius: context.borderRadiusS,
        border: Border.all(
          color: isDark ? theme.colorScheme.outline.withOpacity(0.2) : const Color(0xFFECEFF1),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: TextStyle(fontSize: context.iconSmall - 6),
          ),
          SizedBox(width: context.spacingXS / 2),
          Text(
            '$count',
            style: context.labelStyle.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}