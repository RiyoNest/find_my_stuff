// File: lib/features/gallery/presentation/pages/photo_gallery_page.dart

import 'package:find_my_stuff/features/storage_tree/presentation/pages/photo_viewer_page.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:find_my_stuff/shared/widgets/safe_image_widget.dart';
import 'package:find_my_stuff/shared/widgets/location_breadcrumb.dart';
import 'package:find_my_stuff/shared/widgets/content_page_scaffold.dart';
import 'package:find_my_stuff/shared/widgets/empty_state_widget.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';

class PhotoGalleryPage extends ConsumerStatefulWidget {
  const PhotoGalleryPage({super.key});

  @override
  ConsumerState<PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends ConsumerState<PhotoGalleryPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsWithPhotosProvider);
    final repo = ref.read(storageNodeRepositoryProvider);
    final theme = Theme.of(context);

    final segments = [
      BreadcrumbSegment(
        label: 'Home',
        isHome: true,
        onTap: () => context.go('/'),
      ),
      const BreadcrumbSegment(
        label: 'Photos',
        icon: Icons.photo_library_outlined,
      ),
    ];

    return ContentPageScaffold(
      title: 'Photo Gallery',
      searchHintText: 'Search photos...',
      onSearchChanged: (val) {
        setState(() {
          _searchQuery = val;
        });
      },
      initialSearchQuery: _searchQuery,
      breadcrumbs: segments,
      child: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.photo_outlined,
              title: 'No photos available',
              description: 'Items with photos attached will show up here.',
            );
          }

          // Contextual search query filtering
          var filtered = items;
          if (_searchQuery.trim().isNotEmpty) {
            final query = _searchQuery.toLowerCase().trim();
            filtered = filtered.where((item) {
              final path = repo.buildPath(item).toLowerCase();
              return item.name.toLowerCase().contains(query) ||
                  (item.description?.toLowerCase().contains(query) ?? false) ||
                  path.contains(query);
            }).toList();
          }

          if (filtered.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.search_off_rounded,
              title: 'No results found',
              description: 'Try adjusting your search criteria.',
            );
          }

          final cols = context.columns;
          return GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingS),
            itemCount: filtered.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: context.spacingS + 4,
              crossAxisSpacing: context.spacingS + 4,
              childAspectRatio: context.photoCardAspectRatio,
            ),
            itemBuilder: (_, index) {
              final item = filtered[index];
              final path = repo.buildPath(item);

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PhotoViewerPage(
                        imagePath: item.photoPath!,
                        itemUuid: item.uuid,
                        itemName: item.name,
                      ),
                    ),
                  );
                },
                borderRadius: context.borderRadiusL,
                child: Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: context.borderRadiusL,
                    side: const BorderSide(color: Color(0xFFF8D7E3), width: 0.8),
                  ),
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.08),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Hero(
                          tag: item.photoPath!,
                          child: SafeImageWidget(
                            photoPath: item.photoPath,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: Container(
                              color: const Color(0xFFFFF5F8),
                              child: Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: context.iconLarge,
                                  color: const Color(0xFFD10047),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(context.spacingS + 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AutoSizeText(
                              item.name,
                              style: context.titleStyle.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              minFontSize: 11,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: context.spacingXS),
                            Text(
                              path.isNotEmpty ? path : 'No location path',
                              style: context.bodySmallStyle.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}