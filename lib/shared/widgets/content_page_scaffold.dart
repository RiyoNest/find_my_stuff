import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';
import 'location_breadcrumb.dart';
import 'voice_search_sheet.dart';

class ContentPageScaffold extends StatefulWidget {
  final String title;
  final List<Widget>? appBarActions;
  final String? searchHintText;
  final ValueChanged<String>? onSearchChanged;
  final String initialSearchQuery;
  final List<BreadcrumbSegment> breadcrumbs;
  final Widget child;
  final Widget? floatingActionButton;

  const ContentPageScaffold({
    super.key,
    required this.title,
    this.appBarActions,
    this.searchHintText,
    this.onSearchChanged,
    this.initialSearchQuery = '',
    this.breadcrumbs = const [],
    required this.child,
    this.floatingActionButton,
  });

  @override
  State<ContentPageScaffold> createState() => _ContentPageScaffoldState();
}

class _ContentPageScaffoldState extends State<ContentPageScaffold> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchQuery);
  }

  @override
  void didUpdateWidget(covariant ContentPageScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSearchQuery != widget.initialSearchQuery &&
        _searchController.text != widget.initialSearchQuery) {
      _searchController.text = widget.initialSearchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showVoiceSearch() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceSearchSheet(),
    );

    if (result != null) {
      final trimmed = result.trim();
      if (trimmed.isNotEmpty) {
        _searchController.text = trimmed;
        widget.onSearchChanged?.call(trimmed);
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: AutoSizeText(
          widget.title,
          maxLines: 1,
          minFontSize: 14,
          overflow: TextOverflow.ellipsis,
          style: context.titleStyle.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: widget.appBarActions,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      floatingActionButton: widget.floatingActionButton,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar Section
            if (widget.onSearchChanged != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.spacingM,
                  context.spacingS,
                  context.spacingM,
                  context.spacingS + 4,
                ),
                child: Semantics(
                  label: 'Search bar',
                  textField: true,
                  child: TextField(
                    controller: _searchController,
                    onChanged: widget.onSearchChanged,
                    cursorColor: const Color(0xFFD10047),
                    style: context.bodyStyle.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.searchHintText ?? 'Search...',
                      hintStyle: context.bodyStyle.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFFD10047),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              tooltip: 'Clear search text',
                              icon: Icon(
                                Icons.clear_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                widget.onSearchChanged!('');
                                setState(() {});
                              },
                            ),
                          Semantics(
                            label: 'Voice Search',
                            button: true,
                            child: Tooltip(
                              message: 'Speech input search',
                              child: IconButton(
                                icon: Icon(
                                  Icons.mic_none_rounded,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                onPressed: _showVoiceSearch,
                              ),
                            ),
                          ),
                          SizedBox(width: context.spacingXS),
                        ],
                      ),
                      filled: true,
                      fillColor: isDark
                          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                          : const Color(0xFFFFF5F8),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: context.spacingM,
                        vertical: context.spacingS + 4,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: context.borderRadiusPill,
                        borderSide: BorderSide(
                          color: isDark ? theme.colorScheme.outline.withValues(alpha: 0.4) : const Color(0xFFF8D7E3),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: context.borderRadiusPill,
                        borderSide: BorderSide(
                          color: isDark ? theme.colorScheme.outline.withValues(alpha: 0.4) : const Color(0xFFF8D7E3),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: context.borderRadiusPill,
                        borderSide: const BorderSide(color: Color(0xFFD10047), width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),

            // Breadcrumb Section
            if (widget.breadcrumbs.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(context.spacingM, 0, context.spacingM, context.spacingS + 4),
                child: LocationBreadcrumb(segments: widget.breadcrumbs),
              ),

            // Main Content Area
            Expanded(
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}
