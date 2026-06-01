/// Visual badge attached to a course in the search result list.
///
/// Computed client-side from the search result set itself:
///   • [bestseller]   — most-enrolled course in the current result set.
///   • [highestRated] — highest-rated course (rating >= 4.5 with >= 10 reviews).
///   • [newRelease]   — published within the last 30 days.
enum CourseBadge {
  bestseller('bestseller'),
  highestRated('highest_rated'),
  newRelease('new_release');

  const CourseBadge(this.id);
  final String id;
}
