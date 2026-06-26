import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
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
        title: Text(widget.title),
        actions: widget.appBarActions,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface,
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
                child: Semantics(
                  label: 'Search bar',
                  textField: true,
                  child: TextField(
                    controller: _searchController,
                    onChanged: widget.onSearchChanged,
                    cursorColor: const Color(0xFFD10047),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.searchHintText ?? 'Search...',
                      hintStyle: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
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
                          const SizedBox(width: 4),
                        ],
                      ),
                      filled: true,
                      fillColor: isDark
                          ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.4)
                          : const Color(0xFFFFF5F8),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: isDark ? theme.colorScheme.outline.withOpacity(0.4) : const Color(0xFFF8D7E3),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: isDark ? theme.colorScheme.outline.withOpacity(0.4) : const Color(0xFFF8D7E3),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFFD10047), width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),

            // Visual feedback for listening state
            if (_isListening)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.record_voice_over_rounded,
                      color: Color(0xFFD10047),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Listening...',
                      style: theme.textTheme.bodyMedium?.copyWith(
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
