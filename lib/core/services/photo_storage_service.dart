import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class PhotoStorageService {
  static Future<String> savePhoto(
      String sourcePath,
      ) async {
    final appDir =
    await getApplicationDocumentsDirectory();

    final photoDir = Directory(
      '${appDir.path}/item_photos',
    );

    if (!photoDir.existsSync()) {
      photoDir.createSync(
        recursive: true,
      );
    }

    final extension =
    p.extension(sourcePath);

    final fileName =
        '${const Uuid().v4()}$extension';

    final destination =
        '${photoDir.path}/$fileName';

    final copiedFile =
    await File(sourcePath).copy(
      destination,
    );

    return copiedFile.path;
  }
}