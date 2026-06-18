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
/// **Two sources of truth, reconciled.** Auth state changes can arrive
/// from two places:
///
///   1. The `_repo.authStateChanges()` stream — fires on external
///      events (sign-out from another device, token expiry) AND on the
///      tail end of our own login/signup. The stream's `asyncMap` can
///      emit a stale fallback `UserEntity` during the signup race
///      (Firebase Auth state change fires before the Firestore user
///      doc write completes — see `AuthRepositoryImpl`).
///   2. Explicit `login` / `signup` / `signInWithGoogle` /
///      `signInWithApple` calls — these always end with an explicit
///      `refreshCurrentUser()` round-trip so the state holds the
///      authoritative doc-backed entity.
///
/// To stop the stream from downgrading a freshly-refreshed state, we
/// keep `_lastAuthoritativeAt`. The stream listener treats any
/// emission within the cool-down window as advisory and ignores it if
/// the current state already has a matching user id.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState.initial()) {
    _bootstrap();
  }

  final AuthRepository _repo;
  StreamSubscription<UserEntity?>? _sub;

  /// Wall-clock timestamp of the last manual refresh / login result.
  /// Stream emissions within `_streamCooldown` are skipped if they'd
  /// produce a same-id "downgrade" (e.g. defaults overriding real
  /// fields). Refreshing this on every explicit transition keeps the
  /// system snappy: a real external sign-out STILL applies, because
  /// the stream emits `user == null` which is never a downgrade.
  DateTime? _lastAuthoritativeAt;
  static const _streamCooldown = Duration(seconds: 2);

  Future<void> _bootstrap() async {
    state = const AuthState.loading();
    _sub = _repo.authStateChanges().listen((user) {
      // `user == null` is always honoured — external sign-out / token
      // revoke must clear the UI immediately.
      if (user == null) {
        state = const AuthState.unauthenticated();
        return;
      }
      // Cool-down guard. If the user id matches what we already have
      // AND we've recently refreshed manually, prefer the manual
      // result over the stream's potentially-fallback entity.
      final current = state.userOrNull;
      final recentlyRefreshed = _lastAuthoritativeAt != null &&
          DateTime.now().difference(_lastAuthoritativeAt!) <
              _streamCooldown;
      if (recentlyRefreshed && current != null && current.id == user.id) {
        return;
      }
      state = AuthState.authenticated(user);
    });
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    final result = await _repo.login(email: email, password: password);
    await _applyResult(result);
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
    await _applyResult(result);
  }

  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();
    final result = await _repo.signInWithGoogle();
    await _applyResult(result);
  }

  Future<void> signInWithApple() async {
    state = const AuthState.loading();
    final result = await _repo.signInWithApple();
    await _applyResult(result);
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

  /// Force a re-read of `users/{uid}` and update the state. Public so
  /// callers can refresh after a server-side mutation (e.g. the
  /// onboarding flow that writes `primaryInstrument` / `skillLevel`
  /// straight to Firestore).
  Future<void> refreshCurrentUser() async {
    try {
      final user = await _repo.refreshCurrentUser();
      _lastAuthoritativeAt = DateTime.now();
      state = user == null
          ? const AuthState.unauthenticated()
          : AuthState.authenticated(user);
    } catch (_) {
      // Refresh failures are non-fatal — the existing state stays.
      // Avoid clobbering a known-good `authenticated(user)` with an
      // `unauthenticated()` just because the read momentarily failed.
    }
  }

  /// Collapse a Failure/User result into the appropriate AuthState.
  ///
  /// On success, follow up with a `refreshCurrentUser()` round-trip so
  /// the state holds the doc-backed entity (with real role,
  /// `eulaAcceptedVersion`, instrument, etc.) — NOT whichever shape
  /// the auth-state stream happens to emit during the post-signup
  /// race. See class dartdoc.
  ///
  /// Treats provider cancellation as a quiet return to unauthenticated
  /// so the snackbar listener doesn't fire.
  Future<void> _applyResult(Either<Failure, UserEntity> result) async {
    await result.fold(
      (failure) async {
        final isCancel = failure is AuthFailure &&
            failure.code == AuthCancellation.code;
        state = AuthState.unauthenticated(
          lastFailure: isCancel ? null : failure,
        );
      },
      (user) async {
        // First, optimistically apply the result so any listener
        // (router redirect, snackbar) responds immediately.
        _lastAuthoritativeAt = DateTime.now();
        state = AuthState.authenticated(user);
        // Then re-fetch from Firestore — picks up server-side
        // defaults (createdAt timestamp, server-generated fields)
        // and ensures downstream providers see canonical data.
        await refreshCurrentUser();
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
