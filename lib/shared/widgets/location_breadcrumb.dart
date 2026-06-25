// File: lib/shared/widgets/location_breadcrumb.dart

import 'package:flutter/material.dart';

class BreadcrumbSegment {
  final String label;
  final VoidCallback? onTap; // null = current page (not tappable)
  final bool isHome;
  final IconData? icon;

  const BreadcrumbSegment({
    required this.label,
    this.onTap,
    this.isHome = false,
    this.icon,
  });
}

class LocationBreadcrumb extends StatelessWidget {
  final List<BreadcrumbSegment> segments;

  const LocationBreadcrumb({super.key, required this.segments});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < segments.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Color(0xFF374151),
                  ),
                ),
              _BreadcrumbChip(
                segment: segments[i],
                isCurrent: i == segments.length - 1,
                theme: theme,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BreadcrumbChip extends StatelessWidget {
  final BreadcrumbSegment segment;
  final bool isCurrent;
  final ThemeData theme;

  const _BreadcrumbChip({
    required this.segment,
    required this.isCurrent,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final canTap = !isCurrent && segment.onTap != null;

    final Color bgColor = isCurrent ? const Color(0xFFD10047) : const Color(0xFFFFF5F8);
    final Color textColor = isCurrent ? Colors.white : const Color(0xFF374151);
    final Color borderColor = isCurrent ? Colors.transparent : const Color(0xFFF8D7E3);

    // Dynamic icon resolution
    IconData? icon = segment.icon;
    if (icon == null && segment.isHome) {
      icon = Icons.home_rounded;
    }

    final rowContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          segment.label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: textColor,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );

    if (!canTap) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: rowContent,
      );
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: segment.onTap,
        mouseCursor: SystemMouseCursors.click,
        splashColor: const Color(0xFFD10047).withOpacity(0.12),
        hoverColor: const Color(0xFFFCE4EC),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: rowContent,
        ),
      ),
    );
  }
}