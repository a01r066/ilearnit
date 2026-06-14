import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/data/models/user_model.dart' show TimestampConverter;
import '../../domain/entities/instructor_entity.dart';

part 'instructor_model.freezed.dart';
part 'instructor_model.g.dart';

/// Firestore DTO for the `instructors` collection.
///
/// **Schema invariant.** `id` IS the user's Firebase Auth UID. The
/// `instructors/{uid}` doc is the public-facing complement to
/// `users/{uid}` — one is private auth/role data, the other is public
/// marketing data, joined by the shared key. This is the schema every
/// marketplace converges on (Tonebase, Udemy, Patreon all do this).
///
/// `course.instructorId` is also the auth UID, so the consumer mobile
/// app reads `instructors/{course.instructorId}` as a direct doc
/// lookup — no bridge field, no fallback query.
@freezed
abstract class InstructorModel with _$InstructorModel {
  const InstructorModel._();

  const factory InstructorModel({
    /// Firebase Auth UID. Doubles as the Firestore doc id.
    required String id,
    /// Contact email. Optional — used by the admin moderator queue
    /// scoping and analytics dashboards. Mirrors `users/{uid}.email`
    /// on creation but is allowed to drift if the instructor changes
    /// their public-facing contact email.
    String? email,
    @Default('') String name,
    @Default('') String photoUrl,
    @Default('') String bio,
    String? tagline,
    String? primaryInstrument,
    @Default(<String>[]) List<String> specialties,
    int? yearsExperience,
    String? country,
    @Default(0.0) double rating,
    @Default(0) int reviewCount,
    @Default(0) int studentCount,
    @TimestampConverter() DateTime? joinedAt,
    @Default(<String>[]) List<String> featuredCourseIds,
    String? websiteUrl,
    String? facebookUrl,
    String? twitterUrl,
    String? youtubeUrl,
    String? instagramUrl,
  }) = _InstructorModel;

  factory InstructorModel.fromJson(Map<String, dynamic> json) =>
      _$InstructorModelFromJson(json);

  factory InstructorModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return InstructorModel.fromJson({...data, 'id': doc.id});
  }

  InstructorEntity toEntity() => InstructorEntity(
        id: id,
        name: name,
        photoUrl: photoUrl,
        bio: bio,
        tagline: tagline,
        primaryInstrument: primaryInstrument,
        specialties: specialties,
        yearsExperience: yearsExperience,
        country: country,
        rating: rating,
        reviewCount: reviewCount,
        studentCount: studentCount,
        joinedAt: joinedAt,
        featuredCourseIds: featuredCourseIds,
        websiteUrl: websiteUrl,
        facebookUrl: facebookUrl,
        twitterUrl: twitterUrl,
        youtubeUrl: youtubeUrl,
        instagramUrl: instagramUrl,
      );

  /// Mirrors [InstructorEntity.hasAnySocialLink] so the detail page can
  /// gate the social-links section directly off the model (saves a
  /// `toEntity()` per build).
  bool get hasAnySocialLink =>
      (websiteUrl?.isNotEmpty ?? false) ||
      (facebookUrl?.isNotEmpty ?? false) ||
      (twitterUrl?.isNotEmpty ?? false) ||
      (youtubeUrl?.isNotEmpty ?? false) ||
      (instagramUrl?.isNotEmpty ?? false);
}
