// File: lib/features/search/presentation/pages/search_page.dart

import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:find_my_stuff/shared/widgets/location_breadcrumb.dart';
import 'package:find_my_stuff/shared/providers/theme_provider.dart';
import 'package:find_my_stuff/shared/widgets/content_page_scaffold.dart';
import 'package:find_my_stuff/shared/widgets/empty_state_widget.dart';
import 'package:find_my_stuff/shared/enums/content_view_mode.dart';
import 'package:find_my_stuff/shared/providers/content_preferences_provider.dart';
import 'package:find_my_stuff/shared/widgets/safe_image_widget.dart';
import 'package:find_my_stuff/shared/providers/storage_path_provider.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';

import '../widgets/search_result_tile.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  String query = '';

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
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchProvider(query));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
      searchHintText: 'Search items...',
      onSearchChanged: (val) {
        setState(() {
          query = val;
        });
      },
      initialSearchQuery: query,
      breadcrumbs: segments,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.spacingM),
        child: resultsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => Center(
            child: Text(error.toString()),
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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Searches',
                            style: context.titleStyle.copyWith(
                              color: isDark ? theme.colorScheme.onSurfaceVariant : Colors.grey[600],
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
                      SizedBox(height: context.spacingS),
                      Wrap(
                        spacing: context.spacingS,
                        runSpacing: context.spacingS,
                        children: recentSearches.map((search) {
                          return ActionChip(
                            label: Text(search, style: context.labelStyle),
                            avatar: Icon(Icons.history_rounded, size: context.iconSmall, color: const Color(0xFFD10047)),
                            backgroundColor: isDark
                                ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.4)
                                : const Color(0xFFFFF5F8),
                            side: BorderSide(
                              color: isDark ? theme.colorScheme.outline.withOpacity(0.3) : const Color(0xFFF8D7E3),
                            ),
                            onPressed: () {
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

            // Grid View rendering
            if (prefs.viewMode == ContentViewMode.grid) {
              final cols = context.columns;
              return GridView.builder(
                padding: EdgeInsets.symmetric(vertical: context.spacingS),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: context.spacingS + 4,
                  crossAxisSpacing: context.spacingS + 4,
                  childAspectRatio: context.itemCardAspectRatio,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _ResponsiveSearchResultCard(
                    item: item,
                    onTap: () {
                      _saveSearchQuery(query);
                      context.push('/node/${item.uuid}');
                    },
                    isDark: isDark,
                    theme: theme,
                  );
                },
              );
            }

            // Default List View rendering
            return ListView.separated(
              padding: EdgeInsets.symmetric(vertical: context.spacingS),
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(height: context.spacingS),
              itemBuilder: (context, index) {
                final item = items[index];
                return SearchResultTile(
                  item: item,
                  onTap: () {
                    _saveSearchQuery(query);
                    context.push('/node/${item.uuid}');
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ResponsiveSearchResultCard extends StatefulWidget {
  final StorageNodeEntity item;
  final VoidCallback onTap;
  final bool isDark;
  final ThemeData theme;

  const _ResponsiveSearchResultCard({
    required this.item,
    required this.onTap,
    required this.isDark,
    required this.theme,
  });

  @override
  State<_ResponsiveSearchResultCard> createState() => _ResponsiveSearchResultCardState();
}

class _ResponsiveSearchResultCardState extends State<_ResponsiveSearchResultCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
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
          shadowColor: Colors.black.withOpacity(0.1),
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: context.borderRadiusL,
              side: BorderSide(
                color: widget.isDark
                    ? widget.theme.colorScheme.outline.withOpacity(0.3)
                    : const Color(0xFFF8D7E3),
                width: 0.8,
              ),
            ),
            child: InkWell(
              onTap: widget.onTap,
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
                            color: const Color(0xFFD10047),
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
                                  child: AutoSizeText(
                                    widget.item.name,
                                    style: context.titleStyle.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: widget.theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    minFontSize: 11,
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
                              loading: () => const Text('...', style: TextStyle(fontSize: 12)),
                              error: (_, __) => const SizedBox(),
                              data: (path) {
                                final text = path.map((e) => e.name).join(' > ');
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