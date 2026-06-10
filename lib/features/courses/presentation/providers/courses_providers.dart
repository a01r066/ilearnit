import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../data/datasources/cloudflare_stream_service.dart';
import '../../data/datasources/courses_remote_datasource.dart';
import '../../data/repositories/courses_repository_impl.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/entities/instrument_category.dart';
import '../../domain/repositories/courses_repository.dart';
import 'course_detail_notifier.dart';
import 'course_detail_state.dart';
import 'courses_notifier.dart';
import 'courses_state.dart';
import 'curriculum_notifier.dart';
import 'curriculum_state.dart';

final coursesRemoteDataSourceProvider = Provider<CoursesRemoteDataSource>(
  (ref) => CoursesRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
  ),
);

/// Singleton Cloudflare Stream resolver. The in-memory cache lives as
/// long as the provider container, so revisiting the same lecture
/// within ~50 min doesn't re-invoke the Cloud Function.
final cloudflareStreamServiceProvider = Provider<CloudflareStreamService>(
  (_) => CloudflareStreamService(),
);

/// Resolves a single video UID to a playback object. Use:
/// `ref.watch(cloudflareStreamPlaybackProvider(lecture.cloudflareVideoId!))`.
final cloudflareStreamPlaybackProvider = FutureProvider.autoDispose
    .family<CloudflareStreamPlayback, String>((ref, videoId) {
  return ref.watch(cloudflareStreamServiceProvider).resolve(videoId);
});

final coursesRepositoryProvider = Provider<CoursesRepository>(
  (ref) => CoursesRepositoryImpl(
    remote: ref.watch(coursesRemoteDataSourceProvider),
    network: ref.watch(networkInfoProvider),
  ),
);

final coursesNotifierProvider =
    StateNotifierProvider.autoDispose<CoursesNotifier, CoursesState>(
  (ref) => CoursesNotifier(ref.watch(coursesRepositoryProvider)),
);

/// Family scoped per course id — disposes when off-screen.
final courseDetailNotifierProvider = StateNotifierProvider.autoDispose
    .family<CourseDetailNotifier, CourseDetailState, String>(
  (ref, id) => CourseDetailNotifier(
    repo: ref.watch(coursesRepositoryProvider),
    courseId: id,
  ),
);

/// Featured courses for the home screen.
final featuredCoursesProvider =
    FutureProvider.autoDispose<List<CourseEntity>>((ref) async {
  final result = await ref.watch(coursesRepositoryProvider).fetchFeatured();
  return result.fold(
    (failure) => throw failure,
    (list) => list,
  );
});

/// Curriculum (sections + embedded lectures) for a given course.
final curriculumNotifierProvider = StateNotifierProvider.autoDispose
    .family<CurriculumNotifier, CurriculumState, String>(
  (ref, courseId) => CurriculumNotifier(
    repo: ref.watch(coursesRepositoryProvider),
    courseId: courseId,
  ),
);

/// Popular courses for a given [InstrumentCategory] — drives the
/// "Popular Guitar Courses" / "Popular Piano Courses" / "Popular Violin
/// Courses" carousels on the Home tab.
///
/// We fetch the first 30 courses for the category (ordered by `publishedAt`
/// from the existing query) and sort client-side by `enrollmentCount` to
/// avoid needing a composite Firestore index
/// (`category + enrollmentCount`).
final popularByInstrumentProvider = FutureProvider.autoDispose
    .family<List<CourseEntity>, InstrumentCategory>((ref, category) async {
  final result = await ref.watch(coursesRepositoryProvider).fetchCourses(
        category: category,
        limit: 30,
      );
  return result.fold(
    (failure) => throw failure,
    (page) {
      final items = [...page.items]
        ..sort((a, b) => b.enrollmentCount.compareTo(a.enrollmentCount));
      return items.take(8).toList();
    },
  );
});

/// One-shot fetch of a course by id. Used by the learning-path detail
/// page to hydrate each row in the curriculum (we iterate `courseIds`).
///
/// Riverpod dedupes concurrent calls for the same id, so rendering N
/// rows costs at most N Firestore reads — and the SDK caches
/// `courses/{id}` aggressively.
final courseByIdProvider = FutureProvider.autoDispose
    .family<CourseEntity?, String>((ref, id) async {
  final result =
      await ref.watch(coursesRepositoryProvider).fetchCourseById(id);
  return result.fold(
    (_) => null, // surface as "course missing" in the UI
    (course) => course,
  );
});
