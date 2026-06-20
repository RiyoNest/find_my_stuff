import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

class PhotoViewerPage extends StatelessWidget {
  final String imagePath;
  final String itemUuid;
  final String itemName;

  const PhotoViewerPage({
    super.key,
    required this.imagePath,
    required this.itemUuid,
    required this.itemName,
  });

  @override
  Widget build(BuildContext context) {
    final imageFile = File(imagePath);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Photo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Open Item',
            onPressed: () {
              context.push('/node/$itemUuid');
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Photo',
            onPressed: () async {
              if (!imageFile.existsSync()) {
                return;
              }

              await Share.shareXFiles([
                XFile(imagePath),
              ]);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5,
                child: Hero(
                  tag: imagePath,
                  child: imageFile.existsSync()
                      ? Image.file(
                    imageFile,
                    fit: BoxFit.contain,
                  )
                      : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 80,
                        color: Colors.white,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Image not found',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Text(
              itemName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}