import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/storage_path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:find_my_stuff/shared/widgets/safe_image_widget.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';
import 'highlighted_text.dart';

class SearchResultTile extends ConsumerWidget {
  final StorageNodeEntity item;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const SearchResultTile({
    super.key,
    required this.item,
    required this.searchQuery,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathAsync = ref.watch(storagePathProvider(item.uuid));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasDescription = item.description != null && item.description!.trim().isNotEmpty;
    final hasTags = item.tags != null && item.tags!.trim().isNotEmpty;
    
    final tagsList = hasTags
        ? item.tags!
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList()
        : <String>[];

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final updatedText = 'Updated ${months[item.updatedAt.month - 1]} ${item.updatedAt.day}, ${item.updatedAt.year}';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: context.borderRadiusM,
        side: BorderSide(
          color: isDark ? theme.colorScheme.outline.withValues(alpha: 0.3) : const Color(0xFFF8D7E3),
          width: 0.6,
        ),
      ),
      child: InkWell(
        borderRadius: context.borderRadiusM,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.all(context.spacingM),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Thumbnail
              SizedBox(
                width: 70,
                height: 70,
                child: ClipRRect(
                  borderRadius: context.borderRadiusS,
                  child: SafeImageWidget(
                    photoPath: item.photoPath,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      color: isDark ? theme.colorScheme.surfaceContainerHighest : const Color(0xFFFFF5F8),
                      child: Center(
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Name and Breadcrumb
                    Row(
                      children: [
                        Expanded(
                          child: HighlightedText(
                            text: item.name,
                            highlight: searchQuery,
                            style: context.titleStyle.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Location Path Breadcrumbs
                    pathAsync.when(
                      loading: () => Text('Loading path...', style: context.bodySmallStyle),
                      error: (_, _) => const SizedBox(),
                      data: (path) {
                        final text = path.map((e) => e.name).join(' › ');
                        return Text(
                          text.isNotEmpty ? text : 'No location path',
                          style: context.bodySmallStyle.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),

                    // Optional Description Preview
                    if (hasDescription) ...[
                      const SizedBox(height: 6),
                      HighlightedText(
                        text: item.description!,
                        highlight: searchQuery,
                        maxLines: 2,
                        style: context.bodySmallStyle.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                    ],

                    // Optional Tags Preview
                    if (tagsList.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: tagsList.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
                              borderRadius: context.borderRadiusS,
                            ),
                            child: HighlightedText(
                              text: '#$tag',
                              highlight: searchQuery,
                              style: context.bodySmallStyle.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Badges row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // 1. Future Category Placeholder
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLowest,
                              borderRadius: context.borderRadiusS,
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.category_outlined, size: 10, color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  'Uncategorized',
                                  style: context.bodySmallStyle.copyWith(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),

                          // 2. Star/Important Badge
                          if (item.isImportant) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9E6),
                                borderRadius: context.borderRadiusS,
                                border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.5),
                                  width: 0.5,
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.star, size: 10, color: Colors.amber),
                                  SizedBox(width: 4),
                                  Text(
                                    'Important',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],

                          // 3. Expiry Badge
                          if (item.trackExpiry && item.expiryDate != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                                borderRadius: context.borderRadiusS,
                                border: Border.all(
                                  color: theme.colorScheme.error.withValues(alpha: 0.4),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.alarm_on_rounded, size: 10, color: theme.colorScheme.error),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Expiring soon',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],

                          // 4. Updated Date
                          Text(
                            updatedText,
                            style: context.bodySmallStyle.copyWith(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: context.iconMedium),
            ],
          ),
        ),
      ),
    );
  }
}