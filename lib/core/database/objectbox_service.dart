import 'package:path_provider/path_provider.dart';

import '../../objectbox.g.dart';

class ObjectBoxService {
  static late final Store store;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();

    store = await openStore(
      directory: '${dir.path}/find_my_stuff_db',
    );
  }
}