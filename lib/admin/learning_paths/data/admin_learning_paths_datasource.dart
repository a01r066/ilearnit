import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../features/learning_paths/data/models/learning_path_model.dart';

/// Admin-side CRUD for `learning_paths/{pathId}`.
///
/// Intentionally separate from the consumer
/// [LearningPathsDataSource] — keeping the write surface here means a
/// student can't accidentally end up with a method that does Firestore
/// writes through `tree-shaking` failures.
class AdminLearningPathsDataSource {
  AdminLearningPathsDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.learningPaths);

  /// Every path, draft + published, newest first. The admin list shows
  /// both so editors can find a draft they parked yesterday.
  Stream<List<LearningPathModel>> watchAll() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map(LearningPathModel.fromDoc).toList());

  Stream<LearningPathModel?> watchById(String pathId) =>
      _col.doc(pathId).snapshots().map(
            (snap) =>
                snap.exists ? LearningPathModel.fromDoc(snap) : null,
          );

  /// Create a fresh draft. Returns the new doc id so the caller can
  /// route to the editor.
  Future<String> create({
    required String title,
    required String summary,
    String? coverUrl,
    String? instrumentId,
    required List<String> courseIds,
    required double totalHours,
    bool isPublished = false,
  }) async {
    final ref = _col.doc();
    await ref.set({
      'title': title,
      'summary': summary,
      'coverUrl': coverUrl,
      'instrument': instrumentId,
      'courseIds': courseIds,
      'totalHours': totalHours,
      'isPublished': isPublished,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Partial update. Pass only the keys you want to change — `null` for
  /// every other field skips it. Bumps `updatedAt` regardless.
  Future<void> update({
    required String pathId,
    String? title,
    String? summary,
    String? coverUrl,
    String? instrumentId,
    List<String>? courseIds,
    double? totalHours,
    bool? isPublished,
  }) {
    final payload = <String, dynamic>{
      if (title != null) 'title': title,
      if (summary != null) 'summary': summary,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (instrumentId != null) 'instrument': instrumentId,
      if (courseIds != null) 'courseIds': courseIds,
      if (totalHours != null) 'totalHours': totalHours,
      if (isPublished != null) 'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    return _col.doc(pathId).set(payload, SetOptions(merge: true));
  }

  Future<void> delete(String pathId) => _col.doc(pathId).delete();
}
