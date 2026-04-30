/// Thin exception types thrown by data sources.
/// Repositories catch these and convert them to `Failure` variants.

class ServerException implements Exception {
  ServerException({required this.message, this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class NetworkException implements Exception {
  NetworkException([this.message = 'No internet connection.']);
  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  AuthException({required this.message, this.code});
  final String message;
  final String? code;

  @override
  String toString() => 'AuthException($code): $message';
}

class CacheException implements Exception {
  CacheException([this.message = 'Cache read/write failed.']);
  final String message;

  @override
  String toString() => 'CacheException: $message';
}
