import 'dart:io';

import 'package:find_my_stuff/features/storage_tree/presentation/pages/photo_viewer_page.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:flutter/material.dart';

class PhotoGalleryPage extends StatelessWidget {
  final List<StorageNodeEntity> items;

  const PhotoGalleryPage({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Photos'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 80,
              ),
              SizedBox(height: 12),
              Text('No photos found'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Photos (${items.length})'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (_, index) {
          final item = items[index];

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
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Expanded(
                    child: Hero(
                      tag: item.photoPath!,
                      child: File(item.photoPath!).existsSync()
                          ? Image.file(
                        File(item.photoPath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                          : const Icon(
                        Icons.broken_image,
                        size: 50,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}