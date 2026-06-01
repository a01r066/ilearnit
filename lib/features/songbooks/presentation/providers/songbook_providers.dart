import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../../../shared/providers/storage_providers.dart';
import '../../data/datasources/songbooks_datasource.dart';
import '../../data/models/songbook_model.dart';
import '../../data/models/songbook_review_model.dart';

final songbooksDataSourceProvider = Provider<SongbooksDataSource>(
  (ref) => SongbooksDataSource(firestore: ref.watch(firestoreProvider)),
);

// ---------- List ----------------------------------------------------------

/// Bestsellers — drives the bottom carousel on the Songbooks tab.
final bestsellersStreamProvider = StreamProvider<List<SongbookModel>>(
  (ref) => ref.watch(songbooksDataSourceProvider).watchBestsellers(),
);

/// Full catalogue (capped) — used by search + grid views.
final allSongbooksStreamProvider = StreamProvider<List<SongbookModel>>(
  (ref) => ref.watch(songbooksDataSourceProvider).watchAll(),
);

/// Recently viewed songbooks — hydrated from PrefsService MRU ids.
///
/// FutureProvider rather than Stream because the MRU list is local and
/// only refreshed on detail page open. Use `ref.invalidate` to force a
/// re-fetch after a detail visit (we do that from the detail page).
final recentlyViewedSongbooksProvider =
    FutureProvider<List<SongbookModel>>((ref) async {
  final prefs = ref.watch(prefsProvider);
  final ids = prefs.recentSongbookIds;
  if (ids.isEmpty) return const [];
  return ref.watch(songbooksDataSourceProvider).fetchByIds(ids);
});

// ---------- Detail --------------------------------------------------------

/// Detail page binding — live stream so a server-side rating bump shows
/// up while the user is reading.
final songbookByIdProvider =
    StreamProvider.family.autoDispose<SongbookModel?, String>(
  (ref, id) => ref.watch(songbooksDataSourceProvider).watchById(id),
);

/// "You might also like" carousel on the detail page.
final similarSongbooksProvider = StreamProvider.family
    .autoDispose<List<SongbookModel>, String>((ref, id) async* {
  final book = await ref.watch(songbooksDataSourceProvider).fetchById(id);
  if (book == null) {
    yield const [];
    return;
  }
  yield* ref.watch(songbooksDataSourceProvider).watchSimilar(book);
});

/// Reviews on the detail page.
final songbookReviewsProvider = StreamProvider.family
    .autoDispose<List<SongbookReviewModel>, String>(
  (ref, id) => ref.watch(songbooksDataSourceProvider).watchReviews(id),
);
