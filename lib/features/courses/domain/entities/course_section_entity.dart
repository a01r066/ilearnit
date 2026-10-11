import 'package:freezed_annotation/freezed_annotation.dart';

import 'lecture_entity.dart';
import '../../../../l10n/l10n.dart';

part 'course_section_entity.freezed.dart';

@freezed
abstract class CourseSectionEntity with _$CourseSectionEntity {
  const CourseSectionEntity._();

  const factory CourseSectionEntity({
    required String id,
    required String title,
    @Default(0) int order,
    @Default(<LectureEntity>[]) List<LectureEntity> lectures,
  }) = _CourseSectionEntity;

  int get lectureCount => lectures.length;
  int get totalDurationSeconds =>
      lectures.fold(0, (sum, l) => sum + l.durationSeconds);

  /// `1h 24min` / `45min` / `12s`.
  String get formattedTotalDuration {
    final h = totalDurationSeconds ~/ 3600;
    final m = (totalDurationSeconds % 3600) ~/ 60;
    final t = L10n.current;
    if (h > 0) return t.durationHM('$h', '$m');
    if (m > 0) return t.durationM('$m');
    return t.durationS('$totalDurationSeconds');
  }
}
