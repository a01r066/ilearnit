import 'package:flutter/foundation.dart';

import '../../../../core/error/failure.dart';

/// Shared by [QuestionFormNotifier] and [ReplyFormNotifier] — both edit
/// a single body string with no rich content.
@immutable
class QAFormState {
  const QAFormState({
    this.body = '',
    this.isSubmitting = false,
    this.justSubmitted = false,
    this.lastFailure,
  });

  final String body;
  final bool isSubmitting;
  final bool justSubmitted;
  final Failure? lastFailure;

  /// Minimum length avoids empty / one-word junk threads.
  bool get canSubmit =>
      !isSubmitting && body.trim().length >= 5;

  QAFormState copyWith({
    String? body,
    bool? isSubmitting,
    bool? justSubmitted,
    Object? lastFailure = _unset,
  }) =>
      QAFormState(
        body: body ?? this.body,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        justSubmitted: justSubmitted ?? this.justSubmitted,
        lastFailure: identical(lastFailure, _unset)
            ? this.lastFailure
            : lastFailure as Failure?,
      );

  static const Object _unset = Object();
}
