import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/storage/prefs_service.dart';
import '../../../courses/data/models/course_model.dart';
import '../../data/datasources/search_remote_datasource.dart';
import '../../domain/entities/course_badge.dart';
import '../../domain/entities/search_filter.dart';
import '../../domain/entities/search_suggestion.dart';
import 'search_state.dart';

/// Drives the SearchPage.
///
/// Lifecycle:
///   1. Constructor → hydrate recent searches + warm a single fetch of the
///      full catalogue. All subsequent work is in-memory.
///   2. [onQueryChanged] debounces 250 ms then refreshes the suggestion
///      list (mode stays [SearchMode.suggestions]).
///   3. [submit] commits the query: persists to recents, switches mode to
///      [SearchMode.results], recomputes the ranked result list.
///   4. [setFilter] is applied immediately — no debounce — because it's a
///      coarse facet change.
class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier({
    required SearchRemoteDataSource remote,
    required PrefsService prefs,
  })  : _remote = remote,
        _prefs = prefs,
        super(const SearchState()) {
    _init();
  }

  final SearchRemoteDataSource _remote;
  final PrefsService _prefs;

  /// Full catalogue, fetched once on init and reused thereafter.
  List<CourseModel> _allCourses = const [];

  Timer? _debounce;
  static const _debounceDuration = Duration(milliseconds: 250);
  static const _suggestionLimit = 4;
  static const _courseHitLimit = 6;

  Future<void> _init() async {
    state = state.copyWith(
      recentSearches: _prefs.recentSearches,
      isLoading: true,
    );
    try {
      _allCourses = await _remote.fetchAllCourses();
    } catch (e, st) {
      state = state.copyWith(lastFailure: mapToFailure(e, st));
    }
    state = state.copyWith(isLoading: false);
    _refreshSuggestions();
  }

  /// Called on every keystroke. Debounces a suggestion refresh — we don't
  /// switch mode here, that's [submit]'s job.
  void onQueryChanged(String value) {
    state = state.copyWith(
      query: value,
      mode: SearchMode.suggestions,
      lastFailure: null,
    );
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, _refreshSuggestions);
  }

  /// Commit the current (or provided) query — switch to results mode,
  /// recompute the ranked list, push to recent searches.
  Future<void> submit({String? query}) async {
    final q = (query ?? state.query).trim();
    if (q.isEmpty) return;

    state = state.copyWith(
      query: q,
      mode: SearchMode.results,
      isLoading: true,
      lastFailure: null,
    );

    await _prefs.pushRecentSearch(q);

    final results = _remote.rankAndFilter(
      all: _allCourses,
      query: q,
      filter: state.filter,
    );
    state = state.copyWith(
      results: results,
      badges: _computeBadges(results),
      recentSearches: _prefs.recentSearches,
      isLoading: false,
    );
  }

  /// Clear the search box and bounce back to suggestions mode.
  void clearQuery() {
    _debounce?.cancel();
    state = state.copyWith(
      query: '',
      mode: SearchMode.suggestions,
      results: const [],
      badges: const {},
      lastFailure: null,
    );
    _refreshSuggestions();
  }

  Future<void> clearRecentSearches() async {
    await _prefs.clearRecentSearches();
    state = state.copyWith(recentSearches: const []);
    _refreshSuggestions();
  }

  /// Update the filter. If we're already in results mode, recompute
  /// immediately.
  void setFilter(SearchFilter filter) {
    state = state.copyWith(filter: filter);
    if (state.mode == SearchMode.results && state.hasQuery) {
      final results = _remote.rankAndFilter(
        all: _allCourses,
        query: state.query,
        filter: filter,
      );
      state = state.copyWith(
        results: results,
        badges: _computeBadges(results),
      );
    }
  }

  // ---------- internals ---------------------------------------------------

  void _refreshSuggestions() {
    final q = state.query.trim();
    final keywords = StaticSearchKeywords.matching(q, limit: _suggestionLimit);
    final courseHits = _remote
        .rankAndFilter(
          all: _allCourses,
          query: q,
          filter: SearchFilter.none,
        )
        .take(_courseHitLimit)
        .map(SearchCourseHit.new)
        .toList();

    final suggestions = <SearchSuggestion>[
      ...keywords.map(SearchKeyword.new),
      ...courseHits,
    ];

    state = state.copyWith(suggestions: suggestions);
  }

  /// Heuristic badge assignment for the current result set.
  ///
  ///   • Bestseller    — single course with the most enrollments (>= 100).
  ///   • Highest rated — single course with rating >= 4.5 (and that isn't
  ///                     already the bestseller).
  ///   • New release   — courses published within the last 30 days.
  Map<String, CourseBadge> _computeBadges(List<CourseModel> rs) {
    if (rs.isEmpty) return const {};
    final out = <String, CourseBadge>{};

    final byEnroll = [...rs]
      ..sort((a, b) => b.enrollmentCount.compareTo(a.enrollmentCount));
    if (byEnroll.first.enrollmentCount >= 100) {
      out[byEnroll.first.id] = CourseBadge.bestseller;
    }

    final byRating = [...rs]..sort((a, b) {
        // Min 10 enrollments to count toward "highest rated" so an unrated
        // brand-new course can't game it.
        if (a.enrollmentCount < 10 && b.enrollmentCount < 10) return 0;
        if (a.enrollmentCount < 10) return 1;
        if (b.enrollmentCount < 10) return -1;
        return b.rating.compareTo(a.rating);
      });
    if (byRating.first.rating >= 4.5 && !out.containsKey(byRating.first.id)) {
      out[byRating.first.id] = CourseBadge.highestRated;
    }

    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    for (final c in rs) {
      if (out.containsKey(c.id)) continue;
      if (c.publishedAt != null && c.publishedAt!.isAfter(cutoff)) {
        out[c.id] = CourseBadge.newRelease;
      }
    }

    return out;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
