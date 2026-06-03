import 'package:freezed_annotation/freezed_annotation.dart';

part 'instructor_entity.freezed.dart';

/// Domain entity for one instructor / publisher in the catalogue.
///
/// An "instructor" can be a single human teacher OR a publishing entity
/// (e.g. Legacy Learning Systems, Hal Leonard). The data model treats both
/// the same — only the [tagline] and [websiteUrl] tend to differ.
@freezed
abstract class InstructorEntity with _$InstructorEntity {
  const InstructorEntity._();

  const factory InstructorEntity({
    required String id,
    required String name,

    /// Square avatar / logo. Square images render best in the detail header.
    required String photoUrl,

    /// Full multi-paragraph "About" body shown under the show-more toggle.
    required String bio,

    /// One-line subtitle under the name (e.g. "Bringing Dreams Within Reach").
    String? tagline,

    /// `guitar` | `piano` | `violin` | null (e.g. for publisher entities).
    String? primaryInstrument,
    @Default(<String>[]) List<String> specialties,
    int? yearsExperience,
    String? country,
    @Default(0.0) double rating,
    @Default(0) int reviewCount,
    @Default(0) int studentCount,
    DateTime? joinedAt,
    @Default(<String>[]) List<String> featuredCourseIds,

    // Social links — null when not set.
    String? websiteUrl,
    String? facebookUrl,
    String? twitterUrl,
    String? youtubeUrl,
    String? instagramUrl,
  }) = _InstructorEntity;

  /// True iff at least one social link is configured. Drives whether the
  /// "Links" section renders on the detail page.
  bool get hasAnySocialLink =>
      (websiteUrl?.isNotEmpty ?? false) ||
      (facebookUrl?.isNotEmpty ?? false) ||
      (twitterUrl?.isNotEmpty ?? false) ||
      (youtubeUrl?.isNotEmpty ?? false) ||
      (instagramUrl?.isNotEmpty ?? false);
}
