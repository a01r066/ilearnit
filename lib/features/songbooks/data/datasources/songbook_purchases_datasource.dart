import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/constants/api_endpoints.dart';

class SongbookContentException implements Exception {
  const SongbookContentException(this.code, this.message);
  final String code;
  final String message;

  bool get isLocked =>
      code == 'permission-denied' || code == 'unauthenticated';

  @override
  String toString() => '[$code] $message';
}

/// Read side of songbook ownership + the signed-URL resolver.
///
/// Ownership docs (`users/{uid}/songbooks/{songbookId}`) are written only
/// by the `verifySongbookPurchase` Cloud Function; the PDF is private and
/// served through `resolveSongbookContent`.
class SongbookPurchasesDataSource {
  SongbookPurchasesDataSource({
    required FirebaseFirestore firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<Set<String>> ownedSongbookIds(String uid) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .collection('songbooks')
      .where('status', isEqualTo: 'purchased')
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toSet());

  /// Whether the admin has uploaded the paid PDF (`songbooks/{id}.pdfPath`).
  /// Read raw so [SongbookModel] doesn't need regenerating.
  Stream<bool> hasContent(String songbookId) => _firestore
      .collection(FirestoreCollections.songbooks)
      .doc(songbookId)
      .snapshots()
      .map((d) => ((d.data()?['pdfPath'] as String?) ?? '').isNotEmpty);

  Future<String> resolveContent(String songbookId) async {
    try {
      final res = await _functions
          .httpsCallable('resolveSongbookContent')
          .call<Object?>(<String, dynamic>{'songbookId': songbookId});
      return (Map<String, dynamic>.from(res.data! as Map))['url'] as String;
    } on FirebaseFunctionsException catch (e) {
      throw SongbookContentException(e.code, e.message ?? e.code);
    }
  }
}
