import 'package:flutter/foundation.dart';

import '../../../../core/error/failure.dart';

/// Drives the [DeleteAccountPage] flow.
///
/// Lifecycle: `idle` → user re-authenticates → `reauthenticated` → confirms
/// → `deleting` → terminal (`completed` or `failed`).
enum DeleteAccountStep { idle, reauthenticated, deleting, completed, failed }

/// Plain immutable state. Kept as a hand-rolled class rather than freezed
/// because the field count is small and we want this to compile without a
/// `build_runner` pass.
@immutable
class DeleteAccountState {
  const DeleteAccountState({
    this.step = DeleteAccountStep.idle,
    this.isBusy = false,
    this.lastFailure,
  });

  final DeleteAccountStep step;
  final bool isBusy;
  final Failure? lastFailure;

  bool get isReauthenticated =>
      step == DeleteAccountStep.reauthenticated ||
      step == DeleteAccountStep.deleting;

  bool get isDeleting => step == DeleteAccountStep.deleting;
  bool get isCompleted => step == DeleteAccountStep.completed;

  /// Manual copyWith. Pass `lastFailure: null` explicitly to clear; omitting
  /// it preserves the current value (Dart treats omitted named args as
  /// "not provided" which we map to `_unset` below).
  DeleteAccountState copyWith({
    DeleteAccountStep? step,
    bool? isBusy,
    Object? lastFailure = _unset,
  }) {
    return DeleteAccountState(
      step: step ?? this.step,
      isBusy: isBusy ?? this.isBusy,
      lastFailure: identical(lastFailure, _unset)
          ? this.lastFailure
          : lastFailure as Failure?,
    );
  }

  static const Object _unset = Object();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeleteAccountState &&
          other.step == step &&
          other.isBusy == isBusy &&
          other.lastFailure == lastFailure);

  @override
  int get hashCode => Object.hash(step, isBusy, lastFailure);

  @override
  String toString() =>
      'DeleteAccountState(step: $step, isBusy: $isBusy, '
      'lastFailure: $lastFailure)';
}
