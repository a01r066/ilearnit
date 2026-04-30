import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../data/datasources/courses_remote_datasource.dart';
import '../../data/repositories/courses_repository_impl.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/courses_repository.dart';
import 'course_detail_notifier.dart';
import 'course_detail_state.dart';
import 'courses_notifier.dart';
import 'courses_state.dart';

final coursesRemoteDataSourceProvider = Provider<CoursesRemoteDataSource>(
  (ref) => CoursesRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
  ),
);

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
