import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../l10n/l10n.dart';
import 'failure.dart';

/// Single exception → Failure mapping. Repositories call this in `catch`.
/// Messages come from L10n.current so they follow the app language.
Failure mapToFailure(Object error, [StackTrace? st]) {
  if (error is Failure) return error;
  final t = L10n.current;

  if (error is FirebaseAuthException) {
    return Failure.auth(
      code: error.code,
      message: switch (error.code) {
        'invalid-email' => t.authErrInvalidEmail,
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          t.authErrInvalidCredentials,
        'email-already-in-use' => t.authErrEmailInUse,
        'network-request-failed' => t.errNoInternet,
        _ => t.authErrGeneric,
      },
    );
  }
  if (error is FirebaseFunctionsException) {
    return switch (error.code) {
      'unavailable' || 'deadline-exceeded' => Failure.network(message: t.errNoInternet),
      'permission-denied' || 'unauthenticated' => Failure.permission(message: t.errPermission),
      // Callables throw HttpsError with user-safe messages by convention.
      _ => Failure.server(message: error.message ?? t.errGeneric),
    };
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'unavailable' => Failure.network(message: t.errNoInternet),
      'permission-denied' => Failure.permission(message: t.errPermission),
      _ => Failure.server(message: t.errGeneric),
    };
  }
  if (kDebugMode) debugPrint('[failure] unmapped $error\n$st');
  return Failure.unexpected(message: t.errGeneric, error: error, stackTrace: st);
}
