import 'package:cloud_firestore/cloud_firestore.dart';

/// Stamps the accepted EULA version onto the user doc.
///
/// Idempotent — calling [accept] multiple times only writes when the
/// stored version is older than [kCurrentEulaVersion] (the caller
/// passes whichever version they're accepting).
class EulaAcceptanceService {
  EulaAcceptanceService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> accept({
    required String uid,
    required int version,
  }) =>
      _firestore.collection('users').doc(uid).set({
        'eulaAcceptedVersion': version,
        'eulaAcceptedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}
