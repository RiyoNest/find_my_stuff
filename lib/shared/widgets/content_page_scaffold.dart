import 'package:flutter/material.dart';
import 'location_breadcrumb.dart';
import '../../core/constants/app_colours.dart';

class ContentPageScaffold extends StatefulWidget {
  final String title;
  final List<Widget>? appBarActions;
  final String? searchHintText;
  final ValueChanged<String>? onSearchChanged;
  final String initialSearchQuery;
  final List<BreadcrumbSegment> breadcrumbs;
  final Widget? toolbar;
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
    this.toolbar,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.title),
        actions: widget.appBarActions,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: RAppColors.textPrimary),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: RAppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButton: widget.floatingActionButton,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar Section
            if (widget.onSearchChanged != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: widget.onSearchChanged,
                  cursorColor: const Color(0xFFD10047),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: RAppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.searchHintText ?? 'Search...',
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[500],
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFFD10047),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              if (widget.onSearchChanged != null) {
                                widget.onSearchChanged!('');
                              }
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFFFF5F8),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFFF8D7E3), width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFFF8D7E3), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFFD10047), width: 1.5),
                    ),
                  ),
                ),
              ),

            // Breadcrumb Section
            if (widget.breadcrumbs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: LocationBreadcrumb(segments: widget.breadcrumbs),
              ),

            // Sticky Toolbar Section
            if (widget.toolbar != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: widget.toolbar!,
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
