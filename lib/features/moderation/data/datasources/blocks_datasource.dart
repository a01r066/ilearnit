import 'package:cloud_firestore/cloud_firestore.dart';

/// Coordinates reads + writes for the per-user block list:
/// `users/{uid}/blocks/{blockedUid}`.
///
/// **Why per-user, not a flat collection.** Block lists are private
/// to the blocker — nobody else should see or query them. A
/// subcollection under the owner doc gives owner-only Firestore rules
/// for free.
///
/// **Why doc-per-block instead of an array on the user doc.** Blocks
/// grow without bound and arrays don't scale (Firestore caps array
/// fields at 20K bytes ≈ a few hundred uids before write contention
/// kicks in). One doc per block is also queryable, which we don't use
/// today but is cheap to keep available.
class BlocksDataSource {
  BlocksDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _blocks(String ownerUid) =>
      _firestore.collection('users').doc(ownerUid).collection('blocks');

  /// Live stream of blocked uids. Drives the in-list filter in every
  /// UGC surface so reviews / Q&A / notes from blocked authors
  /// disappear without a roundtrip.
  Stream<Set<String>> watch({required String ownerUid}) =>
      _blocks(ownerUid).snapshots().map(
            (snap) => snap.docs.map((d) => d.id).toSet(),
          );

  Future<void> block({
    required String ownerUid,
    required String blockedUid,
    String blockedName = '',
  }) {
    if (ownerUid == blockedUid) {
      // Defensive — a user blocking themselves is meaningless and
      // would silently hide their own content. Treat as a no-op.
      return Future.value();
    }
    return _blocks(ownerUid).doc(blockedUid).set({
      'blockedAt': FieldValue.serverTimestamp(),
      'blockedName': blockedName,
    });
  }

  Future<void> unblock({
    required String ownerUid,
    required String blockedUid,
  }) =>
      _blocks(ownerUid).doc(blockedUid).delete();
}
