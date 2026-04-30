import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/repositories/courses_repository.dart';
import 'course_detail_state.dart';

class CourseDetailNotifier extends StateNotifier<CourseDetailState> {
  CourseDetailNotifier({
    required CoursesRepository repo,
    required String courseId,
  })  : _repo = repo,
        _courseId = courseId,
        super(const CourseDetailState.loading()) {
    load();
  }

  final CoursesRepository _repo;
  final String _courseId;

  Future<void> load() async {
    state = const CourseDetailState.loading();
    final result = await _repo.fetchCourseById(_courseId);
    state = result.fold(
      CourseDetailState.error,
      CourseDetailState.loaded,
    );
  }
}
