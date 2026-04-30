import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

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
    result.fold(
      (failure) => state = AuthState.unauthenticated(lastFailure: failure),
      (user) => state = AuthState.authenticated(user),
    );
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
    result.fold(
      (failure) => state = AuthState.unauthenticated(lastFailure: failure),
      (user) => state = AuthState.authenticated(user),
    );
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

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
