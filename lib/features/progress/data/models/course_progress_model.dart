import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/data/models/user_model.dart' show TimestampConverter;
import '../../domain/entities/course_progress.dart';

part 'course_progress_model.freezed.dart';
part 'course_progress_model.g.dart';

/// Firestore DTO for `users/{uid}/courseProgress/{courseId}`.
@freezed
abstract class CourseProgressModel with _$CourseProgressModel {
  const CourseProgressModel._();

  const factory CourseProgressModel({
    required String id, // == courseId
    @Default('') String title,
    String? thumbnailUrl,
    String? lastWatchedLectureId,
    String? lastWatchedSectionId,
    @TimestampConverter() DateTime? lastWatchedAt,
    @Default(0) int completedCount,
    @Default(0) int totalLectures,
  }) = _CourseProgressModel;

  factory CourseProgressModel.fromJson(Map<String, dynamic> json) =>
      _$CourseProgressModelFromJson(json);

  factory CourseProgressModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return CourseProgressModel.fromJson({...data, 'id': doc.id});
  }

  CourseProgress toEntity() => CourseProgress(
        courseId: id,
        title: title,
        thumbnailUrl: thumbnailUrl,
        lastWatchedLectureId: lastWatchedLectureId,
        lastWatchedSectionId: lastWatchedSectionId,
        lastWatchedAt: lastWatchedAt,
        completedCount: completedCount,
        totalLectures: totalLectures,
      );

  // ---------- Computed getters --------------------------------------------
  //
  // Duplicated from [CourseProgress] so the UI can read them off the model
  // without an extra `.toEntity()` call. Match the entity's semantics
  // exactly — see `lecture_progress.md` for the contract.

  /// 0..1 — drives the LinearProgressIndicator + percentage label.
  double get fractionComplete {
    if (totalLectures <= 0) return 0;
    return (completedCount / totalLectures).clamp(0.0, 1.0);
  }

  /// True once the user has any tracked activity on the course.
  bool get hasStarted => lastWatchedAt != null || completedCount > 0;

  /// True only when every lecture is completed.
  bool get isFinished =>
      totalLectures > 0 && completedCount >= totalLectures;
}
