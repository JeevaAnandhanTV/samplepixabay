import '../../../core/config/app_config.dart';
import 'pixabay_api_client.dart';

export 'pixabay_api_client.dart' show ImagePage;

/// Abstraction used by the controller so tests can inject a fake.
abstract class GalleryRepository {
  Future<ImagePage> fetch({
    required int page,
    int perPage = AppConfig.defaultPageSize,
    String query = '',
    String? category,
  });
}

class PixabayGalleryRepository implements GalleryRepository {
  PixabayGalleryRepository(this._api);
  final PixabayApiClient _api;

  @override
  Future<ImagePage> fetch({
    required int page,
    int perPage = AppConfig.defaultPageSize,
    String query = '',
    String? category,
  }) =>
      _api.fetchImages(
        page: page,
        perPage: perPage,
        query: query,
        category: category,
      );
}
