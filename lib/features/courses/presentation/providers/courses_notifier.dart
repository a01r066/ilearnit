import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/instrument_category.dart';
import '../../domain/repositories/courses_repository.dart';
import 'courses_state.dart';

class CoursesNotifier extends StateNotifier<CoursesState> {
  CoursesNotifier(this._repo) : super(CoursesState.initial()) {
    refresh();
  }

  final CoursesRepository _repo;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, failure: null);
    final result = await _repo.fetchCourses(
      category: state.category,
      level: state.level,
      limit: AppConstants.defaultPageSize,
    );
    result.fold(
      (f) => state = state.copyWith(isLoading: false, failure: f),
      (page) => state = state.copyWith(
        isLoading: false,
        items: page.items,
        hasMore: page.hasMore,
        nextCursor: page.nextCursor,
      ),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.nextCursor == null) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);
    final result = await _repo.fetchCourses(
      category: state.category,
      level: state.level,
      cursor: state.nextCursor,
      limit: AppConstants.defaultPageSize,
    );
    result.fold(
      (f) => state = state.copyWith(isLoadingMore: false, failure: f),
      (page) => state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...page.items],
        hasMore: page.hasMore,
        nextCursor: page.nextCursor,
      ),
    );
  }

  Future<void> filterByCategory(InstrumentCategory? category) async {
    state = state.copyWith(category: category);
    await refresh();
  }

  Future<void> filterByLevel(CourseLevel? level) async {
    state = state.copyWith(level: level);
    await refresh();
  }
}
