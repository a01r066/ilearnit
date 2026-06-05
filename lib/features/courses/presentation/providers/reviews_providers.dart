import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/course_reviews_datasource.dart';
import '../../data/models/course_review_model.dart';
import 'review_form_notifier.dart';
import 'review_form_state.dart';

final courseReviewsDataSourceProvider = Provider<CourseReviewsDataSource>(
  (ref) => CourseReviewsDataSource(firestore: ref.watch(firestoreProvider)),
);

/// Live list of all reviews for [courseId], newest first.
final courseReviewsProvider = StreamProvider.family
    .autoDispose<List<CourseReviewModel>, String>(
  (ref, courseId) =>
      ref.watch(courseReviewsDataSourceProvider).watchByCourse(courseId),
);

/// The signed-in user's own review for [courseId], or null if none / signed
/// out. Drives the "Write a review" ↔ "Edit your review" toggle.
final myReviewProvider =
    StreamProvider.family.autoDispose<CourseReviewModel?, String>((ref, courseId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref
      .watch(courseReviewsDataSourceProvider)
      .watchMine(courseId, user.id);
});

/// Form notifier — scoped per (courseId) so opening review sheets for
/// different courses doesn't share rating/body state.
final reviewFormNotifierProvider = StateNotifierProvider.autoDispose
    .family<ReviewFormNotifier, ReviewFormState, String>((ref, courseId) {
  final existing = ref.watch(myReviewProvider(courseId)).value;
  return ReviewFormNotifier(
    datasource: ref.watch(courseReviewsDataSourceProvider),
    courseId: courseId,
    user: ref.watch(currentUserProvider),
    initialRating: existing?.rating ?? 0,
    initialBody: existing?.body ?? '',
  );
});
