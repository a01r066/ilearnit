import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/data/models/user_model.dart' show TimestampConverter;
import '../../../courses/domain/entities/instrument_category.dart';
import '../../domain/entities/learning_path.dart';

part 'learning_path_model.freezed.dart';
part 'learning_path_model.g.dart';

/// Firestore DTO for `learning_paths/{pathId}`.
///
/// `instrument` is stored as the [InstrumentCategory.id] string so docs
/// are stable across enum reorderings. Nullable for "mixed instrument"
/// paths.
@freezed
abstract class LearningPathModel with _$LearningPathModel {
  const LearningPathModel._();

  const factory LearningPathModel({
    required String id,
    @Default('') String title,
    @Default('') String summary,
    String? coverUrl,
    String? instrument,
    @Default(<String>[]) List<String> courseIds,
    @Default(0) double totalHours,
    @Default(true) bool isPublished,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  }) = _LearningPathModel;

  factory LearningPathModel.fromJson(Map<String, dynamic> json) =>
      _$LearningPathModelFromJson(json);

  factory LearningPathModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return LearningPathModel.fromJson({...data, 'id': doc.id});
  }

  LearningPath toEntity() => LearningPath(
        id: id,
        title: title,
        summary: summary,
        coverUrl: coverUrl,
        instrument: instrument == null
            ? null
            : InstrumentCategory.fromId(instrument!),
        courseIds: courseIds,
        totalHours: totalHours,
        isPublished: isPublished,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
