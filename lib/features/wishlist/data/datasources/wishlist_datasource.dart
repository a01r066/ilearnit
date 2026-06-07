import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../models/wishlist_item_model.dart';

/// Persistence for `users/{uid}/wishlist/{courseId}`.
///
/// The doc id intentionally equals the course id so `add` / `remove` /
/// `isOnWishlist` are O(1) without an extra query.
class WishlistDataSource {
  WishlistDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String userId) => _firestore
      .collection(FirestoreCollections.users)
      .doc(userId)
      .collection('wishlist');

  /// Full list, newest-saved first. Backs the "Saved" page.
  Stream<List<WishlistItemModel>> watchAll({required String userId}) =>
      _col(userId)
          .orderBy('savedAt', descending: true)
          .snapshots()
          .map((snap) =>
              snap.docs.map(WishlistItemModel.fromDoc).toList());

  /// Just the set of saved course ids. Cheaper than [watchAll] because
  /// the UI bookmark toggle only needs the membership check — every
  /// `CourseCard` and `CourseDetailPage` subscribes to this.
  Stream<Set<String>> watchIds({required String userId}) =>
      _col(userId).snapshots().map(
            (snap) => snap.docs.map((d) => d.id).toSet(),
          );

  /// One-shot count for the Profile tile subtitle.
  Stream<int> watchCount({required String userId}) =>
      _col(userId).snapshots().map((snap) => snap.size);

  /// Save a course. Denormalizes the handful of fields the Saved page
  /// renders. Idempotent — re-running on an already-saved course is a
  /// no-op that refreshes the denormalized fields.
  Future<void> add({
    required String userId,
    required CourseEntity course,
  }) =>
      _col(userId).doc(course.id).set(
        {
          'courseId': course.id,
          'title': course.title,
          'thumbnailUrl': course.thumbnailUrl,
          'instructorName': course.instructorName,
          'priceTier': course.priceTier.id,
          'savedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

  /// Lower-level overload used by the price-drop Cloud Function backfill
  /// (and any future "save from a card we don't yet have a CourseEntity
  /// for" path).
  Future<void> addRaw({
    required String userId,
    required String courseId,
    required String title,
    String? thumbnailUrl,
    required String instructorName,
    required String priceTier,
  }) =>
      _col(userId).doc(courseId).set(
        {
          'courseId': courseId,
          'title': title,
          'thumbnailUrl': thumbnailUrl,
          'instructorName': instructorName,
          'priceTier': priceTier,
          'savedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

  Future<void> remove({
    required String userId,
    required String courseId,
  }) =>
      _col(userId).doc(courseId).delete();
}
