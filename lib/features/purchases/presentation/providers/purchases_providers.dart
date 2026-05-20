import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/iap_remote_datasource.dart';
import '../../data/datasources/purchases_firestore_datasource.dart';
import '../../data/repositories/purchases_repository_impl.dart';
import '../../domain/repositories/purchases_repository.dart';
import 'purchases_notifier.dart';
import 'purchases_state.dart';

final iapRemoteDataSourceProvider = Provider<IapRemoteDataSource>(
  (_) => IapRemoteDataSourceImpl(),
);

final purchasesFirestoreDataSourceProvider =
    Provider<PurchasesFirestoreDataSource>(
  (ref) => PurchasesFirestoreDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
  ),
);

final purchasesRepositoryProvider = Provider<PurchasesRepository>(
  (ref) => PurchasesRepositoryImpl(
    iap: ref.watch(iapRemoteDataSourceProvider),
    firestore: ref.watch(purchasesFirestoreDataSourceProvider),
    auth: ref.watch(firebaseAuthProvider),
  ),
);

/// Keep-alive — the platform purchase stream subscription must outlive
/// route changes. We eager-initialize this from `bootstrap.dart`.
final purchasesNotifierProvider =
    StateNotifierProvider<PurchasesNotifier, PurchasesState>(
  (ref) => PurchasesNotifier(ref.watch(purchasesRepositoryProvider)),
);

/// Streams the set of course IDs the signed-in user owns. Rebuilds when
/// auth changes (sign-out → empty set).
final ownedCourseIdsProvider = StreamProvider<Set<String>>((ref) {
  // Tie the stream's lifetime to the signed-in user — sign-out closes it.
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(<String>{});
  return ref.watch(purchasesRepositoryProvider).ownedCourseIds();
});

/// Family — true iff the user has purchased [courseId]. Pure selector.
final isCoursePurchasedProvider =
    Provider.family.autoDispose<bool, String>((ref, courseId) {
  final owned =
      ref.watch(ownedCourseIdsProvider).value ?? const <String>{};
  return owned.contains(courseId);
});
