enum AppErrorType {
  network,
  timeout,
  rateLimited,
  invalidApiKey,
  missingApiKey,
  server,
  permissionDenied,
  storage,
  cancelled,
  unknown,
  platformNotSupported,
}

/// Single exception type surfaced to the UI layer. Data/service layers map
/// low-level errors (Dio, Gal, parsing) to this so widgets never deal with
/// package-specific exceptions.
class AppException implements Exception {
  const AppException(this.type, this.message);

  final AppErrorType type;
  final String message;

  @override
  String toString() => 'AppException($type): $message';
}
