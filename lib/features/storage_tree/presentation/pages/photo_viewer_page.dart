import 'dart:io';

import 'package:flutter/material.dart';

class PhotoViewerPage extends StatelessWidget {
  final String imagePath;

  const PhotoViewerPage({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: Hero(
            tag: imagePath,
            child: Image.file(
              File(imagePath),
            ),
          ),
        ),
      ),
    );
  }
}