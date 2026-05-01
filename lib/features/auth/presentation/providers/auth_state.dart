import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/user_entity.dart';

part 'auth_state.freezed.dart';

/// State for [AuthNotifier]. Lives in its own file per project convention.
@freezed
class AuthState with _$AuthState {
  const AuthState._();

  /// Cold start — we haven't checked the Firebase session yet.
  const factory AuthState.initial() = _Initial;

  /// In-flight (login / signup / logout / restore session).
  const factory AuthState.loading() = _Loading;

  /// Confirmed signed out (auth check completed with no user).
  const factory AuthState.unauthenticated({
    Failure? lastFailure,
  }) = Unauthenticated;

  /// Signed in with a known user.
  const factory AuthState.authenticated(UserEntity user) = Authenticated;

  // ── State predicates (used by router redirect, UI gates, etc.) ────
  bool get isInitial => this is _Initial;
  bool get isLoading => this is _Loading;
  bool get isAuthenticated => this is Authenticated;
  bool get isUnauthenticated => this is Unauthenticated;

  /// True while we don't yet know if the user is signed in.
  /// (Use this to keep the splash page visible.)
  bool get isResolving => isInitial || isLoading;

  /// Convenience — null when not signed in.
  UserEntity? get userOrNull {
    final self = this;
    return self is Authenticated ? self.user : null;
  }

  /// Last auth failure (only set on unauthenticated transitions).
  Failure? get failureOrNull {
    final self = this;
    return self is Unauthenticated ? self.lastFailure : null;
  }
}
