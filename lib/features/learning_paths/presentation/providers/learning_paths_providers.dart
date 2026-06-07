import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../../courses/domain/entities/instrument_category.dart';
import '../../data/datasources/learning_paths_datasource.dart';
import '../../data/models/learning_path_model.dart';

final learningPathsDataSourceProvider =
    Provider<LearningPathsDataSource>(
  (ref) => LearningPathsDataSource(ref.watch(firestoreProvider)),
);

/// Published paths, newest-first. Backs the Home rail.
final learningPathsStreamProvider =
    StreamProvider.autoDispose<List<LearningPathModel>>(
  (ref) => ref.watch(learningPathsDataSourceProvider).watchAll(),
);

/// Single path for the detail screen.
final learningPathByIdProvider =
    StreamProvider.autoDispose.family<LearningPathModel?, String>(
  (ref, id) =>
      ref.watch(learningPathsDataSourceProvider).watchById(id),
);

/// Optional helper for instrument-specific rails.
final learningPathsByInstrumentProvider = StreamProvider.autoDispose
    .family<List<LearningPathModel>, InstrumentCategory>(
  (ref, category) => ref
      .watch(learningPathsDataSourceProvider)
      .watchByInstrument(category),
);
