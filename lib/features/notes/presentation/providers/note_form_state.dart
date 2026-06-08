import 'package:flutter/foundation.dart';

import '../../../../core/error/failure.dart';

/// Drives both the create-new and edit-existing flows for a single
/// note. `editingId == null` means a fresh note; non-null means we're
/// patching an existing doc.
@immutable
class NoteFormState {
  const NoteFormState({
    this.editingId,
    this.body = '',
    this.timestampSec,
    this.isSubmitting = false,
    this.justSubmitted = false,
    this.lastFailure,
  });

  final String? editingId;
  final String body;

  /// Playback position the note is pinned to. `null` means a free-form
  /// note with no jump target.
  final int? timestampSec;

  final bool isSubmitting;
  final bool justSubmitted;
  final Failure? lastFailure;

  bool get isEditing => editingId != null;

  /// Notes are personal mnemonics — even one word is fine. We only
  /// require *something* non-blank.
  bool get canSubmit => !isSubmitting && body.trim().isNotEmpty;

  NoteFormState copyWith({
    Object? editingId = _unset,
    String? body,
    Object? timestampSec = _unset,
    bool? isSubmitting,
    bool? justSubmitted,
    Object? lastFailure = _unset,
  }) =>
      NoteFormState(
        editingId: identical(editingId, _unset)
            ? this.editingId
            : editingId as String?,
        body: body ?? this.body,
        timestampSec: identical(timestampSec, _unset)
            ? this.timestampSec
            : timestampSec as int?,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        justSubmitted: justSubmitted ?? this.justSubmitted,
        lastFailure: identical(lastFailure, _unset)
            ? this.lastFailure
            : lastFailure as Failure?,
      );

  static const Object _unset = Object();
}
