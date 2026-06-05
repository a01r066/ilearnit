import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';

part 'review_form_state.freezed.dart';

/// Drives the WriteReviewSheet's star picker + body field + submit button.
@freezed
abstract class ReviewFormState with _$ReviewFormState {
  const ReviewFormState._();

  const factory ReviewFormState({
    /// 0 = unrated. Submit requires >= 1.
    @Default(0) int rating,
    @Default('') String body,
    @Default(false) bool isSubmitting,

    /// Set briefly after a successful submit so the sheet can dismiss.
    @Default(false) bool justSubmitted,
    Failure? lastFailure,
  }) = _ReviewFormState;

  bool get canSubmit => rating > 0 && !isSubmitting;
}
