import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../courses/data/models/course_model.dart';
import '../../domain/entities/course_badge.dart';
import '../../domain/entities/search_filter.dart';
import '../../domain/entities/search_suggestion.dart';

part 'search_state.freezed.dart';

/// Top-level mode the SearchPage is in.
///
/// - [SearchMode.suggestions] — the user is actively typing or the
///   query is empty. Suggestion list + recent searches are visible.
/// - [SearchMode.results] — the user has submitted a query (via keyboard
///   enter or tap on a keyword suggestion). Full results list is visible.
enum SearchMode { suggestions, results }

@freezed
abstract class SearchState with _$SearchState {
  const SearchState._();

  const factory SearchState({
    @Default('') String query,
    @Default(SearchMode.suggestions) SearchMode mode,
    @Default(<SearchSuggestion>[]) List<SearchSuggestion> suggestions,
    @Default(<String>[]) List<String> recentSearches,
    @Default(<CourseModel>[]) List<CourseModel> results,
    @Default(<String, CourseBadge>{}) Map<String, CourseBadge> badges,
    @Default(SearchFilter.none) SearchFilter filter,
    @Default(false) bool isLoading,
    Failure? lastFailure,
  }) = _SearchState;

  bool get hasQuery => query.trim().isNotEmpty;
  bool get hasResults => results.isNotEmpty;
  bool get hasSuggestions => suggestions.isNotEmpty;
}
