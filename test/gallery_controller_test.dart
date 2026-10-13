import 'package:flutter_test/flutter_test.dart';
import 'package:infinite_image_gallery/features/gallery/data/gallery_repository.dart';
import 'package:infinite_image_gallery/features/gallery/presentation/gallery_controller.dart';

import 'test_helpers.dart';

GalleryController build(FakeGalleryRepository repo) =>
    GalleryController(repo, perPage: 2);

void main() {
  test('loadInitial loads first page', () async {
    final c = build(FakeGalleryRepository(pagedHandler));
    await c.loadInitial();
    expect(c.status, GalleryStatus.success);
    expect(c.items.map((e) => e.id), [1, 2]);
    expect(c.hasMore, isTrue);
  });

  test('loadMore appends pages until exhausted', () async {
    final c = build(FakeGalleryRepository(pagedHandler));
    await c.loadInitial();
    await c.loadMore();
    expect(c.items.length, 4);
    expect(c.hasMore, isTrue);
    await c.loadMore();
    expect(c.items.length, 5);
    expect(c.hasMore, isFalse);

    final repo = FakeGalleryRepository(pagedHandler);
    final c2 = build(repo);
    await c2.loadInitial();
    await c2.loadMore();
    await c2.loadMore();
    final callsBefore = repo.calls;
    await c2.loadMore(); // no more pages -> no request
    expect(repo.calls, callsBefore);
  });

  test('duplicates are ignored', () async {
    final c = build(FakeGalleryRepository(
        (p, q, cat) async => ImagePage(images: [fakeImage(1), fakeImage(2)], totalHits: 100)));
    await c.loadInitial();
    await c.loadMore();
    expect(c.items.length, 2);
  });

  test('initial failure -> failure state, retry recovers', () async {
    final repo = FakeGalleryRepository((p, q, cat) async => throw networkError);
    final c = build(repo);
    await c.loadInitial();
    expect(c.status, GalleryStatus.failure);
    expect(c.error, networkError);

    repo.handler = pagedHandler;
    await c.loadInitial();
    expect(c.status, GalleryStatus.success);
    expect(c.error, isNull);
  });

  test('loadMore failure keeps items and can be retried', () async {
    final repo = FakeGalleryRepository(pagedHandler);
    final c = build(repo);
    await c.loadInitial();

    repo.handler = (p, q, cat) async => throw networkError;
    await c.loadMore();
    expect(c.items.length, 2);
    expect(c.loadMoreError, networkError);
    expect(c.isLoadingMore, isFalse);

    repo.handler = pagedHandler;
    await c.retryLoadMore();
    expect(c.items.length, 4);
    expect(c.loadMoreError, isNull);
  });

  test('category and query changes reset the list', () async {
    String? lastCategory;
    String? lastQuery;
    final repo = FakeGalleryRepository((p, q, cat) {
      lastCategory = cat;
      lastQuery = q;
      return pagedHandler(p, q, cat);
    });
    final c = build(repo);
    await c.loadInitial();
    await c.loadMore();
    expect(c.items.length, 4);

    await c.setCategory('food');
    expect(lastCategory, 'food');
    expect(c.items.length, 2);

    await c.setQuery('  pizza ');
    expect(lastQuery, 'pizza');
    expect(c.query, 'pizza');
  });

  test('stale responses are discarded after a newer request', () async {
    final repo = FakeGalleryRepository((p, q, cat) {
      if (q == 'slow') {
        return Future.delayed(
            const Duration(milliseconds: 50), () => ImagePage(images: [fakeImage(99)], totalHits: 1));
      }
      return pagedHandler(p, q, cat);
    });
    final c = build(repo);
    final first = c.setQuery('slow');
    final second = c.setQuery('fast');
    await Future.wait([first, second]);
    expect(c.items.map((e) => e.id), [1, 2]); // 'slow' result (id 99) ignored
  });

  test('refresh keeps old list when it fails', () async {
    final repo = FakeGalleryRepository(pagedHandler);
    final c = build(repo);
    await c.loadInitial();
    repo.handler = (p, q, cat) async => throw networkError;
    final error = await c.refresh();
    expect(error, networkError);
    expect(c.status, GalleryStatus.success);
    expect(c.items.length, 2);
  });
}
