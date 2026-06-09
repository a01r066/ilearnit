import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../features/instructors/data/models/instructor_model.dart';

/// Admin write methods for the public-facing `instructors` collection.
///
/// The consumer side reads via `InstructorsDataSource` (read-only).
/// This class adds create / update / delete used by the admin portal.
class AdminInstructorProfilesDataSource {
  AdminInstructorProfilesDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.instructors);

  // ----- Reads (mirrored here so admin pages can stream/filter
  //              without reaching across to the consumer datasource) ---

  Stream<List<InstructorModel>> watchAll() => _col
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(InstructorModel.fromDoc).toList());

  Stream<InstructorModel?> watchById(String id) =>
      _col.doc(id).snapshots().map(
            (d) => d.exists ? InstructorModel.fromDoc(d) : null,
          );

  // ----- Writes ------------------------------------------------------

  /// Create a new instructor profile. Returns the doc id.
  ///
  /// We let Firestore generate the id rather than reusing the auth
  /// uid because instructor *profiles* and *user accounts* are
  /// separate concepts — a marketing profile may exist for a guest
  /// instructor who never signs in.
  Future<String> create(InstructorModel m) async {
    final ref = _col.doc();
    await ref.set(_toPayload(m, joinedAt: m.joinedAt ?? DateTime.now()));
    return ref.id;
  }

  Future<void> update(InstructorModel m) =>
      _col.doc(m.id).set(_toPayload(m), SetOptions(merge: true));

  Future<void> delete(String id) => _col.doc(id).delete();

  // ----- Helpers -----------------------------------------------------

  /// Hand-rolled serialiser — we drop the `id` field (it's the doc id),
  /// and stamp `joinedAt` as a server Timestamp on create.
  Map<String, dynamic> _toPayload(
    InstructorModel m, {
    DateTime? joinedAt,
  }) {
    return {
      'name': m.name,
      'photoUrl': m.photoUrl,
      'bio': m.bio,
      if (m.tagline != null) 'tagline': m.tagline,
      if (m.primaryInstrument != null)
        'primaryInstrument': m.primaryInstrument,
      'specialties': m.specialties,
      if (m.yearsExperience != null) 'yearsExperience': m.yearsExperience,
      if (m.country != null) 'country': m.country,
      'rating': m.rating,
      'reviewCount': m.reviewCount,
      'studentCount': m.studentCount,
      'featuredCourseIds': m.featuredCourseIds,
      if (m.websiteUrl != null) 'websiteUrl': m.websiteUrl,
      if (m.facebookUrl != null) 'facebookUrl': m.facebookUrl,
      if (m.twitterUrl != null) 'twitterUrl': m.twitterUrl,
      if (m.youtubeUrl != null) 'youtubeUrl': m.youtubeUrl,
      if (m.instagramUrl != null) 'instagramUrl': m.instagramUrl,
      if (joinedAt != null) 'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}
