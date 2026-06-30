import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';

/// Adds `Authorization: Bearer <token>` to outgoing requests.
///
/// On 401: tries the refresh-token flow once; if it succeeds, the original
/// request is retried with the new token. If it fails, the error propagates
/// so the AuthNotifier can sign the user out.
///
/// **Bearer header is suppressed for third-party media hosts** —
/// Firebase Storage download URLs (`?alt=media&token=…`) and Cloudflare
/// Stream HLS endpoints are pre-authenticated by their query token.
/// Sending our Firebase Auth ID token alongside causes Firebase Storage
/// to evaluate rules with our auth identity (which usually doesn't
/// grant read on the bucket) and return 403. Cloudflare Stream is
/// similar — the signed token in the URL is authoritative, and an
/// unrelated bearer can confuse the edge.
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

  /// Hosts whose URLs are pre-authenticated by a query token and must
  /// NOT receive our Firebase Auth bearer header. Matched as suffix on
  /// `RequestOptions.uri.host`.
  static const _noAuthHosts = <String>[
    // Firebase Storage public download URLs.
    'firebasestorage.googleapis.com',
    'firebasestorage.app',
    'appspot.com',
    // Cloudflare Stream HLS / DASH playback.
    'cloudflarestream.com',
    'videodelivery.net',
  ];

  bool _isThirdPartyMediaHost(String host) {
    for (final h in _noAuthHosts) {
      if (host == h || host.endsWith('.$h')) return true;
    }
    return false;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isThirdPartyMediaHost(options.uri.host)) {
      // Strip any Authorization header that might have been added by
      // a caller and bypass our own token attach. Defensive: avoids
      // 403s like `firebasestorage.googleapis.com → 403` when the
      // resource downloader fires.
      options.headers.remove('Authorization');
      handler.next(options);
      return;
    }
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
    // Third-party media hosts manage their own auth via query tokens.
    // Refreshing our Firebase Auth token + re-firing the request
    // wouldn't help, and would re-attach the bearer header we
    // deliberately stripped in `onRequest`.
    if (_isThirdPartyMediaHost(err.requestOptions.uri.host)) {
      handler.next(err);
      return;
    }

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
