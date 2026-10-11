import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'exceptions.dart';
import 'failure.dart';
import '../../l10n/l10n.dart';

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
      return Failure.network(message: L10n.current.errTimeout);
    case DioExceptionType.connectionError:
      return Failure.network(message: L10n.current.errNoInternet);
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      final data = e.response?.data;
      final msg = (data is Map && data['message'] is String)
          ? data['message'] as String
          : L10n.current.errRequestFailed;
      return Failure.server(message: msg, statusCode: status);
    case DioExceptionType.cancel:
      return Failure.unexpected(message: L10n.current.errRequestCancelled);
    case DioExceptionType.badCertificate:
      return Failure.network(message: L10n.current.errBadCertificate);
    case DioExceptionType.unknown:
      return Failure.unexpected(
        message: L10n.current.errUnknownNetwork,
        error: e,
      );
  }
}

String _firebaseAuthMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return L10n.current.authErrInvalidEmail;
    case 'user-disabled':
      return L10n.current.authErrDisabled;
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return L10n.current.authErrInvalidCredentials;
    case 'email-already-in-use':
      return L10n.current.authErrEmailInUse;
    case 'weak-password':
      return L10n.current.authErrWeakPassword;
    case 'too-many-requests':
      return L10n.current.authErrTooManyRequests;
    case 'network-request-failed':
      return L10n.current.errNoInternet;
    default:
      return L10n.current.authErrGeneric;
  }
}
