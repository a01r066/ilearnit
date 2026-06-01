import '../../../courses/data/models/course_model.dart';

/// A row in the live-suggestion list shown while the user is typing.
///
/// Two variants, distinguished by the icon they render:
///   • [SearchKeyword] — search-icon row, taps run a new search.
///   • [SearchCourseHit] — instructor-icon row, taps open the course.
sealed class SearchSuggestion {
  const SearchSuggestion();

  /// Text used by the UI to render and bold-match against the query.
  String get displayText;
}

/// A keyword the user can search for. Sources: static catalogue of common
/// instrument queries (`fingerstyle guitar`, `ukulele fingerstyle`, etc.)
/// plus the user's recent search history.
final class SearchKeyword extends SearchSuggestion {
  const SearchKeyword(this.term);
  final String term;

  @override
  String get displayText => term;
}

/// A direct hit on a course in the catalogue — taps deep-link to detail.
final class SearchCourseHit extends SearchSuggestion {
  const SearchCourseHit(this.course);
  final CourseModel course;

  @override
  String get displayText => course.title;
}
