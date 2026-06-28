import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/entities/instrument_category.dart';

part 'courses_state.freezed.dart';

/// State for the courses LIST screen.
///
/// Pagination is cursor-based; `nextCursor` and `hasMore` come from Firestore.
@freezed
abstract class CoursesState with _$CoursesState {
  const CoursesState._();

  const factory CoursesState({
    @Default(<CourseEntity>[]) List<CourseEntity> items,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(true) bool hasMore,
    String? nextCursor,
    InstrumentCategory? category,
    CourseLevel? level,
    /// `true` → list scoped to featured courses (driven by the "See
    /// all" tap on the home Featured carousel, or by the
    /// `?featured=true` deep-link query param). `false` /
    /// unset → catalogue-wide.
    @Default(false) bool featured,

    /// Failure on the initial / refresh load. Null while a load is in
    /// progress and on success.
    Failure? failure,

    /// Failure on the most recent `loadMore()`. Surfaced as an inline
    /// retry footer at the end of the grid so the user keeps their
    /// scroll position.
    Failure? loadMoreFailure,
  }) = _CoursesState;

  factory CoursesState.initial() => const CoursesState(isLoading: true);

  bool get isEmpty => items.isEmpty && !isLoading && failure == null;
}
