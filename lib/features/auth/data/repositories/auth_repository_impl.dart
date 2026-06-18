import 'package:dartz/dartz.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

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
          // Firebase Auth fires the state change the instant
          // `createUserWithEmailAndPassword` resolves — earlier than
          // the Firestore user-doc write that follows in the same
          // signup flow. A first-attempt null is therefore expected.
          // Retry once after a short delay so the stream emits the
          // doc-backed entity instead of the minimal fallback (which
          // would otherwise show role=student, eulaAcceptedVersion=0,
          // no instrument — i.e. "guest-shaped" data on My Learning
          // and Profile until something else triggers a rebuild).
          var doc = await _remote.fetchUserDoc(user.uid);
          if (doc == null) {
            await Future<void>.delayed(const Duration(milliseconds: 400));
            doc = await _remote.fetchUserDoc(user.uid);
          }
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
  Future<UserEntity?> refreshCurrentUser() async {
    final fb = _remote.currentFirebaseUser;
    if (fb == null) return null;
    final doc = await _remote.fetchUserDoc(fb.uid);
    if (doc != null) return doc.toEntity();
    // Last-ditch fallback — same shape as `authStateChanges`. Lets
    // the caller still render a "you're signed in" header while the
    // server-side write catches up.
    return UserEntity(
      id: fb.uid,
      email: fb.email ?? '',
      displayName: fb.displayName,
      photoUrl: fb.photoURL,
      emailVerified: fb.emailVerified,
    );
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
      await _persistToken();
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
      await _persistToken();
      return Right(model.toEntity());
    } catch (e, st) {
      return Left(mapToFailure(e, st));
    }
  }

  @override
  ResultFuture<UserEntity> signInWithGoogle() => _runSocial(
        () => _remote.signInWithGoogle(),
      );

  @override
  ResultFuture<UserEntity> signInWithApple() => _runSocial(
        () => _remote.signInWithApple(),
      );

  /// Shared envelope for the social flows: network gate, token persistence,
  /// failure mapping.
  ResultFuture<UserEntity> _runSocial(
    Future<UserModel> Function() flow,
  ) async {
    if (!await _network.isConnected) {
      return const Left(Failure.network());
    }
    try {
      final model = await flow();
      await _persistToken();
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

  @override
  ResultVoid reauthenticateWithPassword({required String password}) async {
    if (!await _network.isConnected) {
      return const Left(Failure.network());
    }
    try {
      await _remote.reauthenticateWithPassword(password: password);
      return const Right(null);
    } catch (e, st) {
      return Left(mapToFailure(e, st));
    }
  }

  @override
  ResultVoid reauthenticateWithGoogle() =>
      _runReauthSocial(() => _remote.reauthenticateWithGoogle());

  @override
  ResultVoid reauthenticateWithApple() =>
      _runReauthSocial(() => _remote.reauthenticateWithApple());

  @override
  ResultVoid deleteAccount() async {
    if (!await _network.isConnected) {
      return const Left(Failure.network());
    }
    try {
      await _remote.deleteAccount();
      await _storage.clearTokens();
      return const Right(null);
    } catch (e, st) {
      return Left(mapToFailure(e, st));
    }
  }

  @override
  ResultVoid updateRatingPromptStamp(DateTime when) async {
    if (!await _network.isConnected) {
      return const Left(Failure.network());
    }
    try {
      await _remote.updateRatingPromptStamp(when);
      return const Right(null);
    } catch (e, st) {
      return Left(mapToFailure(e, st));
    }
  }

  @override
  ResultVoid updateProfile({
    String? primaryInstrument,
    String? skillLevel,
    String? displayName,
  }) async {
    if (!await _network.isConnected) {
      return const Left(Failure.network());
    }
    try {
      await _remote.updateProfile(
        primaryInstrument: primaryInstrument,
        skillLevel: skillLevel,
        displayName: displayName,
      );
      return const Right(null);
    } catch (e, st) {
      return Left(mapToFailure(e, st));
    }
  }

  /// Shared envelope for the social re-auth flows. Cancellation surfaces as
  /// an [AuthFailure] with `code == AuthCancellation.code` so the UI can
  /// suppress error toasts.
  ResultVoid _runReauthSocial(Future<void> Function() flow) async {
    if (!await _network.isConnected) {
      return const Left(Failure.network());
    }
    try {
      await flow();
      return const Right(null);
    } catch (e, st) {
      return Left(mapToFailure(e, st));
    }
  }

  // ---------- helpers -----------------------------------------------------

  /// Persist the current Firebase ID token to secure storage so any
  /// non-Firebase backend calls can attach an Authorization header.
  Future<void> _persistToken() async {
    final fb = _remote.currentFirebaseUser;
    final token = await fb?.getIdToken();
    if (token != null) await _storage.writeAccessToken(token);
  }
}
