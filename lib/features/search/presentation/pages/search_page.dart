import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:go_router/go_router.dart';

import 'package:find_my_stuff/shared/widgets/custom_snackbar.dart';
import 'package:find_my_stuff/shared/widgets/location_breadcrumb.dart';
import 'package:find_my_stuff/shared/providers/theme_provider.dart';
import 'package:find_my_stuff/shared/widgets/content_page_scaffold.dart';
import 'package:find_my_stuff/shared/widgets/empty_state_widget.dart';
import 'package:find_my_stuff/core/constants/app_colours.dart';

import '../widgets/search_result_tile.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  String query = '';

  final TextEditingController _controller = TextEditingController();

  final SpeechToText _speech = SpeechToText();

  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        debugPrint('Speech Status: $status');

        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            setState(() {
              _isListening = false;
            });
          }
        }
      },
      onError: (error) {
        debugPrint('Speech Error: $error');

        if (mounted) {
          setState(() {
            _isListening = false;
          });
        }
      },
    );
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      AppSnackBar.warning(context, 'Speech recognition not available');
      return;
    }

    setState(() {
      _isListening = true;
    });

    await _speech.listen(
      localeId: "en_IN",
      partialResults: true,
      listenFor: const Duration(minutes: 1),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        final words = result.recognizedWords;

        if (!mounted) return;

        setState(() {
          query = words;

          _controller.value = TextEditingValue(
            text: words,
            selection: TextSelection.collapsed(
              offset: words.length,
            ),
          );
        });

        debugPrint('Recognized: $words');

        if (result.finalResult) {
          _stopListening();
          _saveSearchQuery(words);
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();

    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  void _saveSearchQuery(String searchWord) {
    final trimmed = searchWord.trim();
    if (trimmed.isEmpty) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final history = prefs.getStringList('pref_recent_searches') ?? [];

    history.remove(trimmed);
    history.insert(0, trimmed);

    if (history.length > 10) {
      history.removeLast();
    }

    prefs.setStringList('pref_recent_searches', history);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchProvider(query));
    final theme = Theme.of(context);

    final segments = [
      BreadcrumbSegment(
        label: 'Home',
        isHome: true,
        onTap: () => context.go('/'),
      ),
      const BreadcrumbSegment(
        label: 'Search',
        icon: Icons.search_rounded,
      ),
    ];

    return ContentPageScaffold(
      title: 'Search Items',
      breadcrumbs: segments,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              cursorColor: const Color(0xFFD10047),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: RAppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search items...',
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[500],
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFD10047),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isListening
                        ? Icons.mic_rounded
                        : Icons.mic_none_rounded,
                    color: _isListening
                        ? const Color(0xFFD10047)
                        : Colors.grey[600],
                  ),
                  onPressed: () {
                    if (_isListening) {
                      _stopListening();
                    } else {
                      _startListening();
                    }
                  },
                ),
                filled: true,
                fillColor: const Color(0xFFFFF5F8),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
              onSubmitted: (value) {
                _saveSearchQuery(value);
              },
            ),

            if (_isListening)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.mic_rounded,
                      color: Color(0xFFD10047),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Listening...',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFD10047),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            Expanded(
              child: resultsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),

                error: (error, stackTrace) => Center(
                  child: Text(
                    error.toString(),
                  ),
                ),

                data: (items) {
                  if (query.trim().isEmpty) {
                    final recentSearches = ref.watch(sharedPreferencesProvider).getStringList('pref_recent_searches') ?? [];
                    if (recentSearches.isEmpty) {
                      return const EmptyStateWidget(
                        icon: Icons.search_rounded,
                        title: 'Search Items',
                        description: 'Start typing or tap the microphone to begin.',
                      );
                    }
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Searches',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref.read(sharedPreferencesProvider).remove('pref_recent_searches');
                                  setState(() {});
                                },
                                child: const Text(
                                  'Clear',
                                  style: TextStyle(color: Color(0xFFD10047)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: recentSearches.map((search) {
                              return ActionChip(
                                label: Text(search),
                                avatar: const Icon(Icons.history_rounded, size: 16, color: Color(0xFFD10047)),
                                backgroundColor: const Color(0xFFFFF5F8),
                                side: const BorderSide(color: Color(0xFFF8D7E3)),
                                onPressed: () {
                                  _controller.text = search;
                                  setState(() {
                                    query = search;
                                  });
                                  _saveSearchQuery(search);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }

                  if (items.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.search_off_rounded,
                      title: 'No results found',
                      description: 'We couldn\'t find any items matching your query.',
                    );
                  }

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return SearchResultTile(
                        item: items[index],
                        onTap: () {
                          _saveSearchQuery(query);
                          context.push('/node/${items[index].uuid}');
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}