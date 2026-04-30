import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/entities/instrument_category.dart';

part 'courses_state.freezed.dart';

/// State for the courses LIST screen.
///
/// Pagination is cursor-based; `nextCursor` and `hasMore` come from Firestore.
@freezed
class CoursesState with _$CoursesState {
  const CoursesState._();

  const factory CoursesState({
    @Default(<CourseEntity>[]) List<CourseEntity> items,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(true) bool hasMore,
    String? nextCursor,
    InstrumentCategory? category,
    CourseLevel? level,
    Failure? failure,
  }) = _CoursesState;

  factory CoursesState.initial() => const CoursesState(isLoading: true);

  bool get isEmpty => items.isEmpty && !isLoading && failure == null;
}
