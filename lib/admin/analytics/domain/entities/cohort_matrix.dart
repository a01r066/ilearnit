import 'package:freezed_annotation/freezed_annotation.dart';

part 'cohort_matrix.freezed.dart';

/// Rectangular cohort matrix.
///
/// Each row is a signup cohort (users who created their account in
/// month `cohortMonth`). Each column is a *follow-up month offset*
/// from the cohort month: column 0 = the signup month itself, column 1
/// = one month later, … up to [maxOffset].
///
/// Cell value at `[rowIndex][colIndex]` is the number of users in that
/// cohort who were "retained" by month `cohortMonth + colIndex` —
/// where retention is defined as "either made a course purchase OR
/// held an active subscription that month".
///
/// We store the matrix as rows of cells so the UI can iterate naturally
/// and the data layer can compute the matrix in one pass over the
/// (users × enrollments) join.
@freezed
abstract class CohortMatrix with _$CohortMatrix {
  const CohortMatrix._();

  const factory CohortMatrix({
    @Default(<CohortRow>[]) List<CohortRow> rows,
    @Default(0) int maxOffset,
  }) = _CohortMatrix;

  bool get isEmpty => rows.isEmpty;
}

@freezed
abstract class CohortRow with _$CohortRow {
  const CohortRow._();

  const factory CohortRow({
    required DateTime cohortMonth,
    @Default(0) int cohortSize,
    @Default(<int>[]) List<int> retainedByOffset,
  }) = _CohortRow;

  /// 0..1 retention for `offset`. Returns 0 when the cohort itself was
  /// empty (avoids NaN in the UI).
  double retentionAt(int offset) {
    if (cohortSize == 0) return 0;
    if (offset < 0 || offset >= retainedByOffset.length) return 0;
    return retainedByOffset[offset] / cohortSize;
  }
}

/// Headline conversion-funnel numbers — top-level KPIs above the
/// charts. Computed in the same pass as the matrix to avoid a second
/// scan of the users collection.
@freezed
abstract class FunnelCounts with _$FunnelCounts {
  const FunnelCounts._();

  const factory FunnelCounts({
    @Default(0) int totalUsers,
    @Default(0) int onboarded,
    @Default(0) int payingUsers,
    @Default(0) int activeSubscribers,
  }) = _FunnelCounts;

  double get onboardedRate =>
      totalUsers == 0 ? 0 : onboarded / totalUsers;
  double get conversionRate =>
      totalUsers == 0 ? 0 : payingUsers / totalUsers;
  double get subscriptionRate =>
      totalUsers == 0 ? 0 : activeSubscribers / totalUsers;
}
