import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../../data/datasources/wishlist_datasource.dart';
import '../../data/models/wishlist_item_model.dart';

// ---------- Datasource ----------------------------------------------------

final wishlistDataSourceProvider = Provider<WishlistDataSource>(
  (ref) => WishlistDataSource(ref.watch(firestoreProvider)),
);

// ---------- Streams -------------------------------------------------------

/// Just the set of saved course ids. Cheap to consume per-card —
/// every `CourseCard` subscribes via `isCourseWishlistedProvider`.
final wishlistedIdsStreamProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const <String>{});
  return ref
      .watch(wishlistDataSourceProvider)
      .watchIds(userId: user.id);
});

/// Full list with denormalized fields, newest-saved first. Backs the
/// Saved page. AutoDispose because the page is the only consumer.
final wishlistStreamProvider =
    StreamProvider.autoDispose<List<WishlistItemModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref
      .watch(wishlistDataSourceProvider)
      .watchAll(userId: user.id);
});

/// Profile-tile subtitle (e.g. "12 courses").
final wishlistCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);
  return ref
      .watch(wishlistDataSourceProvider)
      .watchCount(userId: user.id);
});

/// Per-course selector. Derived from the ids set so all bookmark
/// buttons share one Firestore listener.
final isCourseWishlistedProvider =
    Provider.family<bool, String>((ref, courseId) {
  final ids = ref.watch(wishlistedIdsStreamProvider).value ??
      const <String>{};
  return ids.contains(courseId);
});

// ---------- Toggle notifier ----------------------------------------------

/// Optimistic-toggle state. We layer the in-flight set on top of the
/// server-truth set from [wishlistedIdsStreamProvider] so the icon
/// flips instantly on tap — even if the round-trip takes 800ms on a
/// flaky connection. Errors roll the optimistic flip back.
@immutable
class WishlistToggleState {
  const WishlistToggleState({
    this.optimisticallyAdded = const <String>{},
    this.optimisticallyRemoved = const <String>{},
    this.lastErrorCourseId,
  });

  final Set<String> optimisticallyAdded;
  final Set<String> optimisticallyRemoved;
  final String? lastErrorCourseId;

  WishlistToggleState copyWith({
    Set<String>? optimisticallyAdded,
    Set<String>? optimisticallyRemoved,
    Object? lastErrorCourseId = _unset,
  }) =>
      WishlistToggleState(
        optimisticallyAdded:
            optimisticallyAdded ?? this.optimisticallyAdded,
        optimisticallyRemoved:
            optimisticallyRemoved ?? this.optimisticallyRemoved,
        lastErrorCourseId: identical(lastErrorCourseId, _unset)
            ? this.lastErrorCourseId
            : lastErrorCourseId as String?,
      );

  static const Object _unset = Object();
}

class WishlistToggleNotifier extends StateNotifier<WishlistToggleState> {
  WishlistToggleNotifier({
    required this.userId,
    required this.datasource,
  }) : super(const WishlistToggleState());

  final String userId;
  final WishlistDataSource datasource;

  Future<void> toggle({
    required CourseEntity course,
    required bool wasOnWishlist,
  }) async {
    if (userId.isEmpty) return;

    final id = course.id;
    state = state.copyWith(
      optimisticallyAdded: !wasOnWishlist
          ? {...state.optimisticallyAdded, id}
          : ({...state.optimisticallyAdded}..remove(id)),
      optimisticallyRemoved: wasOnWishlist
          ? {...state.optimisticallyRemoved, id}
          : ({...state.optimisticallyRemoved}..remove(id)),
      lastErrorCourseId: null,
    );

    try {
      if (wasOnWishlist) {
        await datasource.remove(userId: userId, courseId: id);
      } else {
        await datasource.add(userId: userId, course: course);
      }
      // Clear the optimistic flag for this id — the next Firestore
      // snapshot will now match.
      state = state.copyWith(
        optimisticallyAdded: {...state.optimisticallyAdded}..remove(id),
        optimisticallyRemoved: {...state.optimisticallyRemoved}..remove(id),
      );
    } catch (_) {
      // Roll back the optimistic flip.
      state = state.copyWith(
        optimisticallyAdded: {...state.optimisticallyAdded}..remove(id),
        optimisticallyRemoved: {...state.optimisticallyRemoved}..remove(id),
        lastErrorCourseId: id,
      );
    }
  }
}

final wishlistToggleNotifierProvider =
    StateNotifierProvider<WishlistToggleNotifier, WishlistToggleState>(
  (ref) {
    final user = ref.watch(currentUserProvider);
    return WishlistToggleNotifier(
      userId: user?.id ?? '',
      datasource: ref.watch(wishlistDataSourceProvider),
    );
  },
);

/// Final answer: should the bookmark icon look saved RIGHT NOW?
///
/// Composition: server-truth ids ± optimistic overlay. The bookmark
/// button reads this so it never goes out of sync with its own tap.
final effectiveWishlistedProvider =
    Provider.family<bool, String>((ref, courseId) {
  final serverIds = ref.watch(wishlistedIdsStreamProvider).value ??
      const <String>{};
  final overlay = ref.watch(wishlistToggleNotifierProvider);
  if (overlay.optimisticallyAdded.contains(courseId)) return true;
  if (overlay.optimisticallyRemoved.contains(courseId)) return false;
  return serverIds.contains(courseId);
});
