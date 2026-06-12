import 'package:freezed_annotation/freezed_annotation.dart';

part 'revenue_summary.freezed.dart';

/// In-memory rollup computed by the datasource — never persisted.
///
/// Powers the KPI cards on `/my-revenue` (instructor view) and the
/// "Financial summary" block on `/admin/dashboard`.
@freezed
abstract class RevenueSummary with _$RevenueSummary {
  const RevenueSummary._();

  const factory RevenueSummary({
    @Default(0) double totalRevenueUsd,
    @Default(0) double monthRevenueUsd,
    @Default(0) int totalEnrollments,
    @Default(0) int totalStudents, // distinct studentUids
    @Default(0) int refundCount,
    @Default(<CourseRevenue>[]) List<CourseRevenue> byCourse,
  }) = _RevenueSummary;
}

@freezed
abstract class CourseRevenue with _$CourseRevenue {
  const factory CourseRevenue({
    required String courseId,
    @Default('') String courseTitle,
    @Default(0) double revenueUsd,
    @Default(0) int enrollments,
  }) = _CourseRevenue;
}
