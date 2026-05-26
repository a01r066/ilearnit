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
}

/// Shared code used by social sign-in implementations to signal that the user
/// dismissed the provider's picker. The presentation layer should treat this
/// as a no-op rather than a real failure.
abstract class AuthCancellation {
  static const String code = 'cancelled';
}
