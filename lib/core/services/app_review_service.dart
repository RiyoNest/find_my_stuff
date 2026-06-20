import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppReviewService {
  static const _openCountKey = 'app_open_count';

  static Future<void> trackAppOpen() async {
    final prefs = await SharedPreferences.getInstance();

    int count = prefs.getInt(_openCountKey) ?? 0;

    count++;

    await prefs.setInt(_openCountKey, count);

    if (count % 36 == 0) {
      final review = InAppReview.instance;

      if (await review.isAvailable()) {
        await review.requestReview();
      }
    }
  }
}
