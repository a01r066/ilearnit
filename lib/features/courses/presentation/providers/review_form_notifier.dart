import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../data/datasources/course_reviews_datasource.dart';
import 'review_form_state.dart';

/// Hydrates an empty form OR an existing review for editing, then
/// submits via [CourseReviewsDataSource.upsert].
class ReviewFormNotifier extends StateNotifier<ReviewFormState> {
  ReviewFormNotifier({
    required CourseReviewsDataSource datasource,
    required this.courseId,
    required this.user,
    int initialRating = 0,
    String initialBody = '',
  })  : _datasource = datasource,
        super(ReviewFormState(rating: initialRating, body: initialBody));

  final CourseReviewsDataSource _datasource;
  final String courseId;
  final UserEntity? user;

  void setRating(int rating) {
    if (rating < 1 || rating > 5) return;
    state = state.copyWith(rating: rating, lastFailure: null);
  }

  void setBody(String body) {
    state = state.copyWith(body: body, lastFailure: null);
  }

  Future<void> submit() async {
    final u = user;
    if (u == null) {
      // Not signed in — the UI shouldn't have offered this in the first
      // place, but guard anyway.
      return;
    }
    if (!state.canSubmit) return;

    state = state.copyWith(isSubmitting: true, lastFailure: null);
    try {
      await _datasource.upsert(
        courseId: courseId,
        userId: u.id,
        userName: u.displayName ?? u.email,
        userPhotoUrl: u.photoUrl,
        rating: state.rating,
        body: state.body.trim(),
      );
      state = state.copyWith(isSubmitting: false, justSubmitted: true);
    } catch (e, st) {
      state = state.copyWith(
        isSubmitting: false,
        lastFailure: mapToFailure(e, st),
      );
    }
  }

  Future<void> deleteMine() async {
    final u = user;
    if (u == null) return;
    state = state.copyWith(isSubmitting: true, lastFailure: null);
    try {
      await _datasource.delete(courseId: courseId, userId: u.id);
      state = state.copyWith(
        isSubmitting: false,
        justSubmitted: true,
        rating: 0,
        body: '',
      );
    } catch (e, st) {
      state = state.copyWith(
        isSubmitting: false,
        lastFailure: mapToFailure(e, st),
      );
    }
  }
}
