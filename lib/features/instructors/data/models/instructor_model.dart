import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/data/models/user_model.dart' show TimestampConverter;
import '../../domain/entities/instructor_entity.dart';

part 'instructor_model.freezed.dart';
part 'instructor_model.g.dart';

/// Firestore DTO for the `instructors` collection.
@freezed
abstract class InstructorModel with _$InstructorModel {
  const InstructorModel._();

  const factory InstructorModel({
    required String id,
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
