# Security model

How iLearnIt decides who may see, play, buy and change what. Read this
before touching `firestore.rules`, `storage.rules`, `functions/src/iap.ts`
or `functions/src/media.ts`.

**Principle:** the client is untrusted. Anything that grants access or
money-related state is written by Cloud Functions (Admin SDK) after a
server-side check. Rules deny those writes from clients.

---

## 1. Identity and roles

- `users/{uid}.role` ∈ `student | instructor | moderator | admin`,
  plus `isSuspended`. Rules helpers (`isAdmin`, `isInstructor`,
  `isModerator`) and the functions' `getRole()` read these fields.
- **Create**: a new account may only create its own doc as a
  non-suspended `student` with no `subscription`
  (`firestore.rules` → `match /users/{userId}`). Without this, anyone
  could sign up through the Auth REST API and create `role: 'admin'`.
- **Update**: owners may edit their profile but never `role`,
  `isSuspended` or `subscription`. Admins may update anything.
- Role changes go through the admin portal; `onUserRoleChanged`
  maintains `instructors/{uid}`.

## 2. Entitlements (who owns what)

| Data | Written by | Client access |
|---|---|---|
| `users/{uid}/purchases/{courseId}` | `verifyPurchase`, refund handlers | owner/admin read; **no writes** |
| `users/{uid}.subscription` | `verifySubscription`, store notifications | owner read; **no writes** |
| `enrollments/{uid}_{courseId}` | `verifyPurchase` | owner / course instructor / admin read; create denied |
| `transactions/*` | `verifyPurchase`, `verifySongbookPurchase`, `processRefund`, refund handlers | student / instructor / admin read; no writes |
| `users/{uid}/songbooks/{songbookId}` | `verifySongbookPurchase`, refund handlers | owner/admin read; **no writes** |
| `_iap_transactions/*`, `_iap_subscriptions/*`, `purchase_intents/*` | functions only | none |

`hasCourseAccess(uid, courseId)` (`functions/src/iap.ts`) is the single
server-side answer to "may this user consume paid content of this
course?": not suspended **and** (admin, or the course's instructor, or a
`purchased` purchase doc, or `subscription.expiresAt > now`).

### Purchase flow (course tiers)

1. `createPurchaseIntent(courseId)` → server checks the course is
   `published` and not already owned, records the intent, and returns the
   consumable tier product for the course's `priceTier`.
2. Store sheet (`buyConsumable`, `autoConsume: false`).
3. `verifyPurchase` → verifies with Apple (App Store Server API,
   JWS-verified) or Google (Play Developer API), then in one Firestore
   transaction: creates the `_iap_transactions` sentinel (once per store
   transaction, bound to one uid), checks the paid tier equals the
   course tier, writes purchase + enrollment + ledger. Android tokens
   are consumed server-side.
4. Only then does the client finish the store transaction.

Refunds / revocations: `appStoreNotifications` (Apple ASSN v2, signature
verified) and `playRtdn` (Play RTDN) call `revokeCoursePurchase` /
`applySubscription`. Details: `docs/iap_setup.md`,
`docs/subscriptions.md`.

## 3. Catalogue visibility

- `courses/{id}` — **get**: published courses for everyone; otherwise
  the instructor, admins, moderators, and buyers (so an archived course
  stays openable for its owners). **list**: queries must filter
  `status == 'published'` (or `instructorId == me`) — the search and
  instructor pages do.
- Course `rating` / `reviewCount` are computed by
  `onCourseReviewWritten`; clients can't write them.
- Reviews: author-only, and only for buyers or active subscribers
  (`canReview` in the rules).
- Lecture docs are publicly readable (curriculum browsing) but contain
  **no usable media links**: a Cloudflare UID (useless without a signed
  token) or a `gs://` reference.

## 4. Paid media

| Media | Endpoint | Gate | URL lifetime |
|---|---|---|---|
| Cloudflare video | `resolveStreamPlayback({courseId, sectionId, lectureId})` | preview or `hasCourseAccess` | signed token, 4 h |
| Storage media / resources | `resolveLectureMedia({…, resourceIndex?})` | preview or `hasCourseAccess` | V4 signed URL, 4 h |
| Songbook PDF | `resolveSongbookContent({songbookId})` | `hasSongbookAccess` (owner, active Personal Plan, admin) | V4 signed URL, 4 h |

Songbooks are **non-consumable** products (one per songbook, prefix
`info.ilearnit.songbook.`). `verifySongbookPurchase` keys the store
transaction by its stable id (iOS `originalTransactionId`, Play token),
binds it to one uid, and is idempotent for restores. The PDF lives at
`songbooks/{id}/content/*` (admin-only Storage reads, tokens stripped).

- Cloudflare videos have `requireSignedURLs: true` (new uploads; old
  ones via `enableSignedStreamUrls`).
- Storage: `onLectureObjectFinalized` strips download tokens;
  `storage.rules` deny direct reads to everyone except the course owner
  and admins; `migrateLectureMediaToPrivate` converts legacy URLs.
- Client caches: 50 min; cleared on sign-out.

## 5. Instructor boundaries

- Firestore: instructors edit only their own courses, can't touch
  admin-only fields, and can only move `draft | changes_requested →
  submitted`. Delete only while `draft`.
- Storage (`canManageCourse`): writes/deletes under `courses/{id}/…`
  only for that course's instructor (or admins).
- `deleteCloudflareVideo`: only videos used solely by the caller's
  courses, or unattached uploads they made.

## 6. Device & session hygiene

- Sign-out (`AuthNotifier.logout`) runs `BeforeSignOutHooks` while still
  authenticated (removes the FCM token from the profile), then signs out.
- `sessionCleanupProvider` (any session end, incl. deletion / revocation):
  stops the mini player, wipes offline downloads + saved resources,
  clears cached signed URLs. FCM token is deleted.
- Offline files live in Application Support, excluded from iCloud /
  Android backups (`docs/offline_downloads.md`).
- iOS uses Dart-side Firebase options per flavor; no bundled plist, so a
  dev build can't reach production.

## 7. Secrets & config

| Secret / param | Used by |
|---|---|
| `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` | Cloudflare functions |
| `APPLE_IAP_KEY_ID`, `APPLE_IAP_ISSUER_ID`, `APPLE_IAP_PRIVATE_KEY` | App Store Server API |
| `GOOGLE_PLAY_SERVICE_ACCOUNT` | Play Developer API |
| `ANDROID_PACKAGE_NAME`, `APPLE_BUNDLE_ID`, `APPLE_APP_ID` (params, `functions/.env.<alias>`) | store verification |
| `functions/certs/*.cer` | Apple root CAs for JWS verification |

Never commit service-account keys (the seeding key
`sample_data/ilearnit-dev-*.json` is gitignored — keep it that way). Rotate any token that has been pasted into chat or docs.

## 8. App Check and app version

- **App Check**: activated in both bootstraps (Play Integrity / App
  Attest / reCAPTCHA v3; debug providers in dev). Client callables run
  `requireAppCheck` — monitor mode until `ENFORCE_APP_CHECK=true`.
- **Force update**: Remote Config `min_build_*` blocks outdated builds
  (e.g. ones that predate server-side entitlements).

## 9. Known gaps

- Lecture docs of unpublished courses are still readable by ID (they
  hold no media links).
- Q&A `replyCount` counters are client-incremented (bounded abuse; see
  `docs/qa.md`).
- Songbook reviews are not gated on ownership.
