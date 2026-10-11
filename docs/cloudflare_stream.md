# Cloudflare Stream integration

Video lectures play from Cloudflare Stream via HLS. Lecture docs carry
only the video UID; a Cloud Function checks the viewer's entitlement,
holds the API token, and returns **short-lived signed** playback URLs.

## ⚠️ Token hygiene (read this first)

**Never embed your Cloudflare API token in the Flutter app.** It grants
write access to Stream — anyone who downloads the .ipa/.apk can extract
it from the binary in minutes and upload, delete, or rate-limit videos
on your account.

The token lives only in Firebase Secrets:

```
firebase functions:secrets:set CLOUDFLARE_API_TOKEN
firebase functions:secrets:set CLOUDFLARE_ACCOUNT_ID
```

If you ever paste a token into chat, source code, or a screenshot —
rotate it immediately at Cloudflare dashboard → My Profile → API
Tokens.

## Data flow

```
┌──────────┐  createCloudflareUpload   ┌──────────────────────┐
│  Admin   │ ── (requireSignedURLs) ──►│  Cloudflare Stream   │
│ editor   │ ──── cloudflareVideoId ──►│ courses/{c}/sections │
└──────────┘        (Firestore)        │ /{s}/lectures/{l}    │
                                       └──────────┬───────────┘
                                                  ▼
                                  ┌──────────────────────────────┐
                                  │ Flutter client                │
                                  │ VideoLecturePlayer            │
                                  └──────┬───────────────────────┘
                                         │ callable resolveStreamPlayback
                                         │ {courseId, sectionId, lectureId}
                                         ▼
                                  ┌──────────────────────────────┐
                                  │ Cloud Function                │
                                  │ 1. read lecture doc → UID     │
                                  │ 2. not preview? require auth  │
                                  │    + hasCourseAccess()        │
                                  │ 3. GET video details          │
                                  │ 4. POST /stream/{uid}/token   │
                                  └──────┬───────────────────────┘
                                         ▼
                          {hlsUrl, dashUrl, thumbnailUrl,     ← UID path segment
                           durationSec, readyToStream}          replaced by token
                                         ▼
                                player loads signed HLS URL
```

The client never sends a raw video UID — it identifies the **lecture**,
and the server reads the UID from Firestore. A guest or non-buyer gets
`unauthenticated` / `permission-denied`, which the player shows as
"Purchase this course to watch this lecture."

`hasCourseAccess(uid, courseId)` (in `functions/src/iap.ts`) is true for:
the course instructor, admins, owners of `users/{uid}/purchases/{courseId}`
with status `purchased`, and users with an active Personal Plan.
Suspended users are always denied.

## Files

| Layer | File | Purpose |
|-------|------|---------|
| Domain | `lib/features/courses/domain/entities/lecture_entity.dart` | `cloudflareVideoId` field |
| Data | `lib/features/courses/data/models/lecture_model.dart` | Mirror field + Firestore JSON round-trip |
| Data | `lib/features/courses/data/datasources/cloudflare_stream_service.dart` | `StreamPlaybackRequest` + callable client, caches 50 min |
| Providers | `lib/features/courses/presentation/providers/courses_providers.dart` | `cloudflareStreamServiceProvider`, `cloudflareStreamPlaybackProvider(StreamPlaybackRequest)` |
| UI | `lib/features/courses/presentation/pages/lecture_player_page.dart` | `_VideoBody` resolution order (below) + locked/error states |
| Functions | `functions/src/index.ts` | `resolveStreamPlayback`, `createCloudflareUpload`, `deleteCloudflareVideo`, `enableSignedStreamUrls` |
| Admin | `lib/admin/courses/presentation/course_editor_page.dart` | Upload / UID field in the lecture dialog |
| Admin | `lib/admin/courses/data/cloudflare_upload_service.dart` | Direct creator upload + delete |

## Setup (one-time)

1. **Create the Cloudflare API token** at dashboard → My Profile → API
   Tokens with **Stream: Edit** on your account. Edit (not read-only)
   is required: the functions create upload URLs, mint signed playback
   tokens, set `requireSignedURLs`, and delete videos.

2. **Set the secrets:**
   ```
   cd functions
   firebase functions:secrets:set CLOUDFLARE_API_TOKEN
   firebase functions:secrets:set CLOUDFLARE_ACCOUNT_ID   # 32-hex account id
   ```
   Paste without a trailing newline — the functions trim, but a
   malformed account id fails fast with `failed-precondition`.

3. **Deploy the functions:**
   ```
   firebase deploy --only functions:resolveStreamPlayback,functions:createCloudflareUpload,functions:deleteCloudflareVideo,functions:enableSignedStreamUrls
   ```

4. **Enforce signed URLs.** New uploads are created with
   `requireSignedURLs: true`. For videos uploaded before this change,
   call the admin-only `enableSignedStreamUrls` callable once (after the
   new app version is live — older builds play unsigned URLs and stop
   working once a video requires signing). It returns
   `{total, updated, failed}`.

5. **Upload a video** from the admin lecture editor (direct upload), or
   paste an existing UID into the "Cloudflare Stream video UID" field.

6. **Play the lecture** as an entitled user (or mark it as a preview).

## Playback resolution order

`_VideoBody` in `lecture_player_page.dart` picks in this order:

1. **Local downloaded file** — `file://` path from offline downloads.
2. **Cloudflare Stream** — when `lecture.cloudflareVideoId` is set:
   `resolveStreamPlayback` → signed HLS URL.
3. **Storage-hosted `mediaUrl`** — legacy / non-Cloudflare lectures.
   Stored as a private `gs://` reference and resolved to a signed
   Storage URL by `resolveLectureMedia` (see
   `docs/offline_downloads.md` → "Paid files in Firebase Storage").

Videos still transcoding (`readyToStream == false`) show "Video still
encoding — try again in a minute."

## Caching

Signed tokens are minted with a **4-hour** TTL
(`STREAM_TOKEN_TTL_SEC` in `functions/src/index.ts`).
`CloudflareStreamService` caches resolutions for **50 minutes**, keyed by
`StreamPlaybackRequest(courseId, sectionId, lectureId)`, so a resumed
session never holds an expired token. The cache is cleared on sign-out
(`lib/app/session_cleanup.dart`) so the next user can't reuse URLs.

Manual invalidation (e.g. after the admin replaces a video):

```dart
final req = StreamPlaybackRequest(
  courseId: courseId, sectionId: sectionId, lectureId: lectureId,
);
ref.read(cloudflareStreamServiceProvider).invalidate(req);
ref.invalidate(cloudflareStreamPlaybackProvider(req));
```

## Who can upload / delete

- `createCloudflareUpload` — instructor or admin. Tags the upload with
  `meta.uploadedByUid`.
- `deleteCloudflareVideo` — admin, or an instructor who owns **every**
  course whose lectures reference the UID. If no lecture references it
  yet (an upload discarded in the editor), the uploader recorded in
  `meta.uploadedByUid` may delete it. Uses the collection-group index on
  `lectures.cloudflareVideoId` (`firestore.indexes.json`).
- The `onLectureDeleted` trigger cleans up with Admin privileges as a
  backstop.

## Testing

1. **Function shell:**
   ```
   firebase functions:shell
   > resolveStreamPlayback({courseId: 'c1', sectionId: 's1', lectureId: 'l1'}, {auth: {uid: '<buyer uid>'}})
   ```
   Expect `{hlsUrl: 'https://customer-…/<token>/manifest/video.m3u8', …}`.
   Repeat with a non-buyer uid → `permission-denied`; without auth on a
   non-preview lecture → `unauthenticated`.

2. **Player:** open a lecture with a Cloudflare UID — brief spinner, then
   playback. The HLS URL contains a long token, not the 32-hex UID.

3. **Direct URL check:** request
   `https://customer-<code>.cloudflarestream.com/<uid>/manifest/video.m3u8`
   for a migrated video — Cloudflare must refuse it (signed URL required).

## HLS support on each platform

- **iOS** — native HLS via AVPlayer (`video_player`).
- **Android** — HLS via ExoPlayer (`video_player` 2.8+).
- **Web** — `video_player_web` has no HLS. Use the Cloudflare iframe
  player or `hls.js` (out of scope for v1).

## Removing the old Firebase Storage flow

Once every video lecture has a `cloudflareVideoId`, you can delete the
`mediaUrl` for video lectures and the media files under
`courses/*/sections/*/lectures/*/media/`. Keep the Storage path for
audio / PDF / DOCX lectures.
