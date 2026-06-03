import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../features/auth/data/models/user_model.dart'
    show TimestampConverter;
import 'application_status.dart';

part 'instructor_application.freezed.dart';
part 'instructor_application.g.dart';

/// A user's application to become an instructor on the platform.
///
/// The Firestore doc lives at `instructor_applications/{uid}` — keyed by the
/// applicant's auth uid so they can only have one open application at a time.
@freezed
abstract class InstructorApplication with _$InstructorApplication {
  const InstructorApplication._();

  const factory InstructorApplication({
    required String id,
    required String userId,
    @Default('') String displayName,
    @Default('') String email,
    @Default('') String bio,

    /// Instrument category ids the applicant wants to teach (`guitar`,
    /// `piano`, `violin`).
    @Default(<String>[]) List<String> instruments,
    int? years,
    String? portfolioUrl,
    @Default(ApplicationStatus.pending)
    @ApplicationStatusConverter()
    ApplicationStatus status,
    String? rejectionReason,
    @TimestampConverter() DateTime? appliedAt,
    @TimestampConverter() DateTime? decidedAt,

    /// uid of the admin who approved / rejected.
    String? decidedBy,
  }) = _InstructorApplication;

  factory InstructorApplication.fromJson(Map<String, dynamic> json) =>
      _$InstructorApplicationFromJson(json);

  factory InstructorApplication.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return InstructorApplication.fromJson({...data, 'id': doc.id});
  }
}

/// Bridges the [ApplicationStatus] enum's string id to/from JSON so the
/// generated freezed/json_serializable code round-trips it as a literal
/// (`"pending"`, `"approved"`, `"rejected"`).
class ApplicationStatusConverter
    implements JsonConverter<ApplicationStatus, String?> {
  const ApplicationStatusConverter();

  @override
  ApplicationStatus fromJson(String? json) => ApplicationStatus.fromId(json);

  @override
  String toJson(ApplicationStatus object) => object.id;
}
