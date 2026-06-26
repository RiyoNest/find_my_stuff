import 'package:flutter/material.dart';
import 'view_options_sheet.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < segments.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
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
          ),
          const SizedBox(width: 8),
          Semantics(
            label: 'Display settings options',
            button: true,
            child: Tooltip(
              message: 'View options settings',
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Color(0xFFD10047)),
                  onPressed: () => ViewOptionsSheet.show(context),
                  hoverColor: const Color(0xFFD10047).withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreadcrumbChip extends StatefulWidget {
  final BreadcrumbSegment segment;
  final bool isCurrent;
  final ThemeData theme;

  const _BreadcrumbChip({
    required this.segment,
    required this.isCurrent,
    required this.theme,
  });

  @override
  State<_BreadcrumbChip> createState() => _BreadcrumbChipState();
}

class _BreadcrumbChipState extends State<_BreadcrumbChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.brightness == Brightness.dark;
    final canTap = !widget.isCurrent && widget.segment.onTap != null;

    final Color bgColor = widget.isCurrent
        ? const Color(0xFFD10047)
        : (isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6) : const Color(0xFFFFF5F8));
    final Color textColor = widget.isCurrent
        ? Colors.white
        : (isDark ? theme.colorScheme.onSurface : const Color(0xFF374151));
    final Color borderColor = widget.isCurrent
        ? Colors.transparent
        : (isDark ? theme.colorScheme.outline.withValues(alpha: 0.3) : const Color(0xFFF8D7E3));

    // Dynamic icon resolution
    IconData? icon = widget.segment.icon;
    if (icon == null && widget.segment.isHome) {
      icon = Icons.home_rounded;
    }

    final rowContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 16,
            color: textColor,
          ),
          if (!widget.segment.isHome) const SizedBox(width: 4),
        ],
        if (!widget.segment.isHome)
          Text(
            widget.segment.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: widget.isCurrent ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
      ],
    );

    final baseDecoration = BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor),
    );

    Widget chipContent;
    if (!canTap) {
      chipContent = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: baseDecoration,
        child: rowContent,
      );
    } else {
      chipContent = Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.segment.onTap,
          onHover: (hovering) {
            setState(() {
              _isHovered = hovering;
            });
          },
          mouseCursor: SystemMouseCursors.click,
          splashColor: const Color(0xFFD10047).withValues(alpha: 0.12),
          hoverColor: const Color(0xFFFCE4EC).withValues(alpha: isDark ? 0.15 : 1.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: rowContent,
          ),
        ),
      );
    }

    return MouseRegion(
      child: AnimatedScale(
        scale: _isHovered && canTap ? 1.05 : 1.00,
        duration: const Duration(milliseconds: 150),
        child: Semantics(
          label: widget.segment.isHome ? 'Home Breadcrumb navigation' : '${widget.segment.label} navigation',
          button: canTap,
          child: Tooltip(
            message: canTap ? 'Go back to ${widget.segment.label}' : widget.segment.label,
            child: chipContent,
          ),
        ),
      ),
    );
  }
}