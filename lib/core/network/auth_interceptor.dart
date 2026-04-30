import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';

/// Adds `Authorization: Bearer <token>` to outgoing requests.
///
/// On 401: tries the refresh-token flow once; if it succeeds, the original
/// request is retried with the new token. If it fails, the error propagates
/// so the AuthNotifier can sign the user out.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required SecureStorageService storage,
    required Dio dio,
    Future<String?> Function()? onRefresh,
  })  : _storage = storage,
        _dio = dio,
        _onRefresh = onRefresh;

  final SecureStorageService _storage;
  final Dio _dio;
  final Future<String?> Function()? _onRefresh;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final shouldRetry = err.response?.statusCode == 401 &&
        _onRefresh != null &&
        err.requestOptions.extra['retried'] != true;

    if (!shouldRetry) {
      handler.next(err);
      return;
    }

    try {
      final newToken = await _onRefresh();
      if (newToken == null || newToken.isEmpty) {
        handler.next(err);
        return;
      }
      final req = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newToken'
        ..extra['retried'] = true;
      final response = await _dio.fetch<dynamic>(req);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
