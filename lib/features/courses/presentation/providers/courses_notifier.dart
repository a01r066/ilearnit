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

  /// Monotonic generation counter. Every `refresh()` claims the next
  /// generation and only writes its result if the counter hasn't moved
  /// on. Stops a stale unfiltered request (typically the constructor's
  /// initial refresh) from overwriting a fresher filtered one — the
  /// exact failure mode that caused "see all" to land on the wrong
  /// list when the deep-link's filter-apply raced the constructor.
  int _refreshGen = 0;

  Future<void> refresh() async {
    final gen = ++_refreshGen;
    state = state.copyWith(isLoading: true, failure: null);
    final result = await _repo.fetchCourses(
      category: state.category,
      level: state.level,
      // `featured == true` filters to isFeatured docs; `null` means
      // catalogue-wide. The bool→bool? lift here is intentional —
      // see CoursesRemoteDataSource for the rationale.
      featured: state.featured ? true : null,
      limit: AppConstants.defaultPageSize,
    );
    // Drop the result if a newer refresh has been queued. We DO NOT
    // need to undo the `isLoading: true` flag — whichever refresh
    // wins the race will set its own `isLoading: false` on success.
    if (gen != _refreshGen) return;
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

  /// Alias used by the page widget — matches the roadmap spec name.
  Future<void> loadNextPage() => loadMore();

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.nextCursor == null) {
      return;
    }
    state = state.copyWith(
      isLoadingMore: true,
      loadMoreFailure: null,
    );
    final result = await _repo.fetchCourses(
      category: state.category,
      level: state.level,
      featured: state.featured ? true : null,
      cursor: state.nextCursor,
      limit: AppConstants.defaultPageSize,
    );
    result.fold(
      // loadMore failures land in `loadMoreFailure` (not the top-level
      // `failure`) so we don't blow away the already-rendered list — the
      // UI surfaces them as an inline retry footer instead.
      (f) => state = state.copyWith(
        isLoadingMore: false,
        loadMoreFailure: f,
      ),
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

  /// Toggle the featured-only filter and re-fetch from page 1. Driven
  /// by the "See all" tap on the home Featured carousel + the
  /// `?featured=true` deep-link query param consumed by `CoursesPage`.
  Future<void> filterByFeatured(bool featured) async {
    if (state.featured == featured) return;
    state = state.copyWith(featured: featured);
    await refresh();
  }

  /// Atomic apply of multiple filters at once. Use this from deep-link
  /// handlers (`?featured=true&category=guitar`) so the state hops
  /// to its final shape in a single mutation and only one `refresh()`
  /// fires — instead of `filterByFeatured` + `filterByCategory`
  /// chaining two separate state updates + two refreshes that race
  /// against each other.
  ///
  /// `category` is nullable to mean "no preference"; pass
  /// `category: null` AND set `clearCategory: false` (the default) to
  /// keep the existing category. Pass `clearCategory: true` to
  /// explicitly drop it.
  Future<void> applyFilters({
    InstrumentCategory? category,
    bool clearCategory = false,
    bool? featured,
  }) async {
    final nextCategory =
        clearCategory ? null : (category ?? state.category);
    final nextFeatured = featured ?? state.featured;
    final sameCategory = state.category == nextCategory;
    final sameFeatured = state.featured == nextFeatured;
    if (sameCategory && sameFeatured) return;
    state = state.copyWith(
      category: nextCategory,
      featured: nextFeatured,
    );
    await refresh();
  }
}
