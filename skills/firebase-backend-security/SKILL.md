---
name: firebase-backend-security
description: Security model for Firebase-backed mobile apps — Firestore and Storage security rules, Cloud Functions (v2, TypeScript) as the only writer of privileged state, role checks, server-side entitlement checks, signed URLs for paid media, App Check gating, account deletion and secrets handling. Use this skill whenever you write or review firestore.rules / storage.rules, add a Cloud Function or callable, store roles, purchases, subscriptions, counters or ratings, serve paid or private files, implement delete-account, or audit a Firebase app for security — even if the user only says "add a collection" or "let users upload X".
---

# Firebase backend security

**Principle: the client is untrusted.** Anything that grants access,
changes a role, moves money or aggregates other users' data is written
by Cloud Functions (Admin SDK bypasses rules) after a server-side
check. Rules exist to *deny* those writes to clients and to scope
everything else to its owner.

Read `references/threat_checklist.md` when auditing an existing project.
Run `scripts/rules_lint.py firestore.rules storage.rules` for a quick
static pass (heuristics, not a proof — still read the rules).

## 1. Identity and roles

- Store `role` (`user | moderator | admin`, plus any app roles) and
  `isSuspended` on `users/{uid}`. Rules helpers and the Functions'
  `getRole()` both read these fields, so **the create rule must pin
  them**: a new account may only create its own doc with role `user`,
  `isSuspended == false`, and no server-owned fields. Without this,
  anyone can sign up through the Auth REST API and write `role: 'admin'`.
- Owner updates use `diff(...).affectedKeys().hasAny([...server fields])`
  to forbid touching `role`, `isSuspended`, `subscription`, counters.
- Role changes happen in an admin tool through a callable that checks
  `getRole(caller) === 'admin'` **before any mutation**. Same for refunds,
  payouts, broadcasts — every privileged callable starts with the check.
- Custom claims are optional; if you add them, keep the Firestore field
  as the source of truth and sync claims in a trigger.

Template: `templates/firestore.rules` (users block, helpers).

## 2. Server-owned data

| Kind | Example path | Client access |
|---|---|---|
| Entitlements | `users/{uid}/purchases/{id}`, `users/{uid}.subscription` | owner read, **no writes** |
| Ledger | `transactions/{id}` | owner/admin read, no writes |
| Idempotency / bindings | `_iap_transactions/*`, `_iap_subscriptions/*`, `purchase_intents/*` | none |
| Aggregates | `items/{id}.rating`, `.reviewCount`, `.enrollCount` | read only; trigger maintains |
| Inbox | `users/{uid}/notifications/{id}` | owner read, update `readAt` only, delete |

Pattern for aggregates: an `onDocumentWritten` trigger on the child
collection recomputes (or transactionally increments) the parent field.
Client-incremented counters are abusable; if you must allow one, bound
it (`== resource.data.count + 1`) and accept the risk explicitly.

## 3. Catalogue visibility

- `get`: published docs for everyone; drafts only for owner/admin (and
  past buyers if archived content must stay openable).
- `list`: rules can't filter results — they reject queries that *could*
  return forbidden docs. Require the filter in the rule
  (`resource.data.status == 'published' || resource.data.ownerId ==
  uid()`), and make every client query include it.
- UGC (reviews, Q&A): author-only writes; gate reviews on ownership
  (`exists(/users/$(uid())/purchases/$(itemId))` or active subscription);
  moderators can hide; reports are create-only for users.
- Blocking: store `users/{uid}/blocks/{otherUid}`; filter client-side
  and skip notifications server-side.

## 4. Paid / private media

Never put a usable URL for paid content in a readable doc.

- **Firebase Storage**: store `gs://bucket/path` in the doc. A callable
  (`resolveMedia`) checks entitlement (preview flag, or `hasAccess(uid,
  itemId)`), verifies the path belongs to that item, and returns a **V4
  signed URL** (≈4 h). The Functions service account needs *Service
  Account Token Creator* on itself for `getSignedUrl`.
- **Strip download tokens**: Firebase SDK uploads add
  `firebaseStorageDownloadTokens`, which makes the object public to
  anyone with the URL regardless of rules. An `onObjectFinalized` trigger
  removes it for private prefixes. Provide a one-off admin migration for
  legacy docs that stored `https://firebasestorage…?token=` URLs.
- **Storage rules**: private prefixes readable only by owner/admin;
  writes only by the owner of the parent doc (`firestore.get` the
  parent in a `canManage(itemId)` helper).
- **Video CDN (e.g. Cloudflare Stream, Mux)**: enable signed URLs on the
  asset; a callable mints a short-lived playback token after the same
  entitlement check. CDN API tokens live only in Functions secrets.
- Client caches signed URLs for less than their TTL (e.g. 50 min) and
  clears them on sign-out.

Templates: `templates/functions/src/media.ts`, `access.ts`,
`templates/storage.rules`.

## 5. Callables checklist

Every `onCall` handler, in this order:

1. `requireAppCheck(request, name)` — monitor mode first, enforce later
   via a boolean param (`ENFORCE_APP_CHECK`) so no redeploy of clients
   is needed.
2. `request.auth?.uid` or `unauthenticated`.
3. Validate and trim every input; never trust IDs, prices, product ids,
   package names or platform from the client — read them from your own
   docs / params.
4. Authorization (`getRole`, ownership, `hasAccess`).
5. Mutations in a Firestore **transaction** when they must be atomic or
   idempotent (store transaction ids, one-time grants).
6. Throw `HttpsError` with a stable `code` and a user-safe message; log
   details with `logger`, never secrets or full receipts.

Template: `templates/functions/src/callable_template.ts`.

## 6. Account deletion (store requirement)

A `deleteAccount` callable (re-auth on the client first) must:
delete `users/{uid}` and **all subcollections** (`recursiveDelete`),
the user's UGC or anonymize it, FCM tokens, Storage under
`users/{uid}/`, bindings that would block re-purchase, then
`auth.deleteUser(uid)`. Keep financial ledgers but anonymize
(`studentName: 'Deleted user'`, drop email) — you usually must retain
transactions for tax. Sign the client out and run session cleanup.

Template: `templates/functions/src/delete_account.ts`.

## 7. Secrets and config

- Secrets: `firebase functions:secrets:set NAME` and
  `defineSecret('NAME')`; declare them on each function that uses them.
- Non-secret per-project params (`ANDROID_PACKAGE_NAME`, bundle id,
  feature flags): `defineString/defineBoolean` with
  `functions/.env.<project-alias>`.
- Service-account JSON keys never enter git (`.gitignore` them); rotate
  any token that has been pasted into chat, docs or an issue.
- Nothing secret in the Flutter client — anything in the binary is
  public.

## 8. Device & session hygiene (client side of security)

Before `signOut()`: remove this device's FCM token from the user doc
(only the signed-in owner may). After: delete the FCM token, wipe
offline paid files, clear signed-URL caches, stop players. See
`flutter-riverpod-firebase-architecture` §7.

## 9. Deploying rules safely

- Test with the Emulator Suite + `@firebase/rules-unit-testing`; write
  at least: guest can't read drafts, user can't write `role`, user can't
  write purchases, list query without filter is denied.
- Deploy rules and the client change that adds query filters together;
  ship a force-update (Remote Config `min_build_*`) when old builds would
  break.
