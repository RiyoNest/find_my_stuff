// File: lib/shared/widgets/dashboard_stat_card.dart
//
// CHANGES from your version (fixing the overflow you hit):
//   - Card had Flutter's default margin (EdgeInsets.all(4) = 8px of
//     vertical height you weren't accounting for) — set to zero so the
//     card's actual rendered size matches what you'd expect from its
//     padding/content alone.
//   - `Text(title)` had no style, so it was inheriting an ambient
//     DefaultTextStyle that (after wiring RAppTextStyles into
//     ThemeData.textTheme) got bigger than before. Gave it an explicit
//     compact labelMedium style + maxLines so it can't silently grow.
//   - borderRadius now uses RAppRadius.lg to match CardTheme's actual
//     convention (was hardcoded 12, CardTheme uses 16).
//
// Note: the actual fix for the overflow you saw is in home_page.dart —
// the row containing these cards now sizes itself via IntrinsicHeight
// instead of a fixed pixel height, so it can never overflow again
// regardless of font scale. This file just tightens up the card itself.

import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:flutter/material.dart';

class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RAppRadius.lg),
      child: Card(
        margin: EdgeInsets.zero,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 26),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: theme.textTheme.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}