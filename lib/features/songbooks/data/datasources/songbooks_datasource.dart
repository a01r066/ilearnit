import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/songbook_model.dart';
import '../models/songbook_review_model.dart';

/// Firestore reader for the `songbooks` collection.
///
/// Songbooks are catalogue items: we read with `snapshots()` for live
/// updates so a publisher pushing a new title appears without a refresh.
class SongbooksDataSource {
  SongbooksDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _books =>
      _firestore.collection(FirestoreCollections.songbooks);

  Stream<List<SongbookModel>> watchAll({int limit = 60}) => _books
      .orderBy('publishedAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(SongbookModel.fromDoc).toList());

  Stream<List<SongbookModel>> watchBestsellers({int limit = 12}) => _books
      .where('isBestseller', isEqualTo: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(SongbookModel.fromDoc).toList());

  Stream<SongbookModel?> watchById(String id) =>
      _books.doc(id).snapshots().map(
            (doc) => doc.exists ? SongbookModel.fromDoc(doc) : null,
          );

  Future<SongbookModel?> fetchById(String id) async {
    final snap = await _books.doc(id).get();
    if (!snap.exists) return null;
    return SongbookModel.fromDoc(snap);
  }

  /// Fetch a list of songbooks by ids in the requested order. Used to
  /// hydrate the "Recently viewed" carousel from the cached id list.
  Future<List<SongbookModel>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    // Firestore `whereIn` is limited to 30; for our limit of 12 we're fine.
    final snap = await _books.where(FieldPath.documentId, whereIn: ids).get();
    final byId = {
      for (final doc in snap.docs) doc.id: SongbookModel.fromDoc(doc),
    };
    return ids
        .map((id) => byId[id])
        .whereType<SongbookModel>()
        .toList();
  }

  /// Similar-songbooks query — same instrument, exclude self.
  Stream<List<SongbookModel>> watchSimilar(SongbookModel self,
      {int limit = 8}) {
    return _books
        .where('instrument', isEqualTo: self.instrument)
        .limit(limit + 1)
        .snapshots()
        .map((s) => s.docs
            .map(SongbookModel.fromDoc)
            .where((b) => b.id != self.id)
            .take(limit)
            .toList());
  }

  Stream<List<SongbookReviewModel>> watchReviews(String id, {int limit = 20}) {
    return _books
        .doc(id)
        .collection(FirestoreCollections.songbookReviews)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(SongbookReviewModel.fromDoc).toList());
  }
}
