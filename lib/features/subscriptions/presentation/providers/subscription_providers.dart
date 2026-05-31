import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../purchases/presentation/providers/purchases_providers.dart';
import '../../data/datasources/subscription_firestore_datasource.dart';
import 'subscription_notifier.dart';
import 'subscription_state.dart';

final subscriptionFirestoreDataSourceProvider =
    Provider<SubscriptionFirestoreDataSource>(
  (ref) => SubscriptionFirestoreDataSource(
    firestore: ref.watch(firestoreProvider),
  ),
);

/// Keep-alive — the IAP stream subscription must outlive route changes.
/// Eager-initialize from `bootstrap.dart`.
final subscriptionNotifierProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier(
    iap: ref.watch(iapRemoteDataSourceProvider),
    firestore: ref.watch(subscriptionFirestoreDataSourceProvider),
    user: ref.watch(currentUserProvider),
  );
});

/// True iff the user currently has an active Personal Plan subscription.
/// Cheap selector — the course gate reads this.
final hasActiveSubscriptionProvider = Provider<bool>(
  (ref) => ref.watch(subscriptionNotifierProvider).hasActiveSubscription,
);
