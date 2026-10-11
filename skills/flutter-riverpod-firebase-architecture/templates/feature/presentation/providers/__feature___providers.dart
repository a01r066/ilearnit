import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/providers/core_providers.dart';
import '../../data/datasources/__feature___remote_datasource.dart';
import '../../data/repositories/__feature___repository_impl.dart';
import '../../domain/entities/__entity__.dart';
import '../../domain/repositories/__feature___repository.dart';
import '__feature___notifier.dart';
import '__feature___state.dart';

// ---- DI ------------------------------------------------------------------

final __entityCamel__RemoteDataSourceProvider = Provider<__Feature__RemoteDataSource>(
  (ref) => __Feature__RemoteDataSource(ref.watch(firestoreProvider)),
);

final __entityCamel__RepositoryProvider = Provider<__Feature__Repository>(
  (ref) => __Feature__RepositoryImpl(ref.watch(__entityCamel__RemoteDataSourceProvider)),
);

// ---- Reads ---------------------------------------------------------------

/// Empty for guests so no permission-denied errors are thrown.
final __entityCamel__ListProvider = StreamProvider.autoDispose<List<__Entity__>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(__entityCamel__RepositoryProvider).watchAll(user.uid);
});

// ---- Mutations -----------------------------------------------------------

final __entityCamel__NotifierProvider =
    StateNotifierProvider.autoDispose<__Feature__Notifier, __Feature__State>((ref) {
  final user = ref.watch(currentUserProvider);
  return __Feature__Notifier(
    uid: user?.uid ?? '',
    repo: ref.watch(__entityCamel__RepositoryProvider),
  );
});
