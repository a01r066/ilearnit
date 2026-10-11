import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../models/purchase_model.dart';
import '../../../../l10n/l10n.dart';

/// Reads owned-course records from Firestore. Read-only: entitlements are
/// written exclusively by the `verifyPurchase` Cloud Function.
///
/// Path: `users/{uid}/purchases/{courseId}` — one doc per owned course.
/// Using the courseId as the doc id makes `hasPurchased(courseId)` a single
/// `.exists` read and dedupes naturally if a restore + a fresh purchase
/// arrive for the same course.
abstract interface class PurchasesFirestoreDataSource {
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
  Future<List<PurchaseModel>> fetchAll(String uid) async {
    try {
      final snap = await _purchasesCol(uid).get();
      return snap.docs.map(PurchaseModel.fromDoc).toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: L10n.current.errLoadFailed);
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
