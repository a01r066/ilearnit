import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../flavors.dart';
import '../constants/app_constants.dart';
import 'auth_interceptor.dart';

/// Builds a configured [Dio] instance.
///
/// In dev: includes [PrettyDioLogger] for full request/response visibility.
/// In prod: silent.
class DioClient {
  static Dio create({
    AuthInterceptor? authInterceptor,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: F.apiBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.sendTimeout,
        responseType: ResponseType.json,
        contentType: Headers.jsonContentType,
        headers: <String, dynamic>{
          'Accept': 'application/json',
        },
      ),
    );

    if (authInterceptor != null) {
      dio.interceptors.add(authInterceptor);
    }

    if (kDebugMode || F.isDev) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          compact: false,
          maxWidth: 120,
        ),
      );
    }

    return dio;
  }
}
