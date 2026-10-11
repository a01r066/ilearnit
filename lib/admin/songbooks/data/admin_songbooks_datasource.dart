import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../features/songbooks/data/models/songbook_model.dart';

/// Admin/CRUD side of the `songbooks` collection.
///
/// The consumer-facing [`SongbooksDataSource`] in `features/songbooks/data/`
/// is read-only. This datasource adds the mutations and admin-scoped
/// queries the admin portal needs, mirroring the pattern of
/// [`AdminCoursesDataSource`].
class AdminSongbooksDataSource {
  AdminSongbooksDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _songbooks =>
      _firestore.collection(FirestoreCollections.songbooks);

  CollectionReference<Map<String, dynamic>> _reviews(String songbookId) =>
      _songbooks
          .doc(songbookId)
          .collection(FirestoreCollections.songbookReviews);

  // ---------- queries -----------------------------------------------------

  Stream<List<SongbookModel>> watchAll({int limit = 200}) => _songbooks
      .orderBy('publishedAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(SongbookModel.fromDoc).toList());

  Stream<SongbookModel?> watchById(String id) =>
      _songbooks.doc(id).snapshots().map(
            (doc) => doc.exists ? SongbookModel.fromDoc(doc) : null,
          );

  // ---------- mutations ---------------------------------------------------

  /// Create a new songbook. Returns the generated id. The caller is
  /// responsible for setting the metadata correctly.
  Future<String> create(SongbookModel model) async {
    final doc = _songbooks.doc();
    final withId = model.copyWith(id: doc.id);
    final json = withId.toJson()..remove('id');
    json['createdAt'] = FieldValue.serverTimestamp();
    json['publishedAt'] ??= FieldValue.serverTimestamp();
    await doc.set(json);
    return doc.id;
  }

  Future<void> update(SongbookModel model) async {
    final json = model.toJson()..remove('id');
    json['updatedAt'] = FieldValue.serverTimestamp();
    await _songbooks.doc(model.id).update(json);
  }

  /// Hard-delete a songbook and cascade its reviews subcollection.
  Future<void> delete(String songbookId) async {
    final reviews = await _reviews(songbookId).get();
    for (final r in reviews.docs) {
      await r.reference.delete();
    }
    await _songbooks.doc(songbookId).delete();
  }

  /// Commerce fields kept outside [SongbookModel] (no codegen needed):
  /// `pdfPath` — `gs://` ref of the paid PDF; `priceUsd` — list price used
  /// for the revenue ledger.
  Stream<({String? pdfPath, double? priceUsd})> watchCommerce(String id) =>
      _songbooks.doc(id).snapshots().map((doc) {
        final d = doc.data() ?? const <String, dynamic>{};
        return (
          pdfPath: d['pdfPath'] as String?,
          priceUsd: (d['priceUsd'] as num?)?.toDouble(),
        );
      });

  Future<void> setCommerce(
    String id, {
    String? pdfPath,
    double? priceUsd,
  }) =>
      _songbooks.doc(id).update({
        if (pdfPath != null) 'pdfPath': pdfPath,
        if (priceUsd != null) 'priceUsd': priceUsd,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setBestseller(String songbookId, bool value) =>
      _songbooks.doc(songbookId).update({'isBestseller': value});
}
