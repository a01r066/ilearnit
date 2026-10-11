# Firebase app security audit checklist

Work through each section; for every "no", note file + line and a fix.
Severity guide: **Critical** = privilege escalation / free paid content /
money; **High** = data exposure of other users; **Medium** = abuse,
integrity; **Low** = hygiene.

## Identity & roles
- [ ] `users/{uid}` create pins `role`, `isSuspended`, server fields. (Critical)
- [ ] Owner update forbids role / suspension / subscription / counters. (Critical)
- [ ] Every privileged callable checks role server-side before mutating. (Critical)
- [ ] Suspended users are denied in rules helpers and `hasAccess`. (High)

## Entitlements & money
- [ ] Clients cannot write purchases, subscription, enrollments, ledger. (Critical)
- [ ] Recursive wildcards don't re-open those paths (rules are OR-ed). (Critical)
- [ ] Purchases verified with the store server-side; product/price derived server-side. (Critical)
- [ ] Store transaction ids are idempotency keys bound to one uid. (High)
- [ ] Refund/revocation notifications revoke access. (High)
- [ ] Only last4 of any card ever stored; no PAN/CVV/billing address. (Critical)

## Content visibility
- [ ] Drafts/unpublished not readable by `get` or `list`. (High)
- [ ] Every client list query includes the filter the rules require. (Medium — otherwise breaks)
- [ ] Paid media URLs not stored in readable docs; served via signed URL / token after entitlement check. (Critical)
- [ ] Storage download tokens stripped on private prefixes. (Critical)
- [ ] Signed-URL callable checks the object belongs to the requested item. (High)
- [ ] Video CDN assets require signed URLs. (Critical)

## UGC
- [ ] Author-only writes; author id equals `request.auth.uid`. (High)
- [ ] Reviews gated on ownership; ratings aggregated by trigger. (Medium)
- [ ] Report + block + moderation path exists (App Store 1.2 / Play UGC policy). (Medium)
- [ ] Field types/sizes validated (`is string`, `.size() < N`). (Low)

## Devices & sessions
- [ ] FCM token removed from profile before sign-out; token deleted after. (Medium)
- [ ] Offline paid files, players, URL caches cleared on sign-out. (High)
- [ ] Offline files excluded from device backups. (Low)
- [ ] Dev builds cannot reach prod Firebase (Dart-side options, no bundled plist). (High)

## Secrets & infra
- [ ] No API tokens/keys with write scope in the client or repo. (Critical)
- [ ] Service-account JSON gitignored and absent from history. (Critical)
- [ ] Secrets via `defineSecret`; params per project via `.env.<alias>`. (Low)
- [ ] App Check activated on clients; callables use `requireAppCheck`; enforcement plan. (Medium)
- [ ] Force-update gate exists to retire builds that predate a security fix. (Medium)

## Account deletion
- [ ] In-app delete (store requirement) removes user doc + all subcollections, UGC, Storage, Auth user. (High)
- [ ] Ledger anonymized, not deleted, where law requires retention. (Low)

## Verification
- [ ] Emulator rules tests for the Critical items above.
- [ ] `scripts/rules_lint.py` run; findings triaged.
