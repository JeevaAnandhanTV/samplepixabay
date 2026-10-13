import 'package:flutter/foundation.dart';

import '../gallery/data/models/pixabay_image.dart';
import 'favorites_repository.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController(this._repository) {
    _items.addAll(_repository.load());
    _ids.addAll(_items.map((e) => e.id));
  }

  final FavoritesRepository _repository;
  final List<PixabayImage> _items = []; // newest first
  final Set<int> _ids = {};

  List<PixabayImage> get items => List.unmodifiable(_items);
  int get count => _items.length;
  bool isFavorite(int id) => _ids.contains(id);

  /// Toggles favourite state. Returns the new state (true = favourited).
  Future<bool> toggle(PixabayImage image) async {
    final nowFavorite = !_ids.contains(image.id);
    if (nowFavorite) {
      _ids.add(image.id);
      _items.insert(0, image);
    } else {
      _ids.remove(image.id);
      _items.removeWhere((e) => e.id == image.id);
    }
    notifyListeners();
    await _repository.save(_items);
    return nowFavorite;
  }
}
