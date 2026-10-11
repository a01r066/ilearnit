import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/__entity___model.dart';

/// Talks to Firestore. Throws on failure — the repository maps errors.
/// Privileged mutations (anything rules deny to clients) go through a
/// callable instead of a direct write.
class __Feature__RemoteDataSource {
  __Feature__RemoteDataSource(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('__feature__');

  Stream<List<__Entity__Model>> watchAll(String uid) => _col(uid)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(__Entity__Model.fromDoc).toList());

  Future<void> create(String uid, String title) => _col(uid).add({
        'ownerId': uid,
        'title': title,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> delete(String uid, String id) => _col(uid).doc(id).delete();
}
