import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/data/models/user_model.dart' show TimestampConverter;
import '../../domain/entities/lecture_note.dart';

part 'lecture_note_model.freezed.dart';
part 'lecture_note_model.g.dart';

/// Firestore DTO for `users/{uid}/notes/{noteId}`.
@freezed
abstract class LectureNoteModel with _$LectureNoteModel {
  const LectureNoteModel._();

  const factory LectureNoteModel({
    required String id,
    @Default('') String userId,
    @Default('') String courseId,
    @Default('') String courseTitle,
    String? courseThumbnailUrl,
    @Default('') String sectionId,
    @Default('') String lectureId,
    @Default('') String lectureTitle,
    @Default('') String body,
    int? timestampSec,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  }) = _LectureNoteModel;

  factory LectureNoteModel.fromJson(Map<String, dynamic> json) =>
      _$LectureNoteModelFromJson(json);

  factory LectureNoteModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return LectureNoteModel.fromJson({...data, 'id': doc.id});
  }

  LectureNote toEntity() => LectureNote(
        id: id,
        userId: userId,
        courseId: courseId,
        courseTitle: courseTitle,
        courseThumbnailUrl: courseThumbnailUrl,
        sectionId: sectionId,
        lectureId: lectureId,
        lectureTitle: lectureTitle,
        body: body,
        timestampSec: timestampSec,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
