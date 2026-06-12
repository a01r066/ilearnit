# Instructor Revenue & Student Management

Udemy-style revenue dashboards + admin-side transactions / payouts /
refunds. All UI lives in the admin web portal — there are no consumer
mobile screens for this feature.

## Role matrix

| Capability | Instructor | Admin |
|---|---|---|
| See own course enrollments | ✓ | ✓ (all) |
| See revenue summary | ✓ (own) | ✓ (all) |
| See per-course performance | ✓ (own) | ✓ (all) |
| Communicate with enrolled students | ✓ (broadcast) | ✓ |
| Export CSV | ✓ | ✓ |
| See other instructors' students | ✗ | ✓ |
| See full payment card data | ✗ (last4 only) | ✗ (last4 only) |
| Modify transactions | ✗ | via `processRefund` callable |
| Manage refunds | ✗ | ✓ |
| Manage payouts | ✗ | ✓ |
| Generate financial reports | ✓ (CSV) | ✓ (CSV) |

Privacy is **enforced server-side by Firestore rules**, not just by
hiding UI. Instructors literally cannot read transactions or
enrollments outside their own courses.

## Routes

```
/my-revenue          instructor + admin   InstructorRevenuePage
/my-students         instructor + admin   InstructorStudentsPage
/admin/transactions  admin only           AdminTransactionsPage
/admin/payouts       admin only           AdminPayoutsPage
```

The admin router's `_isAdminOnly` allow-list gates `/admin/*` paths so
an instructor typing the URL is redirected back to `/`.

## Firestore schema

```
transactions/{transactionId}
  courseId        string
  courseTitle     string                  (denormalized)
  instructorId    string                  (denormalized — query key)
  instructorName  string
  studentUid      string
  studentName     string
  studentEmail    string
  amountUsd       number
  amountVnd       number?
  currency        'USD' | 'VND' | …
  platform        'ios' | 'android' | 'web'
  status          'paid' | 'refunded' | 'pending'
  last4           string?                 (last 4 of payment method — display only)
  processorRef    string?                 (App Store transactionId / Play purchaseToken)
  createdAt       Timestamp
  refundedAt      Timestamp?
  refundReason    string?
  refundedByUid   string?

payouts/{payoutId}
  instructorUid   string                  (query key)
  instructorName  string
  periodStart     Timestamp
  periodEnd       Timestamp
  grossUsd        number
  platformFee     number
  netUsd          number                  (gross - fee)
  status          'pending' | 'paid' | 'cancelled'
  paidAt          Timestamp?
  paidByUid       string?                 (admin who clicked Mark paid)
  payoutMethod    string?                 ('bank' | 'stripe' | 'wise' | free-form)
  txnIds          array<string>
  createdAt       Timestamp
```

### What's NOT stored

- Full PANs, CVVs, billing addresses — those live in the storefront
  receipt (App Store / Play Store) and the storefront is authoritative.
- Personally identifying card data — only `last4` is kept, and only
  for display in the transaction list.

## Firestore rules

```
transactions/{txnId}
  read   : studentUid == uid || instructorId == uid || isAdmin()
  create : false   (Cloud Functions only — admin SDK bypasses rules)
  update : false
  delete : false

payouts/{payoutId}
  read   : instructorUid == uid || isAdmin()
  create : isAdmin()
  update : isAdmin()
  delete : isAdmin()

enrollments/{id}
  read   : userId == uid
           || isAdmin()
           || (isInstructor()
               && get(courses/{courseId}).data.instructorId == uid)
```

The `enrollments` rule extension uses a single `get()` cross-reference
to verify the instructor owns the course. Costs one extra read per
matching enrollment — fine for an admin-only page that loads
dozens of rows.

## Cloud Functions

| Function | Caller | What it does |
|---|---|---|
| `processRefund` | admin | Flip `transactions/{id}.status = 'refunded'`, cancel matching enrollment, notify student via inbox + push. |
| `instructorBroadcast` | instructor (own course) or admin | Resolve the course's enrolled students server-side; fan out a push + inbox row to each via `notifyUser`. Title ≤ 80 chars, body ≤ 800 chars. |
| `markPayoutPaid` | admin | Flip `payouts/{id}.status = 'paid'`, stamp `paidAt`, `paidByUid`, `payoutMethod`. |

All three use the existing `notifyUser` helper for delivery — no new
notification plumbing.

## Composite indexes

Declared in `firestore.indexes.json`:

```
transactions: (instructorId ASC, createdAt DESC)
transactions: (status ASC, createdAt DESC)
transactions: (courseId ASC, createdAt DESC)
payouts:      (instructorUid ASC, periodEnd DESC)
enrollments:  (courseId ASC, createdAt DESC)
```

The Dart queries currently sort client-side after a single `where`
filter to avoid blocking the UI on first deploy. Once you run
`firebase deploy --only firestore:indexes`, you can re-enable
server-side `.orderBy()` in the datasources for free.

## CSV export

`lib/admin/revenue/presentation/utils/csv_export.dart` —
`buildCsv(header, rows)` produces an RFC 4180 string and
`triggerCsvDownload(csv, filename)` triggers a Blob download via
`dart:html` (web-only — the admin portal IS web).

Every page that shows tabular data has an Export CSV button at the
top right. Filename templates:

- `my_revenue_<timestamp>.csv`
- `students_<courseTitle>_<date>.csv`
- `admin_transactions_<timestamp>.csv`
- `payouts_<date>.csv`

## Where transactions come from

The roadmap item P0-1 (server-side IAP receipt verification, in
`docs/go_live_roadmap.md`) is the future writer of the `transactions`
collection. Until that lands, transactions are seeded manually — see
`sample_data/seed_firestore.js` for a future `--only=transactions`
extension, or write docs directly via the Firebase console.

A transaction's `instructorId` MUST match the course's
`courses/{id}.instructorId` for any of the instructor-side queries to
work. The receipt verifier will denormalize this at write time.

## Communication channel rationale

We picked **one-shot broadcast** over chat for v1 because:

1. The push + inbox infrastructure (`notifyUser` helper) already exists
   from P1-4 — reusing it is one Cloud Function instead of an entire
   chat backend.
2. Instructor → students is the dominant direction at launch. Student
   → instructor is already covered by Course Q&A
   (`docs/qa.md`).
3. Broadcast prevents the reply-storm load pattern.

If the product warrants true DMs later, add a `dm_threads/{tid}` /
`messages/{mid}` subcollection and a per-pair rate limit, then expose
it as a second nav item — the existing broadcast stays as a
parallel mode.

## Refund + payout policy

**v1 is bookkeeping-only.** No real money moves through the system.

- A refund flips `transactions.{status: 'refunded'}` and cancels the
  matching `enrollments/{id}` doc. The actual storefront refund is
  processed out-of-band (App Store Connect → Sales and Trends →
  refund, or Play Console → Order management). Best practice: refund
  in the storefront first, then click Refund in admin so the
  bookkeeping reflects reality.
- A payout marks `payouts.{status: 'paid'}` after the admin has
  processed the actual bank wire / Stripe Connect transfer / Wise
  payment outside the system.

Upgrading to real money movement (Stripe Connect for payouts;
App Store Server Notifications V2 / Play Voided Purchases webhook for
auto-refunds) is filed as P0-1 follow-on work.

## Required follow-up after pulling this branch

```bash
# 1. Regenerate freezed + JsonSerializable for the new entities/models.
dart run build_runner build --delete-conflicting-outputs

# 2. Deploy the Cloud Functions.
cd functions
npm run build
cd ..
firebase deploy --only functions:processRefund,functions:markPayoutPaid,functions:instructorBroadcast --project ilearnit-dev

# 3. Deploy Firestore rules + indexes.
firebase deploy --only firestore:rules,firestore:indexes --project ilearnit-dev
```

## Testing checklist

| Scenario | Expected |
|---|---|
| Instructor opens `/my-revenue` with 0 transactions | KPI cards show $0; recent list shows "No transactions yet." |
| Seed 5 paid transactions for instructor A | KPIs reflect totals; Recent shows newest-first |
| Refund one transaction in admin | Refund pill on row; KPI total drops; student gets inbox row + push |
| Instructor A opens `/my-students` | Each of A's courses listed; per-course student count matches |
| Instructor A opens any URL containing instructor B's `courseId` | Firestore rules deny — page shows error block |
| Instructor A clicks Message students on a course | Dialog opens; on Send, snackbar reports "Sent to N students."; B's students NOT included |
| Admin opens `/admin/transactions` | All transactions across all instructors; filter chips switch the stream |
| Admin clicks Refund | Confirmation dialog → snackbar → row updates live (stream re-emits) |
| Admin opens `/admin/payouts` with 0 docs | Empty state explains how to create |
| Admin clicks Mark paid on a pending payout | Status flips to PAID live |
| Non-admin instructor visits `/admin/transactions` | Router redirects to dashboard |
| Export CSV from any of the 4 pages | Browser downloads a UTF-8 BOM-prefixed CSV with the expected headers |

## Files

```
lib/admin/revenue/
  domain/entities/
    transaction.dart         TransactionEntity
    payout.dart              PayoutEntity
    revenue_summary.dart     RevenueSummary + CourseRevenue
  data/models/
    transaction_model.dart   freezed + json
    payout_model.dart        freezed + json
  data/datasources/
    instructor_revenue_datasource.dart   own-only reads + summary
    admin_revenue_datasource.dart        all-reads + Cloud Function mutators
  presentation/
    providers/revenue_providers.dart     Riverpod wiring
    utils/csv_export.dart                buildCsv + triggerCsvDownload
    pages/
      instructor_revenue_page.dart       /my-revenue
      instructor_students_page.dart      /my-students
      admin_transactions_page.dart       /admin/transactions
      admin_payouts_page.dart            /admin/payouts

functions/src/index.ts
  + processRefund        Cloud Function
  + markPayoutPaid       Cloud Function
  + instructorBroadcast  Cloud Function

firestore.rules           + transactions/{txnId} + payouts/{id} +
                            enrollments owner-instructor read
firestore.indexes.json    + 5 composite indexes
lib/admin/routing/admin_route_names.dart   + 4 route + path constants
lib/admin/routing/admin_router.dart        + 4 GoRoute entries
lib/admin/shared/widgets/admin_scaffold.dart  + 4 side-nav items
docs/instructor_revenue.md                 this file
```
