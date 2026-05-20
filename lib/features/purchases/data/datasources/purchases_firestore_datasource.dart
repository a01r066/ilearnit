import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../models/purchase_model.dart';

/// Persists owned-course records in Firestore and streams ownership state.
///
/// Path: `users/{uid}/purchases/{courseId}` — one doc per owned course.
/// Using the courseId as the doc id makes `hasPurchased(courseId)` a single
/// `.exists` read and dedupes naturally if a restore + a fresh purchase
/// arrive for the same course.
abstract interface class PurchasesFirestoreDataSource {
  Future<void> upsertPurchase({
    required String uid,
    required PurchaseModel purchase,
  });

  Future<List<PurchaseModel>> fetchAll(String uid);

  /// Streams the set of `courseId`s the user owns.
  Stream<Set<String>> ownedCourseIdsStream(String uid);
}

class PurchasesFirestoreDataSourceImpl
    implements PurchasesFirestoreDataSource {
  PurchasesFirestoreDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _purchasesCol(String uid) =>
      _firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .collection('purchases');

  @override
  Future<void> upsertPurchase({
    required String uid,
    required PurchaseModel purchase,
  }) async {
    try {
      await _purchasesCol(uid).doc(purchase.courseId).set(
            purchase.toJson(),
            SetOptions(merge: true),
          );
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to save purchase.',
      );
    }
  }

  @override
  Future<List<PurchaseModel>> fetchAll(String uid) async {
    try {
      final snap = await _purchasesCol(uid).get();
      return snap.docs.map(PurchaseModel.fromDoc).toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to load purchases.');
    }
  }

  @override
  Stream<Set<String>> ownedCourseIdsStream(String uid) =>
      _purchasesCol(uid)
          // Only emit records the platform confirmed — skip `pending` and
          // `failed`. Admin grants are stored with status='purchased' and
          // source='admin', so they're naturally included.
          .where('status', whereIn: ['purchased', 'restored'])
          .snapshots()
          .map((snap) => snap.docs.map((d) => d.id).toSet());
}
