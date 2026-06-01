import 'package:flutter/foundation.dart';

import '../../../../core/error/failure.dart';
import '../../../courses/data/models/course_model.dart';
import '../../domain/entities/course_badge.dart';
import '../../domain/entities/search_filter.dart';
import '../../domain/entities/search_suggestion.dart';

/// Top-level mode the SearchPage is in.
///
/// - [SearchMode.suggestions] — the user is actively typing or the
///   query is empty. Suggestion list + recent searches are visible.
/// - [SearchMode.results] — the user has submitted a query (via keyboard
///   enter or tap on a keyword suggestion). Full results list is visible.
enum SearchMode { suggestions, results }

@immutable
class SearchState {
  const SearchState({
    this.query = '',
    this.mode = SearchMode.suggestions,
    this.suggestions = const [],
    this.recentSearches = const [],
    this.results = const [],
    this.badges = const {},
    this.filter = SearchFilter.none,
    this.isLoading = false,
    this.lastFailure,
  });

  /// The text currently in the search field.
  final String query;

  final SearchMode mode;

  /// Live suggestions (keyword + course hits) shown while typing.
  final List<SearchSuggestion> suggestions;

  /// MRU list of user's recent searches — shown above static suggestions
  /// when the query is empty.
  final List<String> recentSearches;

  /// Full result list for the committed query + filter.
  final List<CourseModel> results;

  /// Per-result badge assignments (computed from the result set).
  final Map<String, CourseBadge> badges;

  final SearchFilter filter;
  final bool isLoading;
  final Failure? lastFailure;

  bool get hasQuery => query.trim().isNotEmpty;
  bool get hasResults => results.isNotEmpty;
  bool get hasSuggestions => suggestions.isNotEmpty;

  SearchState copyWith({
    String? query,
    SearchMode? mode,
    List<SearchSuggestion>? suggestions,
    List<String>? recentSearches,
    List<CourseModel>? results,
    Map<String, CourseBadge>? badges,
    SearchFilter? filter,
    bool? isLoading,
    Failure? lastFailure,
    bool clearFailure = false,
  }) =>
      SearchState(
        query: query ?? this.query,
        mode: mode ?? this.mode,
        suggestions: suggestions ?? this.suggestions,
        recentSearches: recentSearches ?? this.recentSearches,
        results: results ?? this.results,
        badges: badges ?? this.badges,
        filter: filter ?? this.filter,
        isLoading: isLoading ?? this.isLoading,
        lastFailure: clearFailure ? null : (lastFailure ?? this.lastFailure),
      );
}
