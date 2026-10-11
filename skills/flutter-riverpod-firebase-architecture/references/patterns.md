# Patterns and rationale

## Contents
1. Optimistic toggle (favorite / bookmark)
2. Cursor pagination with Firestore
3. Enums with wire values
4. Calling a callable from a datasource
5. Testing notifiers with overrides
6. Offline files (Application Support, backup-excluded)
7. Common mistakes found in review

## 1. Optimistic toggle

Keep server truth in a `StreamProvider<Set<String>>` and layer the
in-flight changes on top in a notifier, so the icon flips instantly and
rolls back on error:

```dart
class ToggleState {
  const ToggleState({this.added = const {}, this.removed = const {}});
  final Set<String> added, removed;
}

final isSavedProvider = Provider.family<bool, String>((ref, id) {
  final server = ref.watch(savedIdsProvider).value ?? const <String>{};
  final t = ref.watch(saveToggleProvider);
  if (t.added.contains(id)) return true;
  if (t.removed.contains(id)) return false;
  return server.contains(id);
});
```

Persist the toggle to Firestore (`users/{uid}/saved/{id}`), not only in
memory — a toggle that silently resets on restart is a review complaint
and an App Review 2.1 risk.

## 2. Cursor pagination

```dart
Future<Page<T>> fetchPage({DocumentSnapshot? after, int limit = 20}) async {
  Query<Map<String, dynamic>> q = _db.collection('items')
      .where('status', isEqualTo: 'published')   // must match rules
      .orderBy('publishedAt', descending: true)
      .limit(limit);
  if (after != null) q = q.startAfterDocument(after);
  final s = await q.get();
  return Page(items: s.docs.map(Model.fromDoc).toList(),
              cursor: s.docs.isEmpty ? null : s.docs.last,
              hasMore: s.docs.length == limit);
}
```

List queries must include the same filter the rules require
(`status == 'published'`), otherwise the whole query is denied.

## 3. Enums with wire values

```dart
enum ItemStatus {
  draft('draft'), published('published'), archived('archived');
  const ItemStatus(this.wire);
  final String wire;
  static ItemStatus fromWire(String? v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => draft);
  String get label => switch (this) {          // localized for UI
        draft => L10n.current.statusDraft, … };
  String get englishLabel => …;                 // logs / admin exports
}
```

## 4. Callables

```dart
Future<String> createIntent(String itemId) async {
  final res = await _functions.httpsCallable('createPurchaseIntent')
      .call<Object?>({'itemId': itemId});
  return (res.data! as Map)['productId'] as String;
}
```

Convention on the server: `HttpsError` messages are user-safe English;
the client maps `code` to a localized string and ignores `message` for
anything shown to users in other languages.

## 5. Testing notifiers

```dart
final container = ProviderContainer(overrides: [
  currentUserProvider.overrideWithValue(fakeUser),
  lessonNoteRepositoryProvider.overrideWithValue(FakeRepo()),
]);
addTearDown(container.dispose);
final ok = await container.read(lessonNoteNotifierProvider.notifier).create('x');
expect(ok, isTrue);
```

## 6. Offline files

Re-downloadable content goes to `getApplicationSupportDirectory()/<name>`,
never Documents (iCloud backup + Apple data-storage guideline). Exclude it
from backups (iOS `isExcludedFromBackup` via a method channel; Android
`data_extraction_rules.xml`). Template and native code: skill
`flutter-store-release-readiness`.

## 7. Mistakes caught in production review

- Named Firebase app initialized while plugins used `.instance` → dev
  build wrote to prod.
- Client wrote `role`, `subscription` or purchase docs → privilege
  escalation. Rules must pin these; Functions write them.
- Purchase listeners created lazily on the store page → purchases
  delivered at cold start were lost. Read IAP notifiers in bootstrap.
- Downloads / mini player / signed URLs survived logout → next user on
  the device could play paid content.
- `toJson()` on a parent left nested models as objects → Firestore
  "Unsupported field value". Fix with `explicit_to_json`.
- UI strings in `throw Exception('…')` surfaced untranslated. Map to
  `Failure` with localized messages.
