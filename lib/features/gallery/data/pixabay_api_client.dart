import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import 'models/pixabay_image.dart';

class ImagePage {
  const ImagePage({required this.images, required this.totalHits});
  final List<PixabayImage> images;
  final int totalHits;
}

/// Thin wrapper over the Pixabay REST API. Translates every failure into an
/// [AppException] so upper layers stay free of Dio details.
class PixabayApiClient {
  PixabayApiClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ));

  final Dio _dio;

  Future<ImagePage> fetchImages({
    required int page,
    int perPage = AppConfig.defaultPageSize,
    String query = '',
    String? category,
  }) async {
    if (!AppConfig.hasApiKey) {
      throw const AppException(
        AppErrorType.missingApiKey,
        'Pixabay API key is missing. Run the app with '
        '--dart-define=PIXABAY_API_KEY=<your key> (see README).',
      );
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        AppConfig.pixabayEndpoint,
        queryParameters: {
          'key': AppConfig.pixabayApiKey,
          'image_type': 'photo',
          'safesearch': 'true',
          'order': 'popular',
          'page': page,
          'per_page': perPage,
          if (query.isNotEmpty) 'q': query,
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );
      final data = response.data;
      if (data == null) {
        throw const AppException(
            AppErrorType.server, 'Empty response from server.');
      }
      final hits = (data['hits'] as List<dynamic>? ?? const [])
          .map((e) => PixabayImage.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      return ImagePage(
        images: hits,
        totalHits: (data['totalHits'] as num?)?.toInt() ?? hits.length,
      );
    } on DioException catch (e) {
      // Pixabay answers 400 when "page" exceeds the available range (it caps
      // results at 500 hits). For page > 1 this simply means "no more data".
      if (e.response?.statusCode == 400 && page > 1) {
        final body = '${e.response?.data}';
        if (body.contains('out of valid range')) {
          return const ImagePage(images: [], totalHits: 0);
        }
      }
      throw _mapDioError(e);
    } on AppException {
      rethrow;
    } on TypeError {
      throw const AppException(
          AppErrorType.unknown, 'Unexpected data received from server.');
    } on FormatException {
      throw const AppException(
          AppErrorType.unknown, 'Unexpected data received from server.');
    }
  }

  AppException _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const AppException(
            AppErrorType.timeout, 'The request timed out. Please try again.');
      case DioExceptionType.connectionError:
        return const AppException(AppErrorType.network,
            'No internet connection. Check your network.');
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        final body = '${e.response?.data}';
        if (code == 429) {
          return const AppException(AppErrorType.rateLimited,
              'Too many requests (Pixabay limit: 100/min). Wait a moment and retry.');
        }
        if (code == 401 ||
            code == 403 ||
            body.toLowerCase().contains('api key')) {
          return const AppException(
              AppErrorType.invalidApiKey, 'The Pixabay API key is invalid.');
        }
        return AppException(AppErrorType.server,
            'Server error ($code). Please try again later.');
      case DioExceptionType.cancel:
        return const AppException(AppErrorType.cancelled, 'Request cancelled.');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return const AppException(AppErrorType.network,
            'Could not reach the server. Check your network.');
    }
  }
}
