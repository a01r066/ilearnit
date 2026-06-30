import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/auth_interceptor.dart';
import '../../core/network/dio_client.dart';
import 'storage_providers.dart';

/// Wires the [Dio] instance with [AuthInterceptor].
///
/// The refresh callback is wired to the auth notifier in `auth_providers.dart`.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);

  // The interceptor needs a Dio reference for retries, so we create the
  // instance first and wire the interceptor after.
  late final Dio dio;
  final interceptor = AuthInterceptor(
    storage: storage,
    dio: Dio(),
    onRefresh: () async {
      // TODO(auth): plug in real refresh-token flow:
      //   1. Read refresh token from secure storage.
      //   2. POST /auth/refresh.
      //   3. Persist new tokens, return new access token.
      return null;
    },
  );

  dio = DioClient.create(authInterceptor: interceptor);
  return dio;
});

/// Separate Dio instance for binary media downloads (Firebase Storage,
/// Cloudflare Stream, arbitrary CDN URLs). No `baseUrl`, no JSON
/// `Accept` / `Content-Type` defaults, no `AuthInterceptor`.
///
/// **Why a second instance.** The main `dioProvider` is configured for
/// our backend JSON API — its `BaseOptions.contentType` is
/// `application/json` and `Accept: application/json` is bolted on
/// globally. A per-call `Options(contentType: null, headers: ...)`
/// can't strip those — Dio interprets nulls as "use the base default."
/// Trying to download a PDF / JPG with `Content-Type: application/json`
/// on the request is benign for most CDNs but has been observed to
/// trigger 403s from Firebase Storage on the newer
/// `*.firebasestorage.app` bucket format. Cleaner to just not send
/// the header at all.
final mediaDownloadDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    // No baseUrl: download() always receives absolute URLs.
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(minutes: 2),
    sendTimeout: const Duration(seconds: 15),
    // Wildcard Accept — let the CDN decide MIME.
    headers: <String, dynamic>{'Accept': '*/*'},
    // Critical: don't preset Content-Type. GETs have no body, and a
    // stray Content-Type isn't worth the risk.
    contentType: null,
    followRedirects: true,
  ));
  // Intentionally no AuthInterceptor here — third-party media URLs
  // carry their own auth (Firebase Storage `?token=`, Cloudflare
  // Stream signed URLs, etc.).
  return dio;
});
