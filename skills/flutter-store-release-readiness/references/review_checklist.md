# Release review checklist

Mark each item; anything unchecked is a likely rejection or production incident.

## Both stores
- [ ] Privacy policy URL live, linked in listing and in-app; matches actual data use.
- [ ] Terms of Service / EULA covers every paid product type (subscriptions AND one-time purchases).
- [ ] In-app account deletion that deletes server data (or clearly explains retention).
- [ ] Guest browsing for non-account content.
- [ ] No placeholder, "coming soon", or no-op controls.
- [ ] All user-visible strings localized for every listed language; legal docs per language with fallback.
- [ ] Demo credentials + review notes (where IAPs are, how to reach paid content).
- [ ] Crash-free on a clean install, offline start, slow network, sign-out/sign-in as another user.
- [ ] Force-update gate configured; `min_build` set after breaking backend changes.
- [ ] App Check active (monitor or enforced) and debug tokens registered for CI/QA.

## Apple (App Review Guidelines)
- [ ] 1.2 UGC: report, block, filter, terms acceptance, timely moderation.
- [ ] 2.1 Completeness: no crashes, no broken links, no dead buttons, IAPs submitted with the build.
- [ ] 2.3 Accurate metadata/screenshots; 2.3.8 age rating answers.
- [ ] 2.5.1 Public APIs only; background modes justified.
- [ ] 3.1.1 Digital goods via IAP; Restore Purchases; no external purchase links (unless entitled).
- [ ] 3.1.2 Subscription disclosure: price, period, trial, auto-renew, manage link, Terms + Privacy links on paywall.
- [ ] 4.8 Sign in with Apple when other social logins exist.
- [ ] 5.1.1 Data collection: privacy manifest, App Privacy answers, purpose strings, account deletion, no forced login.
- [ ] 5.1.2 No tracking without ATT; NSPrivacyTracking false otherwise.
- [ ] iOS data-storage: re-downloadable files excluded from backup.
- [ ] Push permission requested in context.

## Google Play
- [ ] Target API level meets current requirement.
- [ ] Data safety form complete and consistent.
- [ ] Permissions declaration: no unused sensitive permissions (media, location, AD_ID).
- [ ] Account deletion: in-app AND a web link in the Data safety section.
- [ ] Subscriptions: clear terms, cancel instructions; RTDN configured.
- [ ] UGC policy: reporting/blocking.
- [ ] App signing by Google Play; upload key secured; SHA-256 fingerprints added to Firebase.
- [ ] Notification small icon monochrome; POST_NOTIFICATIONS requested in context (Android 13+).
- [ ] Closed testing requirement for new personal developer accounts (testers × days) met.
