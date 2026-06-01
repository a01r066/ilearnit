import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../../../shared/providers/storage_providers.dart';
import '../../data/datasources/search_remote_datasource.dart';
import 'search_notifier.dart';
import 'search_state.dart';

final searchRemoteDataSourceProvider = Provider<SearchRemoteDataSource>(
  (ref) => SearchRemoteDataSource(firestore: ref.watch(firestoreProvider)),
);

/// Auto-dispose so navigating away clears the in-memory state. The
/// notifier re-hydrates recent searches on next mount.
final searchNotifierProvider =
    StateNotifierProvider.autoDispose<SearchNotifier, SearchState>(
  (ref) => SearchNotifier(
    remote: ref.watch(searchRemoteDataSourceProvider),
    prefs: ref.watch(prefsProvider),
  ),
);
