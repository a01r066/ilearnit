import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'exceptions.dart';
import 'failure.dart';

/// Centralized exception → Failure mapping.
///
/// Repositories should wrap data-source calls with [mapToFailure] so the
/// presentation layer only ever sees `Failure` variants.
Failure mapToFailure(Object error, [StackTrace? stackTrace]) {
  if (error is Failure) return error;

  if (error is DioException) return _fromDio(error);

  if (error is FirebaseAuthException) {
    return Failure.auth(
      message: _firebaseAuthMessage(error),
      code: error.code,
    );
  }

  if (error is ServerException) {
    return Failure.server(message: error.message, statusCode: error.statusCode);
  }

  if (error is NetworkException) {
    return Failure.network(message: error.message);
  }

  if (error is AuthException) {
    return Failure.auth(message: error.message, code: error.code);
  }

  if (error is CacheException) {
    return Failure.cache(message: error.message);
  }

  return Failure.unexpected(
    message: error.toString(),
    error: error,
    stackTrace: stackTrace,
  );
}

Failure _fromDio(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const Failure.network(message: 'Connection timeout. Try again.');
    case DioExceptionType.connectionError:
      return const Failure.network();
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      final data = e.response?.data;
      final msg = (data is Map && data['message'] is String)
          ? data['message'] as String
          : 'Request failed.';
      return Failure.server(message: msg, statusCode: status);
    case DioExceptionType.cancel:
      return const Failure.unexpected(message: 'Request cancelled.');
    case DioExceptionType.badCertificate:
      return const Failure.network(message: 'Bad certificate.');
    case DioExceptionType.unknown:
      return Failure.unexpected(
        message: e.message ?? 'Unknown network error.',
        error: e,
      );
  }
}

String _firebaseAuthMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'That email address is invalid.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Invalid email or password.';
    case 'email-already-in-use':
      return 'An account already exists for that email.';
    case 'weak-password':
      return 'Password is too weak.';
    case 'too-many-requests':
      return 'Too many attempts. Try again later.';
    case 'network-request-failed':
      return 'No internet connection.';
    default:
      return e.message ?? 'Authentication failed.';
  }
}
