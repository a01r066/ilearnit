import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../courses/domain/entities/instrument_category.dart';
import '../models/learning_path_model.dart';

/// Read-only consumer view of `learning_paths/{pathId}`.
///
/// Admin CRUD lives in `lib/admin/learning_paths/` so the consumer
/// datasource can't accidentally expose a write surface to non-admin
/// users.
class LearningPathsDataSource {
  LearningPathsDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.learningPaths);

  /// Every published path, newest first. Used by the Home rail.
  Stream<List<LearningPathModel>> watchAll({int limit = 20}) =>
      _col
          .where('isPublished', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map(LearningPathModel.fromDoc).toList(),
          );

  /// Single path for the detail page. Streams so admin edits surface
  /// without a manual refresh.
  Stream<LearningPathModel?> watchById(String pathId) =>
      _col.doc(pathId).snapshots().map(
            (snap) =>
                snap.exists ? LearningPathModel.fromDoc(snap) : null,
          );

  /// Filtered by instrument — exposed for instrument-detail and any
  /// future "More paths for piano" rails.
  Stream<List<LearningPathModel>> watchByInstrument(
    InstrumentCategory category, {
    int limit = 10,
  }) =>
      _col
          .where('isPublished', isEqualTo: true)
          .where('instrument', isEqualTo: category.id)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map(LearningPathModel.fromDoc).toList(),
          );
}
