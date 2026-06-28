import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';
import 'location_breadcrumb.dart';

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
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _speechInitialized = false;

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
    _speech.stop();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    if (_speechInitialized) return;
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
            }
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isListening = false);
          }
        },
      );
      _speechInitialized = true;
    } catch (e) {
      debugPrint('Speech init error: $e');
    }
  }

  Future<void> _toggleListening() async {
    await _initSpeech();
    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available')),
        );
      }
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        localeId: "en_IN",
        partialResults: true,
        listenFor: const Duration(minutes: 1),
        pauseFor: const Duration(seconds: 3),
        onResult: (result) {
          final words = result.recognizedWords;
          if (mounted) {
            setState(() {
              _searchController.text = words;
            });
            widget.onSearchChanged?.call(words);
          }
        },
      );
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
                              message: _isListening ? 'Stop voice recording' : 'Speech input search',
                              child: IconButton(
                                icon: Icon(
                                  _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                                  color: _isListening
                                      ? const Color(0xFFD10047)
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                onPressed: _toggleListening,
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

            // Visual feedback for listening state
            if (_isListening)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.spacingL, vertical: context.spacingXS),
                child: Row(
                  children: [
                    const Icon(
                      Icons.record_voice_over_rounded,
                      color: Color(0xFFD10047),
                      size: 18,
                    ),
                    SizedBox(width: context.spacingS),
                    Text(
                      'Listening...',
                      style: context.bodyStyle.copyWith(
                        color: const Color(0xFFD10047),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
