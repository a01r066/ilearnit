import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../purchases/domain/entities/price_tier.dart';
import 'course_status.dart';
import 'instrument_category.dart';

part 'course_entity.freezed.dart';

@freezed
abstract class CourseEntity with _$CourseEntity {
  const CourseEntity._();

  const factory CourseEntity({
    required String id,
    required String title,
    required String summary,
    required String thumbnailUrl,
    required InstrumentCategory category,
    required CourseLevel level,
    required String instructorId,
    required String instructorName,
    @Default(0) int lessonCount,
    @Default(0) int enrollmentCount,
    @Default(0.0) double rating,
    @Default(0) int durationMinutes,
    @Default(false) bool isFeatured,
    @Default(<String>[]) List<String> tags,
    @Default(PriceTier.basic) PriceTier priceTier,
    /// Review / publication state. Defaults to draft so a constructed
    /// `CourseEntity` (e.g. in tests) doesn't accidentally read as
    /// already-live.
    @Default(CourseStatus.draft) CourseStatus status,
    DateTime? publishedAt,
    DateTime? archivedAt,
  }) = _CourseEntity;

  /// App Store / Play Store product id resolved from the tier.
  String get productId => priceTier.productId;

  /// Best-effort price label — replaced at runtime by `ProductDetails.price`.
  String get fallbackPrice => priceTier.fallbackPrice;
}
