import 'package:flutter/foundation.dart';

import '../../../courses/domain/entities/instrument_category.dart';

/// Filters applied on top of the keyword search.
///
/// All fields are optional / multi-select. Empty sets mean "no constraint".
@immutable
class SearchFilter {
  const SearchFilter({
    this.categories = const {},
    this.levels = const {},
    this.minRating = 0,
    this.maxPriceVnd,
  });

  /// Empty filter — used as the initial state.
  static const SearchFilter none = SearchFilter();

  /// Which instrument categories to include (empty = all).
  final Set<InstrumentCategory> categories;

  /// Which difficulty levels to include (empty = all).
  final Set<CourseLevel> levels;

  /// Minimum rating to include (0 = no constraint).
  final double minRating;

  /// Maximum price in VND (null = no constraint). For USD-locale users we
  /// convert at display time only — the filter unit stays VND for parity
  /// with the catalogue.
  final int? maxPriceVnd;

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

  SearchFilter copyWith({
    Set<InstrumentCategory>? categories,
    Set<CourseLevel>? levels,
    double? minRating,
    int? maxPriceVnd,
    bool clearMaxPrice = false,
  }) {
    return SearchFilter(
      categories: categories ?? this.categories,
      levels: levels ?? this.levels,
      minRating: minRating ?? this.minRating,
      maxPriceVnd: clearMaxPrice ? null : (maxPriceVnd ?? this.maxPriceVnd),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SearchFilter &&
      setEquals(other.categories, categories) &&
      setEquals(other.levels, levels) &&
      other.minRating == minRating &&
      other.maxPriceVnd == maxPriceVnd;

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(categories),
        Object.hashAllUnordered(levels),
        minRating,
        maxPriceVnd,
      );
}
