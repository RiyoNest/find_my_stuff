import 'dart:async';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/providers/storage_path_provider.dart';
import 'package:find_my_stuff/shared/providers/theme_provider.dart';
import 'package:find_my_stuff/shared/enums/content_view_mode.dart';
import 'package:find_my_stuff/shared/providers/content_preferences_provider.dart';
import 'package:find_my_stuff/shared/widgets/content_page_scaffold.dart';
import 'package:find_my_stuff/shared/widgets/location_breadcrumb.dart';
import 'package:find_my_stuff/shared/widgets/voice_search_sheet.dart';
import 'package:find_my_stuff/shared/widgets/safe_image_widget.dart';
import 'package:find_my_stuff/shared/widgets/custom_snackbar.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';
import 'package:find_my_stuff/features/storage_tree/presentation/pages/edit_item_page.dart';
import 'package:find_my_stuff/features/storage_tree/presentation/pages/move_node_page.dart';
import 'package:find_my_stuff/core/services/search_service.dart';
import 'package:find_my_stuff/features/search/presentation/widgets/search_result_tile.dart';
import 'package:find_my_stuff/features/search/presentation/widgets/highlighted_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Riverpod state definitions
final searchQueryProvider = StateProvider<String>((ref) => '');
final searchFilterProvider = StateProvider<SearchFilterOption>((ref) => SearchFilterOption.all);
final searchSortProvider = StateProvider<SearchSortOption>((ref) => SearchSortOption.newest);

final searchResultsProvider = Provider<List<StorageNodeEntity>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final filter = ref.watch(searchFilterProvider);
  final sortBy = ref.watch(searchSortProvider);
  
  // Watch search refresh to rerun search reactively
  ref.watch(storageRefreshProvider);
  
  final searchService = ref.watch(searchServiceProvider);
  return searchService.search(query: query, filter: filter, sortBy: sortBy);
});

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isFocused = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).state = val;
    });
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
        ref.read(searchQueryProvider.notifier).state = trimmed;
        _saveSearchQuery(trimmed);
        if (mounted) {
          setState(() {});
        }
      }
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
    setState(() {});
  }

  void _onArchive(StorageNodeEntity item) {
    try {
      final repo = ref.read(storageNodeRepositoryProvider);
      repo.archiveItem(item.uuid);
      ref.read(storageRefreshProvider.notifier).state++;
      if (mounted) {
        AppSnackBar.success(context, '"${item.name}" archived successfully');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed to archive item.');
      }
    }
  }

  Future<void> _onDelete(StorageNodeEntity item) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.radiusL),
        ),
        title: const Text('Delete Item'),
        content: Text(
          'Are you sure you want to permanently delete "${item.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(storageNodeRepositoryProvider);
      repo.delete(item.id);
      ref.read(storageRefreshProvider.notifier).state++;
      if (mounted) {
        AppSnackBar.success(context, '"${item.name}" deleted');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, "Couldn't delete item. Please try again.");
      }
    }
  }

  void _showQuickActions(BuildContext context, StorageNodeEntity item) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.radiusL)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  final q = ref.read(searchQueryProvider);
                  _saveSearchQuery(q);
                  context.push('/node/${item.uuid}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Item'),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditItemPage(node: item),
                    ),
                  );
                  ref.read(storageRefreshProvider.notifier).state++;
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_move_outlined),
                title: const Text('Move Item'),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MoveNodePage(node: item),
                    ),
                  );
                  ref.read(storageRefreshProvider.notifier).state++;
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('Archive Item'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _onArchive(item);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                title: Text('Delete Item', style: TextStyle(color: theme.colorScheme.error)),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _onDelete(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = ref.watch(contentPreferencesProvider);

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
      child: Column(
        children: [
          // Section 1: Premium Search Bar
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.pagePadding.left,
              context.spacingS,
              context.pagePadding.right,
              context.spacingS + 4,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.radiusM),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
              child: Semantics(
                label: 'Search items, locations or notes input field',
                textField: true,
                child: TextField(
                  focusNode: _focusNode,
                  controller: _searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  onSubmitted: (val) {
                    _saveSearchQuery(val);
                  },
                  cursorColor: theme.colorScheme.primary,
                  style: context.bodyStyle.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search items, locations or notes...',
                    hintStyle: context.bodyStyle.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: theme.colorScheme.primary,
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
                              ref.read(searchQueryProvider.notifier).state = '';
                              setState(() {});
                            },
                          ),
                        Semantics(
                          label: 'Voice Search',
                          button: true,
                          child: Tooltip(
                            message: 'Speech input search',
                            child: IconButton(
                              icon: const Icon(Icons.mic_none_rounded),
                              onPressed: _showVoiceSearch,
                            ),
                          ),
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.radiusM),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.radiusM),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Horizontal Filters and Sorting row
          _buildFilterAndSortRow(context),

          const SizedBox(height: 8),

          // Results container
          Expanded(
            child: _buildSearchContent(context, prefs),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSortRow(BuildContext context) {
    final theme = Theme.of(context);
    final activeFilter = ref.watch(searchFilterProvider);

    final filters = [
      (SearchFilterOption.all, 'All'),
      (SearchFilterOption.important, 'Important'),
      (SearchFilterOption.forgotten, 'Forgotten'),
      (SearchFilterOption.expiring, 'Expiring'),
      (SearchFilterOption.hasPhotos, 'Has Photos'),
      (SearchFilterOption.archived, 'Archived'),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacingM),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((f) {
                  final isSelected = activeFilter == f.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(f.$2),
                      selected: isSelected,
                      selectedColor: theme.colorScheme.primaryContainer,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(searchFilterProvider.notifier).state = f.$1;
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<SearchSortOption>(
            icon: Icon(Icons.sort_rounded, color: theme.colorScheme.primary),
            tooltip: 'Sort items',
            onSelected: (sortOption) {
              ref.read(searchSortProvider.notifier).state = sortOption;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SearchSortOption.newest,
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 16),
                    SizedBox(width: 8),
                    Text('Newest Added'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SearchSortOption.oldest,
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward, size: 16),
                    SizedBox(width: 8),
                    Text('Oldest Added'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SearchSortOption.alphabetical,
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 16),
                    SizedBox(width: 8),
                    Text('Alphabetical'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SearchSortOption.recentlyUpdated,
                child: Row(
                  children: [
                    Icon(Icons.update, size: 16),
                    SizedBox(width: 8),
                    Text('Recently Updated'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SearchSortOption.location,
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Location path'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchContent(BuildContext context, ContentPreferences prefs) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final queryText = ref.watch(searchQueryProvider);

    if (queryText.isEmpty) {
      final recentSearches = ref.watch(sharedPreferencesProvider).getStringList('pref_recent_searches') ?? [];

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: context.spacingM),
        child: Align(
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 2: Recent Searches
                if (recentSearches.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Searches',
                        style: context.titleStyle.copyWith(
                          color: isDark ? theme.colorScheme.onSurfaceVariant : Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(sharedPreferencesProvider).remove('pref_recent_searches');
                          setState(() {});
                        },
                        child: const Text(
                          'Clear History',
                          style: TextStyle(color: Color(0xFFD10047), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.spacingXS),
                  Wrap(
                    spacing: context.spacingS,
                    runSpacing: context.spacingS,
                    children: recentSearches.map((search) {
                      return ActionChip(
                        label: Text(search, style: context.labelStyle),
                        avatar: Icon(
                          Icons.history_rounded,
                          size: context.iconSmall,
                          color: theme.colorScheme.primary,
                        ),
                        backgroundColor: isDark
                            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                            : const Color(0xFFFFF5F8),
                        side: BorderSide(
                          color: isDark ? theme.colorScheme.outline.withValues(alpha: 0.3) : const Color(0xFFF8D7E3),
                        ),
                        onPressed: () {
                          _searchController.text = search;
                          ref.read(searchQueryProvider.notifier).state = search;
                          _saveSearchQuery(search);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Section 3: Suggested Searches
                Text(
                  'Suggested Shortcuts',
                  style: context.titleStyle.copyWith(
                    color: isDark ? theme.colorScheme.onSurfaceVariant : Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSuggestionChip('⭐ Important Items', () {
                      ref.read(searchFilterProvider.notifier).state = SearchFilterOption.important;
                    }),
                    _buildSuggestionChip('🕒 Forgotten Items', () {
                      ref.read(searchFilterProvider.notifier).state = SearchFilterOption.forgotten;
                    }),
                    _buildSuggestionChip('⏰ Expiring Soon', () {
                      ref.read(searchFilterProvider.notifier).state = SearchFilterOption.expiring;
                    }),
                    _buildSuggestionChip('📷 Has Photos', () {
                      ref.read(searchFilterProvider.notifier).state = SearchFilterOption.hasPhotos;
                    }),
                    _buildSuggestionChip('🆕 Recently Added', () {
                      ref.read(searchFilterProvider.notifier).state = SearchFilterOption.all;
                      ref.read(searchSortProvider.notifier).state = SearchSortOption.newest;
                    }),
                    _buildSuggestionChip('🔄 Recently Updated', () {
                      ref.read(searchFilterProvider.notifier).state = SearchFilterOption.all;
                      ref.read(searchSortProvider.notifier).state = SearchSortOption.recentlyUpdated;
                    }),
                  ],
                ),
                const SizedBox(height: 40),

                // Helpful Center Illustration/Text
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 64,
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Start Typing to Search',
                        style: context.titleStyle.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Matches name, notes, locations or tags.',
                        style: context.bodySmallStyle.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final resultsAsync = ref.watch(searchResultsProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacingM),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: resultsAsync.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nothing found',
                      style: context.titleStyle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Try another keyword or browse your inventory.',
                      style: context.bodySmallStyle.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                        setState(() {});
                      },
                      child: const Text('Clear Search'),
                    ),
                  ],
                ),
              )
            : (prefs.viewMode == ContentViewMode.grid
                ? GridView.builder(
                    padding: EdgeInsets.symmetric(vertical: context.spacingS),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: context.columns,
                      mainAxisSpacing: context.spacingS + 4,
                      crossAxisSpacing: context.spacingS + 4,
                      childAspectRatio: context.itemCardAspectRatio,
                    ),
                    itemCount: resultsAsync.length,
                    itemBuilder: (context, index) {
                      final item = resultsAsync[index];
                      return _ResponsiveSearchResultCard(
                        item: item,
                        searchQuery: queryText,
                        onTap: () {
                          _saveSearchQuery(queryText);
                          context.push('/node/${item.uuid}');
                        },
                        onLongPress: () => _showQuickActions(context, item),
                        theme: theme,
                      );
                    },
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(vertical: context.spacingS),
                    itemCount: resultsAsync.length,
                    separatorBuilder: (_, _) => SizedBox(height: context.spacingS),
                    itemBuilder: (context, index) {
                      final item = resultsAsync[index];
                      return SearchResultTile(
                        item: item,
                        searchQuery: queryText,
                        onTap: () {
                          _saveSearchQuery(queryText);
                          context.push('/node/${item.uuid}');
                        },
                        onLongPress: () => _showQuickActions(context, item),
                      );
                    },
                  )),
      ),
    );
  }

  Widget _buildSuggestionChip(String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ActionChip(
      label: Text(label, style: context.labelStyle),
      backgroundColor: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
      side: BorderSide(color: theme.colorScheme.outlineVariant),
      onPressed: onTap,
    );
  }
}

class _ResponsiveSearchResultCard extends StatefulWidget {
  final StorageNodeEntity item;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ThemeData theme;

  const _ResponsiveSearchResultCard({
    required this.item,
    required this.searchQuery,
    required this.onTap,
    required this.onLongPress,
    required this.theme,
  });

  @override
  State<_ResponsiveSearchResultCard> createState() => _ResponsiveSearchResultCardState();
}

class _ResponsiveSearchResultCardState extends State<_ResponsiveSearchResultCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.theme.brightness == Brightness.dark;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.00,
        duration: const Duration(milliseconds: 150),
        child: AnimatedPhysicalModel(
          duration: const Duration(milliseconds: 150),
          shape: BoxShape.rectangle,
          borderRadius: context.borderRadiusL,
          elevation: _isHovered ? 4 : 2,
          color: widget.theme.cardColor,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: context.borderRadiusL,
              side: BorderSide(
                color: isDark
                    ? widget.theme.colorScheme.outline.withValues(alpha: 0.3)
                    : const Color(0xFFF8D7E3),
                width: 0.8,
              ),
            ),
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              hoverColor: const Color(0xFFFFF5F8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SafeImageWidget(
                      photoPath: widget.item.photoPath,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        color: const Color(0xFFFFF5F8),
                        child: Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: widget.theme.colorScheme.primary,
                            size: context.iconLarge,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(context.spacingS + 2),
                    child: Consumer(
                      builder: (context, ref, child) {
                        final pathAsync = ref.watch(storagePathProvider(widget.item.uuid));
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: HighlightedText(
                                    text: widget.item.name,
                                    highlight: widget.searchQuery,
                                    style: context.titleStyle.copyWith(
                                      color: widget.theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.item.isImportant)
                                  Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: context.iconSmall,
                                  ),
                              ],
                            ),
                            SizedBox(height: context.spacingXS),
                            pathAsync.when(
                              loading: () => Text('...', style: context.bodySmallStyle),
                              error: (_, _) => const SizedBox(),
                              data: (path) {
                                final text = path.displayString;
                                return Text(
                                  text.isNotEmpty ? text : 'No location path',
                                  style: context.bodySmallStyle.copyWith(
                                    color: widget.theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}