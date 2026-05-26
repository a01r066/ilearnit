import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Manages auth lifecycle. Lives in its own file per project convention.
///
/// Subscribes to repository's `authStateChanges()` so external events
/// (token expiry, sign-out from another device) are reflected immediately.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState.initial()) {
    _bootstrap();
  }

  final AuthRepository _repo;
  StreamSubscription<UserEntity?>? _sub;

  Future<void> _bootstrap() async {
    state = const AuthState.loading();
    _sub = _repo.authStateChanges().listen((user) {
      state = user == null
          ? const AuthState.unauthenticated()
          : AuthState.authenticated(user);
    });
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    final result = await _repo.login(email: email, password: password);
    _applyResult(result);
  }

  Future<void> signup({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AuthState.loading();
    final result = await _repo.signup(
      email: email,
      password: password,
      displayName: displayName,
    );
    _applyResult(result);
  }

  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();
    final result = await _repo.signInWithGoogle();
    _applyResult(result);
  }

  Future<void> signInWithApple() async {
    state = const AuthState.loading();
    final result = await _repo.signInWithApple();
    _applyResult(result);
  }

  Future<void> logout() async {
    state = const AuthState.loading();
    final result = await _repo.logout();
    result.fold(
      (failure) => state = AuthState.unauthenticated(lastFailure: failure),
      (_) => state = const AuthState.unauthenticated(),
    );
  }

  Future<bool> sendPasswordReset(String email) async {
    final result = await _repo.sendPasswordReset(email: email);
    return result.isRight();
  }

  /// Collapse a Failure/User result into the appropriate AuthState.
  ///
  /// Treats provider cancellation as a quiet return to unauthenticated so
  /// the snackbar listener doesn't fire.
  void _applyResult(Either<Failure, UserEntity> result) {
    result.fold(
      (failure) {
        final isCancel = failure is AuthFailure &&
            failure.code == AuthCancellation.code;
        state = AuthState.unauthenticated(
          lastFailure: isCancel ? null : failure,
        );
      },
      (user) => state = AuthState.authenticated(user),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
