import 'package:flutter_test/flutter_test.dart';
import 'package:infinite_image_gallery/features/favorites/favorites_controller.dart';
import 'package:infinite_image_gallery/features/favorites/favorites_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('toggle adds and removes favourites', () async {
    final c = FavoritesController(FavoritesRepository(prefs));
    expect(c.count, 0);

    expect(await c.toggle(fakeImage(1)), isTrue);
    expect(c.isFavorite(1), isTrue);
    expect(c.count, 1);

    expect(await c.toggle(fakeImage(1)), isFalse);
    expect(c.isFavorite(1), isFalse);
    expect(c.count, 0);
  });

  test('newest favourite comes first', () async {
    final c = FavoritesController(FavoritesRepository(prefs));
    await c.toggle(fakeImage(1));
    await c.toggle(fakeImage(2));
    expect(c.items.map((e) => e.id), [2, 1]);
  });

  test('favourites persist across controller instances', () async {
    final first = FavoritesController(FavoritesRepository(prefs));
    await first.toggle(fakeImage(5));
    await first.toggle(fakeImage(6));

    final second = FavoritesController(FavoritesRepository(prefs));
    expect(second.items.map((e) => e.id), [6, 5]);
    expect(second.isFavorite(5), isTrue);
    expect(second.items.first.user, 'tester');
  });

  test('corrupted entries are skipped', () async {
    SharedPreferences.setMockInitialValues({
      'favorites_v1': ['not json', '{"id": 3, "tags": "x"}'],
    });
    prefs = await SharedPreferences.getInstance();
    final c = FavoritesController(FavoritesRepository(prefs));
    expect(c.items.map((e) => e.id), [3]);
  });
}
