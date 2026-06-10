# Cloudflare Stream integration

Video lectures play from Cloudflare Stream via HLS. The Flutter
client carries only the video UID; the Cloud Function holds the API
token and returns playback URLs on demand.

## ⚠️ Token hygiene (read this first)

**Never embed your Cloudflare API token in the Flutter app.** It grants
account-wide write access to Stream — anyone who downloads the
.ipa/.apk can extract it from the binary in minutes and upload, delete,
or rate-limit videos on your account.

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
┌──────────┐       Firestore         ┌──────────────────────┐
│  Admin   │ ──── cloudflareVideoId ─►│ courses/{c}/sections │
│ editor   │                          │ /{s}/lectures/{l}    │
└──────────┘                          └──────────┬───────────┘
                                                 │ watchLecture
                                                 ▼
                                  ┌──────────────────────────┐
                                  │   Flutter client          │
                                  │  VideoLecturePlayer       │
                                  └──────┬───────────────────┘
                                         │ callable:
                                         │ resolveStreamPlayback({videoId})
                                         ▼
                                  ┌──────────────────────────┐
                                  │ Cloud Function            │
                                  │ (token in Firebase Secret)│
                                  └──────┬───────────────────┘
                                         │ GET /accounts/{id}/stream/{vid}
                                         ▼
                                  ┌──────────────────────────┐
                                  │  Cloudflare Stream API    │
                                  └──────────────────────────┘
                                         │
                                         ▼
                          {hlsUrl, dashUrl, thumbnailUrl,
                           durationSec, readyToStream}
                                         │
                                         ▼
                                player loads HLS URL
```

## Files

| Layer | File | Purpose |
|-------|------|---------|
| Domain | `lib/features/courses/domain/entities/lecture_entity.dart` | Added `cloudflareVideoId` field |
| Data | `lib/features/courses/data/models/lecture_model.dart` | Mirror field + Firestore JSON round-trip |
| Data | `lib/features/courses/data/datasources/cloudflare_stream_service.dart` | Calls the Cloud Function, caches results 50 min |
| Providers | `lib/features/courses/presentation/providers/courses_providers.dart` | `cloudflareStreamServiceProvider` + `cloudflareStreamPlaybackProvider` |
| UI | `lib/features/courses/presentation/pages/lecture_player_page.dart` | `_VideoBody` resolution order: local download → Cloudflare → legacy mediaUrl |
| Functions | `functions/src/index.ts` | `resolveStreamPlayback` callable |
| Admin | `lib/admin/courses/presentation/course_editor_page.dart` | `_LectureDraft.cloudflareVideoId` + UID field in lecture dialog |

## Setup (one-time)

1. **Create the Cloudflare API token** at dashboard → My Profile → API
   Tokens. Use the "Read Stream and Stream Videos" template — read-only
   is enough for playback resolution. Copy the token (starts with
   `cfut_…`).

2. **Set the secrets:**
   ```
   cd functions
   firebase functions:secrets:set CLOUDFLARE_API_TOKEN
   #   paste the token at the prompt
   firebase functions:secrets:set CLOUDFLARE_ACCOUNT_ID
   #   paste 7de7c6b1245c93f697d0c038e6047555 (or your account id)
   ```

3. **Deploy the function:**
   ```
   firebase deploy --only functions:resolveStreamPlayback
   ```

4. **Set Cloudflare Stream privacy** (per video). Either:
   - Leave videos **public** — the HLS URL returned by the API is
     directly playable (anyone with the URL can stream it). Simplest
     option.
   - Toggle **Require signed URLs** on the video — the Cloud Function
     must mint a signed JWT per request. See the "Signed URLs" section
     below.

5. **Upload a video** to Cloudflare Stream, copy its UID from the
   dashboard URL (32 hex chars). Open the admin lecture editor, paste
   the UID into the "Cloudflare Stream video UID" field, save.

6. **Play the lecture** as a signed-in user — the player resolves the
   UID and plays the HLS stream.

## Playback resolution order

`_VideoBody` in `lecture_player_page.dart` picks in this order:

1. **Local downloaded file** — if the lecture has been pre-downloaded
   via the offline downloads feature, the player uses the `file://`
   path directly. Skips Cloudflare entirely. (Note: download support
   currently caches Firebase Storage URLs only; offline Cloudflare
   playback is a follow-up.)
2. **Cloudflare Stream** — when `lecture.cloudflareVideoId` is set,
   call the Cloud Function and play the returned HLS URL.
3. **Legacy `mediaUrl`** — for lectures created before the Cloudflare
   migration, fall back to the Firebase Storage URL stored on
   `lecture.mediaUrl`.

This makes the migration safe: existing lectures keep working, new
lectures use Cloudflare, and you can migrate one section at a time.

## Caching

`CloudflareStreamService` keeps in-memory resolutions for **50
minutes**. Cloudflare's signed-URL default TTL is 60 minutes, so we
stay comfortably under it. Cache is bound to the Riverpod container —
killed and recreated on app cold start, on Riverpod container
recreation, and when the user signs out.

For manual invalidation (e.g., after the admin replaces a video):

```dart
ref.read(cloudflareStreamServiceProvider).invalidate(videoId);
ref.invalidate(cloudflareStreamPlaybackProvider(videoId));
```

## Auth gate

The callable requires `request.auth` — only signed-in users can
resolve playback. This stops anonymous scrapers from enumerating your
catalogue's video UIDs through a single endpoint. If you later
introduce paywall enforcement (e.g., "this lecture requires an
enrollment"), add the check in `resolveStreamPlayback` before the
fetch.

## Signed URLs (when you enable "Require signed URLs")

Public HLS URLs work as-is for the public catalogue. To paywall
specific videos, enable "Require signed URLs" on the video in
Cloudflare Stream and update the Cloud Function:

1. Create a Stream signing key in Cloudflare dashboard → Stream →
   Settings → Signing Keys. Save the JWK to a Firebase Secret:
   ```
   firebase functions:secrets:set CLOUDFLARE_STREAM_SIGNING_KEY
   ```
2. In `resolveStreamPlayback`, after fetching the metadata, mint a
   signed JWT (use `jsonwebtoken` npm). Append it as `?token=…` to the
   HLS URL.
3. Set a TTL on the JWT (default Cloudflare TTL is 1 hour). The
   client cache (50 min) keeps us inside the window.

Code skeleton (not yet wired):

```ts
import jwt from 'jsonwebtoken';
const signingKeyJwk = JSON.parse(CLOUDFLARE_STREAM_SIGNING_KEY.value());
const token = jwt.sign(
  {
    sub: videoId,
    kid: signingKeyJwk.kid,
    exp: Math.floor(Date.now() / 1000) + 60 * 60,
  },
  signingKeyJwk,
  {algorithm: 'RS256'},
);
const signedHls = `${hlsUrl}?token=${token}`;
```

## Testing

1. **Local emulator:**
   ```
   cd functions
   firebase emulators:start --only functions
   ```
   Then in the Flutter app point `FirebaseFunctions.instance` at the
   emulator (`useFunctionsEmulator('localhost', 5001)`) before
   `runApp`.

2. **Hand-test the function** with the Firebase Functions shell:
   ```
   firebase functions:shell
   > resolveStreamPlayback({videoId: 'bf53017eb20e5db311c21d30ffb5a075'}, {auth: {uid: 'test'}})
   ```
   Should return `{hlsUrl, dashUrl, durationSec, thumbnailUrl, readyToStream}`.

3. **Curl the deployed function** as an authenticated user (requires a
   Firebase Auth ID token):
   ```
   curl -X POST \
     -H 'Content-Type: application/json' \
     -H "Authorization: Bearer $(firebase auth:sign-in-with-custom-token …)" \
     -d '{"data":{"videoId":"bf53017eb20e5db311c21d30ffb5a075"}}' \
     https://<region>-<project>.cloudfunctions.net/resolveStreamPlayback
   ```

4. **Verify in the player:** open a lecture with a Cloudflare UID —
   you should see a brief spinner while the function resolves, then
   the HLS stream begins. Watch the network panel: the only outbound
   request is to the Cloud Function (not to Cloudflare directly).

## HLS support on each platform

- **iOS** — native HLS via AVPlayer (the `video_player` plugin uses
  it under the hood). Works out of the box.
- **Android** — HLS via ExoPlayer. The `video_player` plugin v2.8+
  uses ExoPlayer with HLS support enabled. No extra setup.
- **Web** — `video_player_web` doesn't ship HLS support. For web
  playback, either embed the Cloudflare iframe player
  (`https://customer-<code>.cloudflarestream.com/<uid>/iframe`) or add
  `hls.js`. Out of scope for v1.

## Removing the old Firebase Storage flow

Once every lecture has a `cloudflareVideoId`, you can:
1. Delete `mediaUrl` from the Firestore docs (or keep it as a backup).
2. Remove the upload UI in the admin lecture editor (the bottom
   "Media file" section) — leaving only the UID field.
3. Delete the `videos/` prefix from Firebase Storage to save costs.

Don't rush this; the legacy fallback is cheap insurance during the
migration window.
