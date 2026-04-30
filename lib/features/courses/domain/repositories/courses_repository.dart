import '../../../../core/typedefs/typedefs.dart';
import '../entities/course_entity.dart';
import '../entities/instrument_category.dart';

/// Cursor-based pagination payload.
class CoursesPage {
  const CoursesPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });
  final List<CourseEntity> items;
  final String? nextCursor;
  final bool hasMore;
}

abstract interface class CoursesRepository {
  ResultFuture<CoursesPage> fetchCourses({
    InstrumentCategory? category,
    CourseLevel? level,
    String? cursor,
    int limit,
  });

  ResultFuture<CourseEntity> fetchCourseById(String id);

  ResultFuture<List<CourseEntity>> fetchFeatured({int limit});
}
