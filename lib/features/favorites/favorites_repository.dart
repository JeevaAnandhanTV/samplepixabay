import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../gallery/data/models/pixabay_image.dart';

/// Local persistence for favourites. Whole image objects are stored (not just
/// ids) so the Favorites screen works fully offline-first and instantly.
class FavoritesRepository {
  FavoritesRepository(this._prefs);

  static const _key = 'favorites_v1';
  final SharedPreferences _prefs;

  List<PixabayImage> load() {
    final raw = _prefs.getStringList(_key) ?? const <String>[];
    final result = <PixabayImage>[];
    for (final entry in raw) {
      try {
        result.add(PixabayImage.fromJson(
            jsonDecode(entry) as Map<String, dynamic>));
      } catch (_) {
        // Skip corrupted entries rather than crash the app.
      }
    }
    return result;
  }

  Future<void> save(Iterable<PixabayImage> images) => _prefs.setStringList(
        _key,
        images.map((e) => jsonEncode(e.toJson())).toList(),
      );
}
