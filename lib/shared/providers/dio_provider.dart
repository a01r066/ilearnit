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
