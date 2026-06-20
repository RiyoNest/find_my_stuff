import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  static Future<void> checkForUpdates() async {
    try {
      final updateInfo =
      await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (_) {}
  }
}