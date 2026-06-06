import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import 'delete_account_state.dart';

/// Drives the multi-step delete-account flow.
///
/// Steps:
///   1. [reauthenticateWithPassword] / [reauthenticateWithGoogle] /
///      [reauthenticateWithApple] — sets `step = reauthenticated` on
///      success, populates `lastFailure` on error (or leaves the user on
///      `idle` if they cancelled the social picker).
///   2. [confirmDelete] — gated on `isReauthenticated`. Sets `deleting`,
///      then transitions to `completed` or `failed`.
///
/// The page widget watches `isCompleted` to perform the post-success
/// navigation (sign-out + push `/login`).
class DeleteAccountNotifier extends StateNotifier<DeleteAccountState> {
  DeleteAccountNotifier(this._repo) : super(const DeleteAccountState());

  final AuthRepository _repo;

  Future<void> reauthenticateWithPassword(String password) async {
    state = state.copyWith(isBusy: true, lastFailure: null);
    final result = await _repo.reauthenticateWithPassword(password: password);
    result.fold(
      (failure) => state = state.copyWith(
        isBusy: false,
        lastFailure: failure,
      ),
      (_) => state = state.copyWith(
        isBusy: false,
        step: DeleteAccountStep.reauthenticated,
      ),
    );
  }

  Future<void> reauthenticateWithGoogle() =>
      _runSocialReauth(_repo.reauthenticateWithGoogle);

  Future<void> reauthenticateWithApple() =>
      _runSocialReauth(_repo.reauthenticateWithApple);

  Future<void> _runSocialReauth(ResultVoid Function() flow) async {
    state = state.copyWith(isBusy: true, lastFailure: null);
    final Either<Failure, void> result = await flow();
    result.fold(
      (failure) {
        // Treat provider-cancellation as a silent no-op so the user can try
        // again without an error toast.
        final isCancel = failure is AuthFailure &&
            failure.code == AuthCancellation.code;
        state = state.copyWith(
          isBusy: false,
          lastFailure: isCancel ? null : failure,
        );
      },
      (_) => state = state.copyWith(
        isBusy: false,
        step: DeleteAccountStep.reauthenticated,
      ),
    );
  }

  /// Final step. Must be invoked only after the user passed re-auth and
  /// confirmed the destructive action.
  Future<void> confirmDelete() async {
    if (!state.isReauthenticated) return;
    state = state.copyWith(
      step: DeleteAccountStep.deleting,
      isBusy: true,
      lastFailure: null,
    );
    final result = await _repo.deleteAccount();
    result.fold(
      (failure) => state = state.copyWith(
        step: DeleteAccountStep.failed,
        isBusy: false,
        lastFailure: failure,
      ),
      (_) => state = state.copyWith(
        step: DeleteAccountStep.completed,
        isBusy: false,
      ),
    );
  }

  void reset() {
    state = const DeleteAccountState();
  }
}
