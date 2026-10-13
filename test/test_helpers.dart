import 'package:infinite_image_gallery/core/errors/app_exception.dart';
import 'package:infinite_image_gallery/features/gallery/data/gallery_repository.dart';
import 'package:infinite_image_gallery/features/gallery/data/models/pixabay_image.dart';

PixabayImage fakeImage(int id, {String tags = 'nature, forest, green'}) =>
    PixabayImage(
      id: id,
      pageUrl: 'https://pixabay.com/photos/$id',
      tags: tags,
      previewUrl: 'https://example.com/p$id.jpg',
      webformatUrl: 'https://example.com/w$id.jpg',
      largeImageUrl: 'https://example.com/l$id.jpg',
      webformatWidth: 640,
      webformatHeight: 480,
      imageWidth: 4000,
      imageHeight: 3000,
      views: 12500,
      downloads: 800,
      likes: 90,
      comments: 3,
      user: 'tester',
      userImageUrl: '',
    );

typedef FetchHandler = Future<ImagePage> Function(
    int page, String query, String? category);

class FakeGalleryRepository implements GalleryRepository {
  FakeGalleryRepository(this.handler);

  FetchHandler handler;
  int calls = 0;

  @override
  Future<ImagePage> fetch({
    required int page,
    int perPage = 30,
    String query = '',
    String? category,
  }) {
    calls++;
    return handler(page, query, category);
  }
}

/// Pages of 2 items each, 5 hits in total (3 pages: 2 + 2 + 1).
Future<ImagePage> pagedHandler(int page, String query, String? category) async {
  const total = 5;
  final start = (page - 1) * 2 + 1;
  final ids = [for (var i = start; i < start + 2 && i <= total; i++) i];
  return ImagePage(images: ids.map(fakeImage).toList(), totalHits: total);
}

const networkError =
    AppException(AppErrorType.network, 'No internet connection.');
