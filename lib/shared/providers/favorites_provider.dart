import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:find_my_stuff/shared/providers/theme_provider.dart';

class FavoritesNotifier extends StateNotifier<List<String>> {
  final SharedPreferences _prefs;

  FavoritesNotifier(this._prefs)
      : super(_prefs.getStringList('pref_favorite_uuids') ?? []);

  void toggleFavorite(String uuid) {
    final list = List<String>.from(state);
    if (list.contains(uuid)) {
      list.remove(uuid);
    } else {
      list.add(uuid);
    }
    _prefs.setStringList('pref_favorite_uuids', list);
    state = list;
  }

  bool isFavorite(String uuid) => state.contains(uuid);
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FavoritesNotifier(prefs);
});
