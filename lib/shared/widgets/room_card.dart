// File: lib/shared/widgets/room_card.dart
//
// Compact card used in the horizontally-scrolling "Rooms" row on the
// Home Screen. Replaces the old full-width ListTile rows so users can
// scan all rooms without a long vertical list. Radius matches the
// app's CardTheme convention (RAppRadius.lg).

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

    return InkWell(
      borderRadius: BorderRadius.circular(RAppRadius.lg),
      onTap: onTap,
      child: Container(
        width: 124,
        padding: const EdgeInsets.all(RAppSpacing.sm + 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(RAppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(RAppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.meeting_room_rounded,
                color: theme.colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(height: RAppSpacing.sm + 6),
            Text(
              room.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}