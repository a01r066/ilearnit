import '../../../../core/typedefs/typedefs.dart';
import '../entities/user_entity.dart';

/// Contract for the auth feature. Implementations live in `data/`.
abstract interface class AuthRepository {
  Stream<UserEntity?> authStateChanges();

  Future<UserEntity?> currentUser();

  ResultFuture<UserEntity> login({
    required String email,
    required String password,
  });

  ResultFuture<UserEntity> signup({
    required String email,
    required String password,
    required String displayName,
  });

  /// Trigger the native Google Sign-In flow and exchange the Google ID token
  /// for a Firebase credential. On first sign-in a Firestore user doc is
  /// created.
  ///
  /// If the user cancels the picker, the returned [Failure] will have
  /// `code == [AuthCancellation.code]` so callers can suppress error UI.
  ResultFuture<UserEntity> signInWithGoogle();

  /// Trigger the native Sign in with Apple flow (iOS only) and exchange the
  /// Apple identity token for a Firebase credential. On first sign-in a
  /// Firestore user doc is created.
  ///
  /// If the user cancels, see [signInWithGoogle] for the cancellation
  /// convention.
  ResultFuture<UserEntity> signInWithApple();

  ResultVoid logout();

  ResultVoid sendPasswordReset({required String email});

  /// Re-authenticate the currently signed-in user with their email and
  /// password. Required by Firebase Auth before destructive actions like
  /// [deleteAccount].
  ///
  /// No-op for users who signed in with Google or Apple — they should
  /// re-run [reauthenticateWithGoogle] or [reauthenticateWithApple]
  /// instead.
  ResultVoid reauthenticateWithPassword({required String password});

  /// Re-trigger the Google sign-in flow so Firebase Auth receives a fresh
  /// credential. Used before destructive actions when the user signed in
  /// with Google.
  ResultVoid reauthenticateWithGoogle();

  /// Re-trigger Apple sign-in for a fresh credential.
  ResultVoid reauthenticateWithApple();

  /// Permanently delete the currently signed-in user and everything tied
  /// to them via the `deleteAccount` callable Cloud Function.
  ///
  /// The caller is responsible for re-authenticating first (Firebase Auth
  /// rejects token-aged deletions with `requires-recent-login`). On
  /// success the client should sign out and route to `/login`.
  ResultVoid deleteAccount();
}

/// Shared code used by social sign-in implementations to signal that the user
/// dismissed the provider's picker. The presentation layer should treat this
/// as a no-op rather than a real failure.
abstract class AuthCancellation {
  static const String code = 'cancelled';
}
