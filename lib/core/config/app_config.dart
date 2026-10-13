/// Compile-time configuration.
///
/// The Pixabay key is injected with `--dart-define` so it is never committed:
///   flutter run --dart-define=PIXABAY_API_KEY=xxxx
/// or
///   flutter run --dart-define-from-file=dart_defines.json
class AppConfig {
  const AppConfig._();

  static const String pixabayApiKey =
      String.fromEnvironment('PIXABAY_API_KEY');

  static bool get hasApiKey => pixabayApiKey.trim().isNotEmpty;

  static const String pixabayEndpoint = 'https://pixabay.com/api/';
  static const int defaultPageSize = 30;
  static const String downloadAlbum = 'Infinite Gallery';
}
