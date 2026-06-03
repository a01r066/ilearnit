import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../../courses/data/models/course_model.dart';
import '../../data/datasources/instructors_datasource.dart';
import '../../data/models/instructor_model.dart';

final instructorsDataSourceProvider = Provider<InstructorsDataSource>(
  (ref) => InstructorsDataSource(firestore: ref.watch(firestoreProvider)),
);

/// Catalogue of all instructors — drives the InstructorsPage list.
final instructorsListProvider = StreamProvider<List<InstructorModel>>(
  (ref) => ref.watch(instructorsDataSourceProvider).watchAll(),
);

/// Detail-page binding.
final instructorByIdProvider =
    StreamProvider.family.autoDispose<InstructorModel?, String>(
  (ref, id) => ref.watch(instructorsDataSourceProvider).watchById(id),
);

/// "My courses (N)" carousel binding.
final coursesByInstructorProvider = StreamProvider.family
    .autoDispose<List<CourseModel>, String>(
  (ref, id) =>
      ref.watch(instructorsDataSourceProvider).watchCoursesByInstructor(id),
);
