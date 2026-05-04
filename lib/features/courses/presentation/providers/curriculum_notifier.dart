import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/repositories/courses_repository.dart';
import 'curriculum_state.dart';

class CurriculumNotifier extends StateNotifier<CurriculumState> {
  CurriculumNotifier({
    required CoursesRepository repo,
    required String courseId,
  })  : _repo = repo,
        _courseId = courseId,
        super(const CurriculumState.loading()) {
    load();
  }

  final CoursesRepository _repo;
  final String _courseId;

  Future<void> load() async {
    state = const CurriculumState.loading();
    final result = await _repo.fetchSections(_courseId);
    state = result.fold(
      CurriculumState.error,
      CurriculumState.loaded,
    );
  }
}
