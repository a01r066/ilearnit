# Offline Downloads

Implements **P1-8** from `docs/go_live_roadmap.md` — owners and Personal
Plan subscribers can download lecture media for offline viewing on flaky
or expensive networks (VN is mostly mobile-tethered).

---

## 1. Where things live

```
Application Support (app-private, excluded from backups, removed on uninstall)
  ├── downloads/                 ← offline lectures (DownloadsService)
  │     ├── <lectureId>.mp4
  │     ├── <lectureId>.m4a
  │     └── <lectureId>.pdf
  └── resources/                 ← PDFs / scores opened from a lecture
        └── <urlHash>_<name>.<ext>   (DocumentLectureResourceTile)

Secure storage (Keychain on iOS / EncryptedSharedPreferences on Android)
  └── downloads_manifest_v1   (JSON: { lectureId: DownloadEntity, … })
```

- **Media bytes** sit in app-private storage — the OS sandbox already
  prevents other apps from reading them, so we don't double-encrypt.
  Removed on uninstall.
- **Not Documents.** Older builds wrote to `<Documents>/downloads` and
  `<Documents>/ilearnit`. Documents is backed up to iCloud, which Apple's
  data-storage guideline forbids for re-downloadable media. Paths come
  from `lib/core/storage/offline_storage.dart`:
  - `OfflineStorage.dir(name)` → `<ApplicationSupport>/<name>`, created
    on demand and flagged `isExcludedFromBackup` on iOS through the
    `ilearnit/backup` method channel (`ios/Runner/AppDelegate.swift`).
  - Android Auto Backup / device transfer exclude these folders (and the
    legacy `app_flutter/` ones) via `res/xml/data_extraction_rules.xml`
    and `res/xml/backup_rules.xml`.
  - Entries written by older builds keep their absolute Documents path
    in the manifest and still play; wipes delete both locations.
- **Manifest** is encrypted-at-rest in flutter_secure_storage per the
  P1-8 acceptance criteria. The JSON blob includes per-file
  `localPath`, `bytesDownloaded`, `totalBytes`, `status`,
  `downloadedAt`, `courseTitle`, `lectureTitle`. ~100 bytes per entry
  → fits 600+ downloads comfortably inside platform limits.

---

## 2. State machine per download

```
              enqueue()
   none ──────────────────────> queued
                                  │
                                  ▼
                            downloading ──── cancel()? ──── paused
                                  │                            │
                                  ▼                            ▼
                            completed                       resume → enqueue() (restart)
                                  ▲
                                  │ failed (network / 5xx)
                                  └────────── failed
```

Notes:
- `cancel()` on an in-flight download transitions to `paused` (CancelToken
  isn't an error — we filter on `CancelToken.isCancel(error)` in the
  catch).
- `resume` is a fresh `enqueue` — Dio doesn't natively do Range-resume
  here. For users on intermittent networks this means a 200 MB lecture
  re-downloads from byte 0. Filed as future work.
- `delete()` is a hard purge: cancel + unlink file + drop manifest row.
- **Signed URLs are resolved per transfer.** For paid Storage files the
  manifest stores a stable reference (`lecture-media:<course>/<section>/<lecture>`)
  in `mediaUrl`, never the signed URL. `DownloadsService.enqueue` calls
  its `resolveUrl` hook (`LectureMediaService.resolveRef`) right before
  each transfer, so a resume after the URL expired still works. If the
  server refuses (not entitled / signed out) the entry becomes `failed`.

---

## 3. Throttling + battery

- Dio writes the file in chunks; we only update the manifest every
  ~256 KB to avoid hammering EncryptedSharedPreferences (which
  re-encrypts the whole blob on every write on Android).
- The progress `Stream<DownloadProgressEvent>` is broadcast. All UI
  surfaces (button + downloads page) read from the same stream so
  there's never a divergent state.
- We cap concurrent downloads implicitly to 1 per `lectureId` via the
  `_inFlight` cancel-token map. Multiple lectures CAN download in
  parallel — Dio handles the connection pooling.

---

## 4. Files added

| Path | Role |
|---|---|
| `lib/features/downloads/domain/entities/download_entity.dart` | Freezed entity + `formattedSize`, `progress`, `isCompleted`, `isInFlight` |
| `lib/features/downloads/data/datasources/downloads_manifest_store.dart` | Read/write JSON manifest from `flutter_secure_storage`, with in-memory cache |
| `lib/features/downloads/data/datasources/downloads_service.dart` | Dio-based downloader with CancelTokens + broadcast stream |
| `lib/features/downloads/presentation/providers/downloads_state.dart` | Hand-rolled state with `completed`, `totalBytesUsed` selectors |
| `lib/features/downloads/presentation/providers/downloads_notifier.dart` | Bridges service stream to Riverpod state |
| `lib/features/downloads/presentation/providers/downloads_providers.dart` | Singletons + selectors (`localMediaPathForLectureProvider` powers the player swap) |
| `lib/features/downloads/presentation/widgets/lecture_download_button.dart` | Multi-state pill button (Download / Downloading… / Resume / Downloaded) |
| `lib/features/downloads/presentation/pages/downloads_page.dart` | List + usage header + swipe-to-delete + "Clear all" |
| `docs/offline_downloads.md` | This file |

## 5. Files changed

- `lib/features/courses/presentation/pages/lecture_player_page.dart` —
  body widgets now read `localMediaPathForLectureProvider` and pass
  `file://<path>` to `VideoLecturePlayer` / `AudioLecturePlayer` when the
  download is complete. `_LectureBody` mounts the `LectureDownloadButton`
  under the metadata row.
- `lib/features/profile/presentation/pages/profile_page.dart` — new
  "Downloads" tile that routes to `/profile/downloads`.
- `lib/core/routing/route_names.dart` + `app_router.dart` — `downloads`
  route registered under the profile branch.
- `lib/l10n/app_en.arb`, `app_vi.arb` + generated `app_localizations*.dart`
  — 11 new keys.

## 6. Player local-file swap

The player picks a local file first, then a signed URL:

```dart
final localPath = ref.watch(localMediaPathForLectureProvider(lecture.id));
if (localPath != null) {
  url = Uri.file(localPath).toString();
} else if (LectureMediaService.needsResolution(lecture.mediaUrl)) {
  // gs:// reference → signed URL after a server entitlement check
  url = await ref.watch(lectureMediaUrlProvider(LectureMediaRequest(...)));
} else {
  url = lecture.mediaUrl!; // plain https (external CDN)
}
```

`Uri.file(path).toString()` produces the correct `file:///…` URL on both
platforms — `video_player` and `just_audio` accept it natively. Going
offline mid-watch is graceful: future ticks read from disk; the
`onTick` -> `LectureProgressNotifier.flush()` write queues against
Firestore which retries when the connection comes back.

## 7. Why secure storage for the manifest (not SharedPreferences)?

Two reasons:

1. **The roadmap asked for it.** P1-8 acceptance criteria specifically
   call out encrypted manifest.
2. **Course metadata is included.** The manifest stores `courseTitle`
   and `lectureTitle` plain — encryption-at-rest means a forensic dump
   of the device can't reveal what someone is studying without their
   keychain credentials. Modest defense, but free.

The downside is write cost on Android (re-encrypting the whole blob on
every progress tick). We mitigate with the 256 KB throttle.

If the manifest grows past ~1000 entries you'll want to swap the
backing store for SQLite — but at that point the user is doing
something unusual that deserves a UX nudge ("you have 1000+ downloads;
consider clearing some").

## 8. Permissions

Neither iOS nor Android needs an extra permission for app-private
writes:

- iOS — no `Info.plist` entry required.
- Android — `getApplicationSupportDirectory()` maps to the app's
  internal `files/` directory. No storage or `READ_MEDIA_*` permission is
  needed — the manifest explicitly strips `READ_MEDIA_*` that plugins
  merge in (Play's photo/video permission policy).

## 9. Testing checklist

| Scenario | Expected |
|---|---|
| Tap Download on a paid lecture (owned) | Pill swaps to "Downloading… 0%", progress increments, file written |
| Tap the pill mid-download | Cancels — pill swaps to "Resume download" |
| Tap Resume | Restarts (current behaviour — not range-resume) |
| Lose network mid-download | Status → `failed`, `lastError` populated, pill swaps to "Resume" |
| Reach 100% | Pill swaps to "Downloaded · 12.4 MB" + delete icon |
| Re-open lecture player | Player loads from `file://`, no network calls |
| Profile → Downloads | All completed items listed, newest first, with size + date |
| Swipe a row in Downloads | Hard-deletes file + manifest entry |
| Clear all overflow | Wipes the whole `downloads/` directory + manifest |
| Tap a row in Downloads | Routes to lecture player with the saved position |
| Sign out / delete account / revoked session | `sessionCleanupProvider` (`lib/app/session_cleanup.dart`) wipes all downloads + saved resources and stops the mini player, so the next person on the device can't play paid content. Guest downloads (never signed in) are untouched. |
| Download a paid lecture as a non-owner | Entry becomes `failed` ("Purchase this course to download.") |
| Resume a download hours later | New signed URL is fetched; transfer restarts |

## 10. Future work

- Real range-resume (Dio + `Range: bytes=N-` header) so partial
  downloads survive network blips without restarting.
- WiFi-only toggle (`connectivity_plus` exists in the stack already).
- Auto-delete oldest downloads when free disk drops below a threshold.
- Cross-device manifest sync — currently downloads are per-device.
  Mirror to `users/{uid}/downloads/{lectureId}` so reinstalls can
  re-fetch.
- DRM / HLS offline via Mux when we cut over from raw MP4.
- Background downloads via `flutter_downloader` so iOS app
  backgrounding doesn't pause the transfer.

## 11. Paid files in Firebase Storage

Lecture media that isn't on Cloudflare (audio, PDF/DOCX lectures, older
videos) and lecture resources are paid content. They are protected like
this:

- **Admin uploads** (`AdminStorageService.uploadLectureMedia` /
  `uploadLectureResource`) store `gs://<bucket>/<path>` in the lecture
  doc instead of a token-bearing download URL.
- **`onLectureObjectFinalized`** (`functions/src/media.ts`) strips the
  `firebaseStorageDownloadTokens` metadata from every new object under
  `courses/*/sections/*/lectures/*/(media|resources)/`. A download token
  would let anyone with the URL bypass Storage rules.
- **`storage.rules`** allow direct reads of those paths only to the
  course's instructor and admins (`canManageCourse`).
- **`resolveLectureMedia`** (callable) checks entitlement
  (`hasCourseAccess`; preview lectures are free) and returns a V4 signed
  URL valid for 4 hours. The client (`LectureMediaService`) caches it for
  50 minutes and clears the cache on sign-out.
- **Migration**: admin calls `migrateLectureMediaToPrivate` once after
  the new app is live — it rewrites legacy download URLs to `gs://`
  references and revokes their tokens. Returns
  `{lectures, docsUpdated, tokensRevoked, failures}`.
- **IAM**: signing uses IAM `signBlob`. Grant the functions runtime
  service account *Service Account Token Creator* on itself.

