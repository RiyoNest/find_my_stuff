import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/storage_path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:find_my_stuff/shared/widgets/safe_image_widget.dart';
import 'package:find_my_stuff/core/constants/app_colours.dart';

class SearchResultTile extends ConsumerWidget {
  final StorageNodeEntity item;
  final VoidCallback? onTap;

  const SearchResultTile({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathAsync = ref.watch(storagePathProvider(item.uuid));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? theme.colorScheme.outline.withOpacity(0.3) : const Color(0xFFF8D7E3),
          width: 0.6,
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else {
            context.push('/node/${item.uuid}');
          }
        },
        hoverColor: const Color(0xFFFFF5F8),
        leading: SizedBox(
          width: 44,
          height: 44,
          child: SafeImageWidget(
            photoPath: item.photoPath,
            borderRadius: BorderRadius.circular(8),
            placeholder: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFFD10047),
                size: 22,
              ),
            ),
          ),
        ),
        title: Text(
          item.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: pathAsync.when(
          loading: () => const Text('Loading path...'),
          error: (_, __) => const SizedBox(),
          data: (path) {
            final text = path.map((e) => e.name).join(' > ');
            return Text(
              text.isNotEmpty ? text : 'No location path',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: RAppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.isImportant)
              const Icon(
                Icons.star_rounded,
                color: Colors.amber,
                size: 20,
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}