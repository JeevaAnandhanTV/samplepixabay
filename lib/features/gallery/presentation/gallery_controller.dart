import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../data/gallery_repository.dart';
import '../data/models/pixabay_image.dart';

enum GalleryStatus { loading, success, failure }

/// Owns gallery state: items, pagination, search query and category.
///
/// A "generation" counter guards against race conditions: if the query or
/// category changes (or the list is refreshed) while a request is in flight,
/// the late response is discarded instead of corrupting the new list.
class GalleryController extends ChangeNotifier {
  GalleryController(
    this._repository, {
    this.perPage = AppConfig.defaultPageSize,
  });

  final GalleryRepository _repository;
  final int perPage;

  final List<PixabayImage> _items = [];
  final Set<int> _ids = {};

  GalleryStatus _status = GalleryStatus.loading;
  AppException? _error;
  AppException? _loadMoreError;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  int _generation = 0;
  String _query = '';
  String? _category;

  List<PixabayImage> get items => List.unmodifiable(_items);
  GalleryStatus get status => _status;
  AppException? get error => _error;
  AppException? get loadMoreError => _loadMoreError;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String get query => _query;
  String? get category => _category;

  /// First load (shows skeleton). Also used as "retry" on the error screen.
  Future<void> loadInitial() => _reset(showSkeleton: true);

  /// Pull-to-refresh. Keeps the current list visible until new data arrives.
  /// Returns the error (if any) so the UI can show a snackbar.
  Future<AppException?> refresh() async {
    await _reset(showSkeleton: false);
    return _status == GalleryStatus.failure ? _error : _refreshError;
  }

  AppException? _refreshError;

  Future<void> setQuery(String value) {
    final q = value.trim();
    if (q == _query) return Future.value();
    _query = q;
    return _reset(showSkeleton: true);
  }

  Future<void> setCategory(String? value) {
    if (value == _category) return Future.value();
    _category = value;
    return _reset(showSkeleton: true);
  }

  Future<void> _reset({required bool showSkeleton}) async {
    final generation = ++_generation;
    _page = 0;
    _hasMore = true;
    _loadMoreError = null;
    _refreshError = null;
    _isLoadingMore = false;

    if (showSkeleton || _items.isEmpty) {
      _items.clear();
      _ids.clear();
      _status = GalleryStatus.loading;
      _error = null;
    }
    notifyListeners();

    try {
      final result = await _repository.fetch(
        page: 1,
        perPage: perPage,
        query: _query,
        category: _category,
      );
      if (generation != _generation) return;
      _items.clear();
      _ids.clear();
      _append(result.images);
      _page = 1;
      _hasMore = result.images.isNotEmpty && perPage < result.totalHits;
      _status = GalleryStatus.success;
      _error = null;
    } on AppException catch (e) {
      if (generation != _generation) return;
      if (_items.isEmpty) {
        _status = GalleryStatus.failure;
        _error = e;
      } else {
        _refreshError = e; // keep showing the old list
      }
    }
    notifyListeners();
  }

  /// Loads the next page. Safe to call repeatedly (guarded).
  Future<void> loadMore() async {
    if (_status != GalleryStatus.success || _isLoadingMore || !_hasMore) return;

    final generation = _generation;
    final nextPage = _page + 1;
    _isLoadingMore = true;
    _loadMoreError = null;
    notifyListeners();

    try {
      final result = await _repository.fetch(
        page: nextPage,
        perPage: perPage,
        query: _query,
        category: _category,
      );
      if (generation != _generation) return;
      _append(result.images);
      _page = nextPage;
      _hasMore = result.images.isNotEmpty && nextPage * perPage < result.totalHits;
    } on AppException catch (e) {
      if (generation != _generation) return;
      _loadMoreError = e;
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Retry after a failed "load more".
  Future<void> retryLoadMore() => loadMore();

  void _append(List<PixabayImage> images) {
    for (final image in images) {
      if (_ids.add(image.id)) _items.add(image);
    }
  }
}
