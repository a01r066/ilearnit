import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/data/models/user_model.dart' show TimestampConverter;
import '../../domain/entities/report.dart';
import '../../domain/entities/report_content_type.dart';
import '../../domain/entities/report_reason.dart';
import '../../domain/entities/report_status.dart';

part 'report_model.freezed.dart';
part 'report_model.g.dart';

/// Firestore DTO for `reports/{reportId}`.
///
/// Enums are stored as their stable `.id` strings so renaming the Dart
/// enum cases is a zero-migration change.
@freezed
abstract class ReportModel with _$ReportModel {
  const ReportModel._();

  const factory ReportModel({
    required String id,
    @Default('review') String contentType,
    @Default('') String contentId,
    @Default('') String contentPath,
    String? courseId,
    String? lectureId,
    @Default('') String contentSnapshot,
    @Default('') String authorId,
    @Default('') String authorName,
    @Default('') String reporterId,
    @Default('') String reporterName,
    @Default('other') String reason,
    @Default('') String reporterNotes,
    @Default('open') String status,
    String? reviewedBy,
    String? reviewedByName,
    @TimestampConverter() DateTime? reviewedAt,
    @Default('') String resolutionNotes,
    @TimestampConverter() DateTime? createdAt,
  }) = _ReportModel;

  factory ReportModel.fromJson(Map<String, dynamic> json) =>
      _$ReportModelFromJson(json);

  factory ReportModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ReportModel.fromJson({...data, 'id': doc.id});
  }

  Report toEntity() => Report(
        id: id,
        contentType: ReportContentType.fromId(contentType),
        contentId: contentId,
        contentPath: contentPath,
        courseId: courseId,
        lectureId: lectureId,
        contentSnapshot: contentSnapshot,
        authorId: authorId,
        authorName: authorName,
        reporterId: reporterId,
        reporterName: reporterName,
        reason: ReportReason.fromId(reason),
        reporterNotes: reporterNotes,
        status: ReportStatus.fromId(status),
        reviewedBy: reviewedBy,
        reviewedByName: reviewedByName,
        reviewedAt: reviewedAt,
        resolutionNotes: resolutionNotes,
        createdAt: createdAt,
      );
}
