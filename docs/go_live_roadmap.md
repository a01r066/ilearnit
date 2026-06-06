# iLearnIt — Go-Live Roadmap

An actionable checklist of what's missing or weak before iLearnIt is ready for App Store + Play Store submission and a confident public launch. Items are grouped by priority and each has an acceptance criteria block so a ticket can be filed verbatim.

- **P0** — blocks store review or opens the business to fraud.
- **P1** — needed for a launch that doesn't feel like a beta.
- **P2** — post-launch growth + retention.
- **Ops** — engineering / infrastructure plumbing.

Companion docs: [technical_specification.md](technical_specification.md), [admin_portal.md](admin_portal.md), [subscriptions.md](subscriptions.md), [push_notifications.md](push_notifications.md), [social_auth_setup.md](social_auth_setup.md), [songbooks.md](songbooks.md).

---

## Status snapshot

What's already built and shipping today:

| Area | Status |
|---|---|
| Auth (email/pw, Google, Apple) | Done |
| Course catalog + detail + lectures (metadata only) | Done |
| Per-course IAP (`PriceTier`) | Done |
| Personal Plan subscription (monthly / yearly) | Done (client-trust) |
| Search (in-memory, ranked) | Done |
| Songbooks tab + detail | Done |
| Instructors list + detail | Done |
| Push notifications (FCM + local + Cloud Functions) | Done |
| Admin portal (courses, instructors, songbooks, applications, subscriptions, notifications) | Done |
| Reviews (courses + songbooks) | Done |
| i18n (EN + VI) | Done |
| Themes (vibrant, professional, system) | Done |
| Firestore + Storage rules | Done |
| Cloud Functions (3 triggers) | Done |

What's missing — see the rest of this doc.

---

## P0 — must ship before the store review

### P0-1. Server-side IAP receipt verification

Today `SubscriptionNotifier` writes `users/{uid}.subscription` directly from the client after a `PurchaseStatus.purchased` event. A jailbroken / Frida-hooked client can forge it. **This is a fraud open door** and must be closed before any marketing dollar is spent.

**Acceptance criteria**
- New callable Cloud Function `verifyPurchase(serverVerificationData, productId, source: 'apple' | 'google')`.
  - Apple: POST to `https://buy.itunes.apple.com/verifyReceipt` (fallback to sandbox on 21007). Use App Store Connect shared secret from `functions:config:apple.shared_secret`.
  - Google: `androidpublisher.purchases.subscriptionsv2.get` with a service account that has Play Console "View financial data" scope.
- Function is the **only** writer of `users/{uid}.subscription`. Firestore rule on `users/{uid}` carves out the subscription map to admin-only writes (the Function runs as Admin SDK, bypassing rules).
- On verification failure, function returns `{ ok: false, reason }` and client surfaces a snackbar — no Firestore write.
- Webhook endpoints `appstoreNotificationsV2` and `googlePlayPubSub` flip `subscription.autoRenew`, `subscription.expiresAt`, and `subscription.canceledAt` on renew / cancel / refund events. Without these, churned users keep access until manual reconciliation.

**Files touched**
- `functions/src/index.ts` — add `verifyPurchase`, `appstoreNotificationsV2`, `googlePlayPubSub`.
- `firestore.rules` — lock `users/{uid}.subscription`.
- `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart` — new `verify(...)` that calls the callable.
- `lib/features/subscriptions/presentation/providers/subscription_notifier.dart` — replace direct Firestore write with `verify()`.

---

### P0-2. In-app account deletion (Apple §5.1.1(v))

Apple rejects apps that allow account creation without offering in-app deletion. Currently iLearnIt has no deletion path.

**Acceptance criteria**
- `Profile → Settings → Delete account` row, gated by re-authentication (`reauthenticateWithCredential` for email/pw, fresh Google/Apple sign-in for socials).
- Callable Cloud Function `deleteAccount` runs in a Firestore batch:
  1. Hard-delete `users/{uid}` doc.
  2. Delete `enrollments` where `userId == uid`.
  3. Delete `instructor_applications/{uid}`.
  4. Delete authored `courses/{*}/reviews/{uid}` and `songbooks/{*}/reviews/{uid}`.
  5. Delete storage objects under `users/{uid}/`.
  6. Unsubscribe FCM tokens from all topics.
  7. Call `admin.auth().deleteUser(uid)`.
- After success: client signs out and routes to `/login`.
- Confirmation dialog explains what is deleted, that subscriptions must be canceled separately via the App Store / Play Store, and that deletion is permanent.

**Files touched**
- `functions/src/index.ts` — `deleteAccount` callable.
- `lib/features/profile/presentation/pages/delete_account_page.dart` — new.
- `lib/features/profile/presentation/pages/settings_page.dart` — add row.
- `lib/l10n/app_en.arb` + `app_vi.arb` — new strings.

---

### P0-3. Privacy policy + Terms of Service screens

App Store Connect requires a privacy policy URL; Play Console requires the same plus a data-safety form. Currently neither screen exists.

**Acceptance criteria**
- `assets/legal/privacy_policy.md` + `terms_of_service.md` checked into the repo, also published at `https://ilearnit.info/legal/privacy` and `/legal/terms`.
- `LegalDocumentPage(slug)` renders the markdown via `flutter_markdown`.
- Linked from: sign-up footer ("By signing up you agree to…"), sign-in footer, `Profile → About`, subscription checkout disclaimer.
- App Store Connect → App Privacy filled out (data collected, linked, used for tracking).
- Play Console → Data Safety filled out.

---

### P0-4. Email verification gate

`signupWithEmail` doesn't enforce verification. Spam accounts can pollute reviews and trigger refunds.

**Acceptance criteria**
- On sign-up success, immediately call `firebaseUser.sendEmailVerification()`.
- New `VerifyEmailPage` shown when `isAuthenticated && !user.emailVerified`. Has "Resend email" button (with 60s cooldown) and "I've verified, refresh" that calls `firebaseUser.reload()`.
- Gate the following on `user.emailVerified == true`:
  - `subscription/checkout` route.
  - `BuyCourseButton` purchase tap.
  - `ReviewFormNotifier.submit`.
  - `instructorApplication.submit`.
- Social sign-ins (Google / Apple) are considered verified.

**Files touched**
- `lib/features/auth/presentation/pages/verify_email_page.dart` — new.
- `lib/core/routing/app_router.dart` — redirect rule.
- `lib/features/auth/data/datasources/auth_remote_datasource.dart` — send-on-signup.

---

### P0-5. Forgot password flow

Strings exist (`authForgotPassword`) but the screen and call don't.

**Acceptance criteria**
- `ForgotPasswordPage` with email field → `firebaseAuth.sendPasswordResetEmail(email)`.
- "Forgot password?" link on `LoginPage` opens it.
- Customize the email template via Firebase Auth Console → Templates with `{{LINK}}` deep-linking to a Hosting page that finishes the reset (or use the default landing page for v1).

---

### P0-6. Crashlytics + Performance + Analytics

No `firebase_crashlytics`, `firebase_performance`, or `firebase_analytics` imports today. Without these you ship blind.

**Acceptance criteria**
- Add the three dependencies + corresponding native config.
- `bootstrap.dart`:
  ```dart
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (e, st) {
    FirebaseCrashlytics.instance.recordError(e, st, fatal: true);
    return true;
  };
  ```
- Funnel events instrumented via `AnalyticsService` (thin wrapper around `FirebaseAnalytics`):
  - `sign_up`, `sign_in` with `{ method }`.
  - `view_course` with `{ course_id, category }`.
  - `start_purchase`, `purchase_success`, `purchase_failed` with `{ product_id, currency, value }`.
  - `subscription_started`, `subscription_canceled` with `{ plan }`.
  - `lecture_started`, `lecture_completed` with `{ course_id, lecture_id }`.
  - `review_submitted` with `{ course_id, rating }`.
  - `search_submit` with `{ query_length, result_count }`.
- Set `userId` to `users/{uid}.id` on sign-in, clear on sign-out.

---

### P0-7. Real video playback pipeline

I see lecture entities and the access gate but no `video_player` integration, no HLS, no DRM. A locally-hosted MP4 in Firebase Storage won't scale and burns egress.

**Acceptance criteria**
- Pick a video CDN: **Mux** (recommended — best DX, signed playback URLs, DRM optional), Cloudflare Stream (cheapest), or Bunny.net.
- Replace `LectureModel.videoUrl: String` with `playbackId: String` + `signedPlaybackUrlExpiresAt`.
- Callable Function `getLectureSignedUrl(courseId, lectureId)` that:
  - Verifies `hasUnlockedAccessProvider`-equivalent server-side via enrollments + active subscription.
  - Returns a 60-min signed HLS URL.
- `LecturePlayerPage` uses `video_player` + `chewie` (or `better_player` for HLS + casting).
- Server-side adaptive bitrate (Mux handles this automatically; Storage + raw MP4 does not).

---

### P0-8. Lecture progress tracking

No `enrollments/{id}/progress` collection today. Without it: no "Continue learning" CTA, no completion %, no certificates, no resume-from-position.

**Acceptance criteria**
- Subcollection `enrollments/{id}/progress/{lectureId}`: `{ positionSec, durationSec, completed: bool, lastWatchedAt }`.
- `LecturePlayerNotifier` writes every 10 seconds (debounced) and on pause / dispose.
- `enrollmentProgressProvider(enrollmentId)` exposes `completedCount / totalLectures`.
- Course detail page shows a `LinearProgressIndicator` if the user has any progress.
- Home tab gains a "Continue learning" rail showing the 3 most recent in-progress courses (across enrollments + active subscription's watched courses).
- Firestore rule: only the enrollment owner can write to their progress subcollection.

---

### P0-9. App icons, splash, store assets

**Acceptance criteria**
- `flutter_launcher_icons` config in `pubspec.yaml`; `flutter pub run flutter_launcher_icons:main` generates all sizes.
- `flutter_native_splash` config — branded launch screen (logo + vibrant gradient).
- iOS + Android screenshots in 5 device sizes × EN + VI (10 sets total). Store under `marketing/screenshots/`.
- App Store Connect metadata in `marketing/store_metadata/{en,vi}/` — name, subtitle, description, keywords, promotional text.
- Play Console metadata in `marketing/store_metadata/play/{en,vi}/`.

---

### P0-10. ATT prompt + Apple Privacy Manifest

iOS 17+ requires `PrivacyInfo.xcprivacy` declaring tracking domains and required-reason APIs. Firebase SDK 10.21+ ships its own, but you need yours.

**Acceptance criteria**
- Add `ios/Runner/PrivacyInfo.xcprivacy` declaring:
  - `NSPrivacyTracking: false` (unless you add ad SDKs).
  - Required-reason API entries for `UserDefaults` (`CA92.1`), file timestamp (`C617.1` if used).
- If Analytics or any SDK is configured for tracking, add `AppTrackingTransparency` plugin and call `requestTrackingAuthorization()` before logging events.
- Run `flutter build ios --release` and verify Xcode 16's "Privacy Manifest" warnings are zero.

---

## P1 — needed for a launch that doesn't feel like a beta

### P1-1. Onboarding flow

First launch drops users in `/home` with no personalization.

**Acceptance criteria**
- 3-screen onboarding shown on first launch (gated by `PrefsService.onboardingComplete`):
  1. Instrument picker — writes `users/{uid}.primaryInstrument`.
  2. Skill level (beginner / intermediate / advanced) — drives the default Home rail.
  3. Notification permission soft-ask — explains value before triggering the native prompt.
- After completion, sets `PrefsService.onboardingComplete = true` and routes to `/home`.
- Skippable in 2 taps to avoid friction.

---

### P1-2. 7-day free trial implementation

The songbooks tab banner advertises "Start 7-day free trial" but the IAP products aren't configured with introductory offers.

**Acceptance criteria**
- App Store Connect → Subscriptions → Introductory Offer → Free Trial (7 days) on both `personal_monthly` and `personal_yearly`.
- Play Console → equivalent base-plan + free-trial offer.
- `SubscriptionPlan.fromProductDetails` reads `ProductDetails.subscriptionOfferDetails` (Android) or `ProductDetails.introductoryPrice` (iOS) and exposes `trialDays`.
- Checkout copy updates to "Free for 7 days, then ₫800.000/month" when a trial is available.
- Trial expiry triggers `subscription.expiresAt` and the Cloud Function from P0-1 charges via store.

---

### P1-3. Restore purchases UX

`purchaseRestore` strings exist; verify the wire-up end-to-end.

**Acceptance criteria**
- `Settings → Subscription → "Restore purchases"` button calls `InAppPurchase.instance.restorePurchases()`.
- Snackbar on success ("Purchases restored") / failure ("No purchases to restore").
- On a fresh install after sign-in, the same flow runs implicitly so the user's owned courses + subscription re-bind without a tap.

---

### P1-4. Notifications inbox + preferences

Notifications fire as system alerts and disappear. Many users disable system notifications and never see anything again.

**Acceptance criteria**
- Subcollection `users/{uid}/notifications/{id}`: `{ type, title, body, payload, readAt, createdAt }`. Cloud Functions write to it in parallel to the FCM send.
- `NotificationsInboxPage` reachable from the bell icon on Home + Songbooks. Read/unread badge.
- `Settings → Notifications` with toggles for each topic in `NotificationTopics` (all_users, instrument_*, admins). Toggling subscribes/unsubscribes via FCM.
- Tapping a notification deep-links via the existing `notificationTapsProvider` routing.

---

### P1-5. Reviews moderation

Anyone with access can post abusive content.

**Acceptance criteria**
- Cloud Function trigger on `courses/{cid}/reviews/{uid}` write: runs profanity filter (npm `bad-words` or PerspectiveAPI). If flagged: sets `isHidden: true` and clears `body`.
- Admin portal new page `/admin/reviews` shows recent reviews with "Hide" / "Restore" actions.
- `users/{uid}/reports/{id}` subcollection so users can flag a review with `{ targetPath, reason }`.
- Reports surface on `/admin/reports` for triage.

---

### P1-6. Suspension UI in admin

`users/{uid}.isSuspended` is already in the model and rules respect it, but there's no admin page to flip it.

**Acceptance criteria**
- `/admin/instructors` and a new `/admin/students` page each row menu has "Suspend" / "Reactivate".
- Suspension writes to `users/{uid}.isSuspended` and to `audit_log/{id}` (see Ops-7).
- Suspended users see an in-app banner explaining why and how to appeal.

---

### P1-7. Server-side aggregate counters

`CourseReviewsDataSource._recomputeAggregate` re-scans the whole subcollection on every write. At 5k+ reviews per course this becomes a 100KB read per write.

**Acceptance criteria**
- Cloud Function trigger on `courses/{cid}/reviews/{uid}` create / update / delete uses `FieldValue.increment` to update `reviewCount` + a tracked `ratingSum` field. Compute `rating = ratingSum / reviewCount`.
- Remove the client-side `_recomputeAggregate` call.
- Same pattern for `songbooks/{id}/reviews/{rid}`.
- Backfill once via an admin script in `sample_data/recompute_aggregates.js`.

---

### P1-8. Offline downloads

For subscribers in markets with expensive mobile data (VN), offline viewing is a major retention lever.

**Acceptance criteria**
- "Download" button on lecture player (visible only to users with unlocked access).
- Uses `flutter_downloader` or the video CDN's offline-DRM SDK (Mux: HLS offline; Bunny: direct MP4 cache).
- Downloaded lectures listed under `Profile → Downloads` with file size + delete action.
- Local storage encrypted via `flutter_secure_storage` for the manifest; media files use platform-default app-private storage.

---

### P1-9. Pagination on courses list

Verify `CoursesPage.cursor` is wired through to `ListView` and not just defined.

**Acceptance criteria**
- `CoursesNotifier` exposes `loadNextPage()`.
- `CoursesPage` `ListView` triggers `loadNextPage()` at 80% scroll.
- Skeleton placeholder rows during fetch.
- Tested with a seed of 100+ courses to verify smooth scroll.

---

### P1-10. Pull-to-refresh + skeletons

`CircularProgressIndicator` on first load is a regression vs perceived performance.

**Acceptance criteria**
- `RefreshIndicator` on Home, Courses list, Instructors list, Songbooks tab, Reviews list.
- Replace loading spinners with `shimmer`-style skeletons matching the eventual layout.
- New shared widget `SkeletonBox` + `SkeletonText` in `core/widgets/`.

---

### P1-11. Accessibility pass

**Acceptance criteria**
- Run Flutter `flutter_test`'s `meetsGuideline(textContrastGuideline)` audit. Fix all failures.
- Star pickers and rating widgets wrapped in `Semantics(label: '$rating of 5 stars')`.
- `MediaQuery.textScalerOf(context)` respected — verify at `2.0x` no layout breaks.
- Color contrast: trial banner `0xFFE9E1FA` vs gray text fails WCAG AA. Darken text or strengthen background.
- All `IconButton` / `InkWell` actions have a `tooltip` or `semanticsLabel`.

---

### P1-12. App rating prompt

**Acceptance criteria**
- `in_app_review` plugin.
- Trigger after the user completes their 3rd lecture, never within the first 7 days of install, never more than once per 90 days.
- Track trigger attempts in `users/{uid}.metadata.lastRatingPromptAt`.

---

### P1-13. Force-update gate

A critical bug ships and you have no way to push users off the broken version.

**Acceptance criteria**
- Remote Config keys: `min_supported_build_number_ios`, `min_supported_build_number_android`.
- On boot, compare to `packageInfo.buildNumber`. If lower, show a blocking dialog with App Store / Play Store link (`url_launcher`).
- Soft-update: if `recommended_build_number > current`, show a dismissible banner.

---

### P1-14. Localization completeness

**Acceptance criteria**
- Inventory non-localized strings: `grep -rn "Text\('" lib/ | grep -v generated | grep -v "//"` and prioritize the consumer-facing ones.
- Admin chrome and filter sheets stay EN-only for v1 (internal staff tool) — documented in `localization.md`.
- Verify `intl.DateFormat.yMMMd('vi')` is used wherever you format dates for VI users.
- New strings added to both `app_en.arb` and `app_vi.arb` in the same PR — fail CI if either is missing a key.

---

### P1-15. Search server-side fallback plan

Pulling 200 courses into memory works for v1 but breaks at ≥500 courses.

**Acceptance criteria**
- Document the swap path in `docs/search.md`:
  - Phase 1 (now): client-side ranking, capped at 200 courses.
  - Phase 2 (~1k courses): Typesense self-hosted on a $5 droplet, indexed via Cloud Function trigger on `courses` writes.
  - Phase 3 (≥10k courses): Algolia managed.
- `SearchRepository` interface stays stable across phases.

---

### P1-16. Web admin: harden auth

Admins manage all courses + revenue. They need stronger auth than email/password.

**Acceptance criteria**
- Disable email/pw sign-in on the admin portal — Google or Apple only.
- Require Firebase Auth multi-factor for `role == 'admin'` users.
- `users/{uid}.lastSignInIp` written from a Cloud Function trigger on `auth.user().beforeSignIn` for audit.
- IP allowlist configurable via Remote Config for ultra-sensitive routes.

---

## P2 — post-launch growth + retention

### P2-1. Quizzes + certificates

Massive driver of course completion + social sharing.

**Acceptance criteria**
- New `lectures/{lid}/quiz/{qid}` subcollection: `{ question, options: List<String>, correctIndex }`.
- `QuizPage` at end of each section. Pass threshold: 70%.
- On course completion (all sections passed), Cloud Function generates a PDF certificate (`pdf` package) signed by the instructor and uploads to `users/{uid}/certificates/{courseId}.pdf`.
- "Share certificate" button posts to LinkedIn / Twitter / Facebook with the PDF link.

---

### P2-2. Bookmarks / Wishlist

**Acceptance criteria**
- `users/{uid}/wishlist/{courseId}` subcollection.
- Bookmark icon on `CourseCard` + `CourseDetailPage`.
- "Saved" tab under Profile.
- Email campaign trigger: "The course you saved is on sale" when course price drops.

---

### P2-3. Course Q&A

Drives DAU and instructor engagement.

**Acceptance criteria**
- Per-lecture comment thread `courses/{cid}/sections/{sid}/lectures/{lid}/questions/{qId}` with `{ userId, body, createdAt, replyCount, isInstructorAnswered }`.
- Nested `replies/{rid}` subcollection.
- Push notification to course instructor on new question.
- Instructor replies get a "verified instructor" badge.

---

### P2-4. Notes on lectures

Cheap to build, big retention impact.

**Acceptance criteria**
- `users/{uid}/notes/{noteId}`: `{ courseId, lectureId, positionSec, body, createdAt }`.
- "Add note" button on lecture player saves with current playback position.
- Notes list under each course in `My Learning` tab, tappable to seek to position.

---

### P2-5. Learning paths

**Acceptance criteria**
- New top-level `learning_paths/{pathId}` collection: `{ title, summary, coverUrl, instrument, courseIds: List<String>, totalHours }`.
- Admin CRUD via `/admin/learning-paths`.
- Home tab adds a "Learning paths" rail.
- Path detail page lists courses in sequence with progress bar.

---

### P2-6. Practice tools (metronome + tuner)

Make users open the app daily even when not consuming content.

**Acceptance criteria**
- `Practice` tab (new bottom nav slot or accessible from Profile).
- Metronome: tempo slider (40-240 BPM), time signature picker, accent first beat, tap-tempo. Use `audioplayers` or `soundpool` for low-latency tick.
- Tuner: mic input via `pitch_detector_dart`, displays note + cents off, color-coded.

---

### P2-7. Referral program

Drives K-factor.

**Acceptance criteria**
- Each user gets a code `users/{uid}.referralCode`.
- When a new user signs up with `?ref=CODE` query string (deep link), both sides get 1 month free Personal Plan added to `subscription.expiresAt`.
- Cap at 12 successful referrals per user per year.
- "Invite friends" screen in Settings shows code, copy button, share sheet.

---

### P2-8. Coupons / promo codes

Required for any marketing campaign.

**Acceptance criteria**
- `coupons/{code}` collection: `{ discountPercent, validUntil, maxRedemptions, redemptions, scope: 'subscription' | 'course' | 'all' }`.
- App Store offer codes + Play promo codes generated via the respective consoles, redeemed via the native code-redemption sheet.
- Custom coupons (non-IAP) reduce `users/{uid}.subscription.expiresAt` extension on the server.

---

### P2-9. Revenue + cohort dashboard in admin

`fl_chart` is already in the stack.

**Acceptance criteria**
- `/admin/analytics` page with:
  - MRR + ARR line chart (last 12 months).
  - Churn cohort retention curve (month-1, month-3, month-6).
  - Top 10 courses by enrollment + revenue (table).
  - Top 10 instructors by student count + earnings.
- Source: aggregate from BigQuery export of Firestore + Analytics.

---

### P2-10. Audit log

Compliance + post-mortem gold.

**Acceptance criteria**
- `audit_log/{id}` collection: `{ actorUid, action, targetPath, before, after, timestamp }`.
- Every admin-portal write (publish course, suspend user, hide review, extend subscription, refund) writes a row.
- Function trigger writes server-attributed rows for subscription state changes.
- Admin-only readable.

---

### P2-11. Customer support entry point

**Acceptance criteria**
- Intercom or Zendesk SDK integrated. `Settings → Help` opens the chat widget.
- Alternative v1: `mailto:support@ilearnit.info` button with prefilled user ID + app version + device info.

---

### P2-12. Live classes / community

Tonebase's actual moat. Defer until you have 1k paying subscribers.

**Acceptance criteria**
- "Live now" stream on the Home tab via Mux Live or Cloudflare Stream Live.
- Discord-style instructor-led channel per instrument.
- Calendar of upcoming live classes with calendar-add integration.

---

## Ops — engineering / infrastructure plumbing

### Ops-1. Tests

No meaningful `test/` directory today.

**Acceptance criteria**
- Unit tests for `SubscriptionNotifier`, `ReviewFormNotifier`, `SearchNotifier`, `AuthNotifier` using `ProviderContainer.test`.
- Repository tests with mocked datasources, verifying every `Either<Failure, T>` branch.
- One smoke widget test per page in `features/*/presentation/pages/`.
- Target: 60% line coverage on `domain/` + `data/`, 30% on `presentation/`.

---

### Ops-2. CI/CD

**Acceptance criteria**
- GitHub Actions workflow `ci.yml`: on PR, run `flutter analyze` + `flutter test` + `flutter build apk --debug --flavor dev`.
- Workflow `release.yml`: on tag `v*`, build + upload to TestFlight via `fastlane` and Play Internal Track.
- Workflow `functions.yml`: on `functions/**` change to main, `firebase deploy --only functions --project ilearnit-prod` using service account in GH secrets.

---

### Ops-3. Staging Firebase project

`dev` and `prod` exist. Add `stage` for release candidates so QA isn't testing against dev data.

**Acceptance criteria**
- New Firebase project `ilearnit-stage`.
- `flavors.dart` gains `stage` flavor.
- `firebase_options_stage.dart` generated.
- TestFlight external testers point at the stage build.

---

### Ops-4. Firestore scheduled backups

Currently a `gcloud firestore import` is your only restore path; without scheduled exports you have nothing to restore *to*.

**Acceptance criteria**
- Cloud Scheduler job runs `gcloud firestore export` nightly to `gs://ilearnit-backups/firestore/{YYYY-MM-DD}/`.
- Bucket has lifecycle rule: delete after 30 days.
- Documented restore procedure in `docs/disaster_recovery.md`.

---

### Ops-5. Cloud Functions error reporting

**Acceptance criteria**
- Each Function wrapped in `try/catch` with `functions.logger.error(err, { extras })`.
- Cloud Error Reporting alert policy: notify Slack on any error in the last 5 minutes.

---

### Ops-6. Composite indexes documentation

`firestore.indexes.json` is empty. Several queries will eventually require composite indexes.

**Acceptance criteria**
- Document the cutover point in `firestore.indexes.json` comment header.
- Add indexes pre-emptively for:
  - `courses` (category, enrollmentCount desc) — for `popularByInstrumentProvider` when N > 500.
  - `enrollments` (userId, createdAt desc) — for "Continue learning" rail.
  - `notification_broadcasts` (status, createdAt desc) — for admin recent broadcasts pane.

---

### Ops-7. Storage CDN

Firebase Storage doesn't cache aggressively. For thumbnails + cover images, front it with Hosting rewrites for `Cache-Control: public, max-age=31536000, immutable`.

**Acceptance criteria**
- Hosting site `ilearnit-cdn.ilearnit.info` with a rewrite to a Cloud Function that proxies from Storage with strong cache headers.
- `CourseModel.thumbnailUrl` and `SongbookModel.coverUrl` rewritten on read to use the CDN domain.

---

### Ops-8. Cost monitoring

Firestore reads + FCM costs can spike unexpectedly.

**Acceptance criteria**
- GCP billing alerts at 50% / 80% / 100% of monthly budget. Recipients: vmthanh24@gmail.com + #ilearnit-ops Slack channel.
- Firebase Console → Project settings → Usage and billing → set the same alerts at the Firebase level.
- Weekly cost review documented in `docs/operations.md`.

---

## Suggested launch sequence

If filing tickets in priority order, these are the next five in the queue:

1. **P0-1** (verifyPurchase Cloud Function) — eliminates fraud risk before any marketing dollar is spent.
2. **P0-2** (DeleteAccountPage + deleteAccount callable) — unblocks Apple review.
3. **P0-7 + P0-8** together (video pipeline + progress tracking) — the core learning loop is meaningless without it.
4. **P0-6** (Crashlytics + Analytics + funnel) — so you have data to debug the next thing that breaks.
5. **P0-4 + P0-5 + P1-1** together (email verification + forgot password + onboarding) — the trifecta missing for first-time UX.

Once those are in, you're at "submittable" — everything below P0 is real launch polish but not a store-review blocker.

---

**Last updated:** 2026-06-06. Track progress by checking items off in a PR that edits this file.
