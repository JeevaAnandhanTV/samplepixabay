import 'package:flutter_test/flutter_test.dart';
import 'package:infinite_image_gallery/features/gallery/data/models/pixabay_image.dart';

import 'test_helpers.dart';

void main() {
  group('PixabayImage', () {
    test('toJson/fromJson round trip keeps data', () {
      final original = fakeImage(7);
      final copy = PixabayImage.fromJson(original.toJson());
      expect(copy, original);
      expect(copy.tags, original.tags);
      expect(copy.largeImageUrl, original.largeImageUrl);
      expect(copy.views, 12500);
    });

    test('fromJson tolerates missing fields', () {
      final image = PixabayImage.fromJson({'id': 1});
      expect(image.id, 1);
      expect(image.user, 'Unknown');
      expect(image.aspectRatio, closeTo(4 / 3, 0.001));
    });

    test('description is built from tags, author and stats', () {
      final image = fakeImage(1);
      expect(image.title, 'Nature photo by tester');
      expect(image.description, contains('nature'));
      expect(image.description, contains('forest, green'));
      expect(image.description, contains('4000 × 3000'));
      expect(image.description, contains('12.5K'));
    });

    test('tagList trims and drops empties', () {
      final image = fakeImage(1, tags: ' a , ,b ');
      expect(image.tagList, ['a', 'b']);
    });
  });
}
