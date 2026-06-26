import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:flutter/material.dart';

class DashboardStatCard extends StatefulWidget {
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
  State<DashboardStatCard> createState() => _DashboardStatCardState();
}

class _DashboardStatCardState extends State<DashboardStatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine Gradient & Emoji icon based on Title name
    List<Color> gradientColors;
    String emoji;
    String tooltipMsg;

    switch (widget.title.toLowerCase().trim()) {
      case 'items':
        emoji = '📦';
        tooltipMsg = 'View all stored items';
        gradientColors = isDark
            ? [const Color(0xFF4C0519), const Color(0xFF2D020D)] // Rose tint
            : [const Color(0xFFFFF1F2), const Color(0xFFFFE4E6)];
        break;
      case 'important':
        emoji = '⭐';
        tooltipMsg = 'View important starred items';
        gradientColors = isDark
            ? [const Color(0xFF422006), const Color(0xFF2D1500)] // Amber tint
            : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)];
        break;
      case 'photos':
        emoji = '📸';
        tooltipMsg = 'View items with photos';
        gradientColors = isDark
            ? [const Color(0xFF064E3B), const Color(0xFF022F22)] // Teal tint
            : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)];
        break;
      case 'archived':
      case 'archive':
        emoji = '🗄️';
        tooltipMsg = 'View archived items';
        gradientColors = isDark
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] // Slate tint
            : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)];
        break;
      default:
        emoji = 'ℹ️';
        tooltipMsg = 'View ${widget.title}';
        gradientColors = isDark
            ? [theme.colorScheme.surfaceContainerHigh, theme.colorScheme.surfaceContainerLow]
            : [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)];
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.00,
        duration: const Duration(milliseconds: 180),
        child: Semantics(
          label: '${widget.title} Statistics card',
          value: widget.value,
          button: widget.onTap != null,
          child: Tooltip(
            message: tooltipMsg,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(RAppRadius.lg),
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                    blurRadius: _isHovered ? 12 : 6,
                    offset: Offset(0, _isHovered ? 6 : 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(RAppRadius.lg),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: widget.onTap,
                  hoverColor: Colors.black.withOpacity(0.02),
                  splashColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.value,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.title,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
}