import 'package:dartz/dartz.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required NetworkInfo network,
    required SecureStorageService storage,
  })  : _remote = remote,
        _network = network,
        _storage = storage;

  final AuthRemoteDataSource _remote;
  final NetworkInfo _network;
  final SecureStorageService _storage;

  @override
  Stream<UserEntity?> authStateChanges() => _remote.authStateChanges().asyncMap(
        (user) async {
          if (user == null) return null;
          final doc = await _remote.fetchUserDoc(user.uid);
          return (doc?.toEntity()) ??
              UserEntity(
                id: user.uid,
                email: user.email ?? '',
                displayName: user.displayName,
                photoUrl: user.photoURL,
                emailVerified: user.emailVerified,
              );
        },
      );

  @override
  Future<UserEntity?> currentUser() async {
    final fb = _remote.currentFirebaseUser;
    if (fb == null) return null;
    final doc = await _remote.fetchUserDoc(fb.uid);
    return doc?.toEntity();
  }

  @override
  ResultFuture<UserEntity> login({
    required String email,
    required String password,
  }) async {
    if (!await _network.isConnected) {
      return const Left(Failure.network());
    }
    try {
      final model = await _remote.login(email: email, password: password);
      // Persist Firebase ID token for any non-Firebase backend calls.
      final fb = _remote.currentFirebaseUser;
      final token = await fb?.getIdToken();
      if (token != null) await _storage.writeAccessToken(token);
      return Right(model.toEntity());
    } catch (e, st) {
      return Left(mapToFailure(e, st));
    }
  }

  @override
  ResultFuture<UserEntity> signup({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (!await _network.isConnected) {
      return const Left(Failure.network());
    }
    try {
      final model = await _remote.signup(
        email: email,
        password: password,
        displayName: displayName,
      );
      final fb = _remote.currentFirebaseUser;
      final token = await fb?.getIdToken();
      if (token != null) await _storage.writeAccessToken(token);
      return Right(model.toEntity());
    } catch (e, st) {
      return Left(mapToFailure(e, st));
    }
  }

  @override
  ResultVoid logout() async {
    try {
      await _remote.logout();
      await _storage.clearTokens();
      return const Right(null);
    } catch (e, st) {
      return Left(mapToFailure(e, st));
    }
  }

  @override
  ResultVoid sendPasswordReset({required String email}) async {
    if (!await _network.isConnected) {
      return const Left(Failure.network());
    }
    try {
      await _remote.sendPasswordReset(email: email);
      return const Right(null);
    } catch (e, st) {
      return Left(mapToFailure(e, st));
    }
  }
}
