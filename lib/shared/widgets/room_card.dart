// File: lib/shared/widgets/room_card.dart
//
// CHANGES: Full gradient background (rotating palette via
// RAppGradients.roomGradient(index)) with white text + house emoji
// as the "colored image" focal point. Takes an index param so each
// room card in the horizontal row picks a distinct color automatically.

import 'package:find_my_stuff/core/constants/app_gradients.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:find_my_stuff/shared/entities/room_entity.dart';
import 'package:flutter/material.dart';

class RoomCard extends StatelessWidget {
  final RoomEntity room;
  final int index;
  final VoidCallback onTap;

  const RoomCard({
    super.key,
    required this.room,
    required this.index,
    required this.onTap,
  });

  // Room emojis rotate alongside the gradient palette for extra personality.
  static const List<String> _roomEmojis = ['🏠', '🛋️', '🛏️', '🍳', '📚', '🪴'];
  static const List<String> _roomLabels = [
    'Living', 'Lounge', 'Bedroom', 'Kitchen', 'Study', 'Garden',
  ];

  @override
  Widget build(BuildContext context) {
    final gradient = RAppGradients.roomGradient(index);
    final emoji = _roomEmojis[index % _roomEmojis.length];

    return InkWell(
      borderRadius: BorderRadius.circular(RAppRadius.lg),
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(RAppSpacing.md),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(RAppRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Decorative circle — top right
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emoji as the "colored image"
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: RAppSpacing.sm + 4),
                Text(
                  room.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}