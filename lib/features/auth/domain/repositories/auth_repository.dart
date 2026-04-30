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

  ResultVoid logout();

  ResultVoid sendPasswordReset({required String email});
}
