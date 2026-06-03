import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../courses/domain/entities/instrument_category.dart';

part 'search_filter.freezed.dart';

/// Filters applied on top of the keyword search.
///
/// All fields are optional / multi-select. Empty sets mean "no constraint".
/// Default-constructed instance ([SearchFilter.none]) is the "no filter"
/// baseline used by the notifier on init.
@freezed
abstract class SearchFilter with _$SearchFilter {
  const SearchFilter._();

  const factory SearchFilter({
    @Default(<InstrumentCategory>{}) Set<InstrumentCategory> categories,
    @Default(<CourseLevel>{}) Set<CourseLevel> levels,
    @Default(0) double minRating,
    int? maxPriceVnd,
  }) = _SearchFilter;

  /// Empty filter — used as the initial state.
  static const SearchFilter none = SearchFilter();

  bool get isEmpty =>
      categories.isEmpty &&
      levels.isEmpty &&
      minRating == 0 &&
      maxPriceVnd == null;

  /// Count of active filter facets — used to render the chip count next to
  /// the filter icon.
  int get activeCount {
    var n = 0;
    if (categories.isNotEmpty) n++;
    if (levels.isNotEmpty) n++;
    if (minRating > 0) n++;
    if (maxPriceVnd != null) n++;
    return n;
  }
}
