// File: lib/shared/widgets/room_card.dart

import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:find_my_stuff/shared/entities/room_entity.dart';
import 'package:flutter/material.dart';

class RoomCard extends StatelessWidget {
  final RoomEntity room;
  final VoidCallback onTap;

  const RoomCard({super.key, required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roomName = room.name.toLowerCase().trim();

    // Default Visual Style (Hall/Default)
    Color bgColor = const Color(0xFFFFF5F8);
    Color iconColor = const Color(0xFFD10047);
    Color borderColor = const Color(0xFFF8D7E3);
    IconData icon = Icons.meeting_room_rounded;

    if (roomName.contains('bedroom') || roomName.contains('bed room') || roomName.contains('bed')) {
      bgColor = const Color(0xFFFFF0F2);
      iconColor = const Color(0xFFD10047);
      borderColor = const Color(0xFFF8D7E3);
      icon = Icons.bed_rounded;
    } else if (roomName.contains('kitchen') || roomName.contains('cook')) {
      bgColor = const Color(0xFFFFF8E1);
      iconColor = const Color(0xFFE65100);
      borderColor = const Color(0xFFFFE082);
      icon = Icons.kitchen_rounded;
    } else if (roomName.contains('garage') || roomName.contains('car')) {
      bgColor = const Color(0xFFECEFF1);
      iconColor = const Color(0xFF455A64);
      borderColor = const Color(0xFFCFD8DC);
      icon = Icons.garage_rounded;
    } else if (roomName.contains('office') || roomName.contains('study') || roomName.contains('desk') || roomName.contains('work')) {
      bgColor = const Color(0xFFE8F5E9);
      iconColor = const Color(0xFF2E7D32);
      borderColor = const Color(0xFFC8E6C9);
      icon = Icons.desktop_windows_rounded;
    } else if (roomName.contains('bathroom') || roomName.contains('bath') || roomName.contains('toilet') || roomName.contains('wash') || roomName.contains('shower')) {
      bgColor = const Color(0xFFE0F7FA);
      iconColor = const Color(0xFF00838F);
      borderColor = const Color(0xFFB2EBF2);
      icon = Icons.bathtub_rounded;
    } else if (roomName.contains('store') || roomName.contains('pantry') || roomName.contains('closet') || roomName.contains('wardrobe') || roomName.contains('utility')) {
      bgColor = const Color(0xFFEFEBE9);
      iconColor = const Color(0xFF5D4037);
      borderColor = const Color(0xFFD7CCC8);
      icon = Icons.inventory_2_rounded;
    } else if (roomName.contains('living') || roomName.contains('hall') || roomName.contains('lounge') || roomName.contains('sitting') || roomName.contains('tv')) {
      bgColor = const Color(0xFFEDE7F6);
      iconColor = const Color(0xFF651FFF);
      borderColor = const Color(0xFFD1C4E9);
      icon = Icons.chair_rounded;
    } else if (roomName.contains('dining')) {
      bgColor = const Color(0xFFF1F8E9);
      iconColor = const Color(0xFF33691E);
      borderColor = const Color(0xFFDCEDC8);
      icon = Icons.restaurant_rounded;
    } else if (roomName.contains('balcony') || roomName.contains('terrace') || roomName.contains('garden') || roomName.contains('yard')) {
      bgColor = const Color(0xFFE8F5E9);
      iconColor = const Color(0xFF1B5E20);
      borderColor = const Color(0xFFC8E6C9);
      icon = Icons.yard_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(RAppRadius.lg),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(RAppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(RAppRadius.lg),
          onTap: onTap,
          hoverColor: iconColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: RAppSpacing.sm + 6,
              vertical: RAppSpacing.sm + 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(RAppSpacing.sm),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(height: RAppSpacing.sm + 6),
                Text(
                  room.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: RAppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}