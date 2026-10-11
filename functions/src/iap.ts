/**
 * iLearnIt — In-app purchase verification + entitlement helpers.
 *
 * Every entitlement (course ownership, Personal Plan subscription) is
 * minted HERE, with the Admin SDK, after the transaction has been
 * validated with Apple / Google. Clients cannot write
 * `users/{uid}/purchases/*`, `users/{uid}.subscription`, `enrollments/*`
 * or `transactions/*` (see firestore.rules).
 *
 * Callables:
 *   createPurchaseIntent  — records "uid is about to buy courseId" so a
 *                           purchase that lands after an app kill can
 *                           still be mapped back to its course.
 *   verifyPurchase        — validates a CONSUMABLE course-tier purchase,
 *                           grants the course, consumes the Play token.
 *   verifySubscription    — validates an auto-renewable Personal Plan
 *                           subscription and writes users/{uid}.subscription.
 *
 * Store back-ends:
 *   iOS     — App Store Server API (store/apple.ts). Lookups are by
 *             transaction id; responses are JWS-verified to Apple's root CA.
 *   Android — Google Play Developer API (store/google.ts).
 *
 * Renewals, refunds and revocations arrive via server notifications
 * (storeNotifications.ts) and are applied with the helpers exported here.
 *
 * Config: see store/apple.ts, plus
 *   firebase functions:secrets:set GOOGLE_PLAY_SERVICE_ACCOUNT   (full JSON)
 *   param ANDROID_PACKAGE_NAME (info.ilearnit.app / info.ilearnit.app.dev)
 */

import {createHash} from 'crypto';
import {getFirestore, FieldValue, Firestore, Timestamp} from 'firebase-admin/firestore';
import {HttpsError, onCall} from 'firebase-functions/v2/https';
import {logger} from 'firebase-functions/v2';
import {defineSecret, defineString} from 'firebase-functions/params';

import {
  APPLE_SECRETS,
  getAppleSubscription,
  getAppleTransaction,
  transactionIdFromReceipt,
} from './store/apple';
import {
  consumeGoogleProduct,
  fetchGoogleSubscription,
  verifyGoogleProduct,
} from './store/google';
import {requireAppCheck} from './appCheck';

export const GOOGLE_PLAY_SERVICE_ACCOUNT = defineSecret('GOOGLE_PLAY_SERVICE_ACCOUNT');
/** Server-side source of truth — never trust a package name from the client. */
export const ANDROID_PACKAGE_NAME = defineString('ANDROID_PACKAGE_NAME');

// Lazy — index.ts calls initializeApp() after module imports are hoisted.
const db = (): Firestore => getFirestore();

export type StorePlatform = 'ios' | 'android';

// ---------------------------------------------------------------------------
// Product catalogue — MUST match lib/features/purchases/domain/entities/
// price_tier.dart and subscription_plan.dart.
// ---------------------------------------------------------------------------

/** Non-consumable, one product per songbook (`songbooks/{id}.productId`). */
export const SONGBOOK_PRODUCT_PREFIX = 'info.ilearnit.songbook.';

/** Consumable course-tier product id for a course's `priceTier`. */
export function courseTierProductId(tier: string | undefined): string {
  return `info.ilearnit.course_tier_${tier || 'basic'}`;
}

/** List prices per tier — keep in sync with PriceTier.rawFallbackPrice. */
const TIER_LIST_PRICE_USD: Record<string, number> = {
  basic: 9.99,
  standard: 19.99,
  premium: 39.99,
};

export const SUBSCRIPTION_PLANS: Record<string, {planId: string}> = {
  'info.ilearnit.personal_monthly': {planId: 'monthly'},
  'info.ilearnit.personal_yearly': {planId: 'yearly'},
};

export function sha256(s: string): string {
  return createHash('sha256').update(s).digest('hex');
}

/** `_iap_transactions/{id}` — one doc per store transaction. */
export function txnDocId(platform: StorePlatform, txnKey: string): string {
  return sha256(`${platform}:${txnKey}`);
}

/** `_iap_subscriptions/{id}` — binds a store subscription chain to a uid. */
export function subscriptionBindingId(platform: StorePlatform, originalId: string): string {
  return sha256(`${platform}:${originalId}`);
}

// ---------------------------------------------------------------------------
// Entitlement helper (also used by resolveStreamPlayback / media.ts)
// ---------------------------------------------------------------------------

/**
 * True iff [uid] may play paid content of [courseId]: owns the course,
 * has an active Personal Plan, is the course's instructor, or is admin.
 */
export async function hasCourseAccess(
  uid: string,
  courseId: string,
): Promise<boolean> {
  const [userSnap, purchaseSnap, courseSnap] = await Promise.all([
    db().doc(`users/${uid}`).get(),
    db().doc(`users/${uid}/purchases/${courseId}`).get(),
    db().doc(`courses/${courseId}`).get(),
  ]);
  const user = userSnap.data() ?? {};
  if (user.isSuspended === true) return false;
  if (user.role === 'admin') return true;
  if (courseSnap.data()?.instructorId === uid) return true;

  const p = purchaseSnap.data();
  if (p && (p.status === 'purchased' || p.status === 'restored')) return true;

  const sub = user.subscription as {expiresAt?: Timestamp} | undefined;
  if (sub?.expiresAt && sub.expiresAt.toMillis() > Date.now()) return true;

  return false;
}

// ---------------------------------------------------------------------------
// Shared entitlement writers (callables + server notifications)
// ---------------------------------------------------------------------------

export interface SubscriptionState {
  originalTransactionId: string;
  productId: string;
  startedAtMs: number;
  expiresAtMs: number;
  autoRenew: boolean;
  revoked: boolean;
}

/** Writes users/{uid}.subscription from an authoritative store state. */
export async function applySubscription(
  uid: string,
  platform: StorePlatform,
  s: SubscriptionState,
): Promise<void> {
  const plan = SUBSCRIPTION_PLANS[s.productId];
  // A refunded / revoked subscription ends now, not at period end.
  const expiresAt = new Date(s.revoked ? Math.min(Date.now(), s.expiresAtMs) : s.expiresAtMs);
  await db().doc(`users/${uid}`).set({
    subscription: {
      planId: plan?.planId ?? null,
      productId: s.productId,
      startedAt: new Date(s.startedAtMs),
      expiresAt,
      autoRenew: s.revoked ? false : s.autoRenew,
      canceledAt: s.revoked ? FieldValue.serverTimestamp() : null,
      platform,
      originalTransactionId: s.originalTransactionId,
      verifiedAt: FieldValue.serverTimestamp(),
    },
  }, {merge: true});
}

/** uid that owns a store subscription chain, if we've seen it. */
export async function uidForSubscription(
  platform: StorePlatform,
  originalId: string,
): Promise<string | null> {
  const snap = await db().collection('_iap_subscriptions')
    .doc(subscriptionBindingId(platform, originalId)).get();
  return (snap.data()?.uid as string | undefined) ?? null;
}

/**
 * Refund / revocation of a course purchase: removes access, marks the
 * ledger + enrollment. Idempotent. Returns false if the transaction is
 * unknown (never verified through us).
 */
export async function revokeCoursePurchase(
  platform: StorePlatform,
  txnKey: string,
  reason: string,
): Promise<boolean> {
  const txnRef = db().collection('_iap_transactions').doc(txnDocId(platform, txnKey));
  return db().runTransaction(async (tx) => {
    const snap = await tx.get(txnRef);
    const t = snap.data();
    if (!t) return false;
    if (t.status === 'refunded') return true;
    const {uid, courseId, songbookId, ledgerId} =
      t as {uid: string; courseId?: string; songbookId?: string; ledgerId?: string};

    tx.update(txnRef, {status: 'refunded', refundReason: reason, refundedAt: FieldValue.serverTimestamp()});
    if (ledgerId) {
      tx.update(db().doc(`transactions/${ledgerId}`), {
        status: 'refunded',
        refundedAt: FieldValue.serverTimestamp(),
      });
    }
    // Only a 'granted' transaction gave access; a 'duplicate' payment for
    // an already-owned course must not revoke the original purchase.
    if (courseId && t.status === 'granted') {
      tx.set(db().doc(`users/${uid}/purchases/${courseId}`), {
        status: 'refunded',
        refundedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      tx.set(db().doc(`enrollments/${uid}_${courseId}`), {
        status: 'cancelled',
        cancelledAt: FieldValue.serverTimestamp(),
      }, {merge: true});
    }
    if (songbookId && t.status === 'granted') {
      tx.set(db().doc(`users/${uid}/songbooks/${songbookId}`), {
        status: 'refunded',
        refundedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
    }
    logger.info(
      `revokeCoursePurchase: uid=${uid} course=${courseId ?? '-'} songbook=${songbookId ?? '-'} reason=${reason}`,
    );
    return true;
  });
}

// ---------------------------------------------------------------------------
// createPurchaseIntent
// ---------------------------------------------------------------------------

export const createPurchaseIntent = onCall(async (request) => {
  requireAppCheck(request, 'createPurchaseIntent');
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign-in required.');

  const courseId = (request.data?.courseId as string | undefined)?.trim();
  if (!courseId) throw new HttpsError('invalid-argument', 'courseId is required.');

  const courseSnap = await db().doc(`courses/${courseId}`).get();
  const course = courseSnap.data();
  if (!course) throw new HttpsError('not-found', 'Course not found.');
  if (course.status !== 'published') {
    throw new HttpsError('failed-precondition', 'Course is not available for purchase.');
  }

  const owned = await db().doc(`users/${uid}/purchases/${courseId}`).get();
  if (owned.exists && owned.data()?.status === 'purchased') {
    throw new HttpsError('already-exists', 'You already own this course.');
  }

  const productId = courseTierProductId(course.priceTier as string | undefined);
  // One open intent per (uid, productId). A newer intent for the same
  // tier replaces the older one — the client only allows one purchase
  // in flight at a time.
  await db().doc(`purchase_intents/${uid}_${productId}`).set({
    uid,
    courseId,
    productId,
    createdAt: FieldValue.serverTimestamp(),
  });

  return {productId};
});

// ---------------------------------------------------------------------------
// verifyPurchase — consumable course tier
// ---------------------------------------------------------------------------

interface VerifiedCourseTxn {
  /** Store-unique id of THIS purchase (iOS transactionId / Play token). */
  txnKey: string;
  originalTransactionId: string | null;
  purchasedAtMs: number;
}

async function verifyIosCourse(
  transactionId: string | null,
  receipt: string | undefined,
  productId: string,
): Promise<VerifiedCourseTxn | null> {
  const id = transactionId ?? transactionIdFromReceipt(receipt);
  if (!id) return null;
  const found = await getAppleTransaction(id);
  if (!found) return null;
  const {tx} = found;
  // The JWS is verified (signature + bundle id) by the library; still
  // check it's the product the client claims and not refunded.
  if (tx.productId !== productId || tx.revocationDate != null || !tx.transactionId) return null;
  return {
    txnKey: tx.transactionId,
    originalTransactionId: tx.originalTransactionId ?? null,
    purchasedAtMs: tx.purchaseDate ?? Date.now(),
  };
}

export const verifyPurchase = onCall(
  {secrets: [...APPLE_SECRETS, GOOGLE_PLAY_SERVICE_ACCOUNT]},
  async (request) => {
    requireAppCheck(request, 'verifyPurchase');
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign-in required.');

    const data = (request.data ?? {}) as {
      platform?: string;
      courseId?: string | null;
      productId?: string;
      transactionId?: string | null;
      receipt?: string;
    };
    const {platform, productId, receipt} = data;
    const transactionId = data.transactionId ?? null;
    if (platform !== 'ios' && platform !== 'android') {
      throw new HttpsError('invalid-argument', `Unsupported platform: ${platform}`);
    }
    if (!productId || !productId.startsWith('info.ilearnit.course_tier_')) {
      throw new HttpsError('invalid-argument', 'Not a course product.');
    }
    if (platform === 'android' && !receipt) {
      throw new HttpsError('invalid-argument', 'Purchase token required.');
    }
    if (platform === 'ios' && !transactionId && !receipt) {
      throw new HttpsError('invalid-argument', 'transactionId or receipt required.');
    }

    // --- 1. Verify with the store FIRST (no writes on bad purchases) ---
    let verified: VerifiedCourseTxn | null;
    try {
      verified = platform === 'ios'
        ? await verifyIosCourse(transactionId, receipt, productId)
        : await verifyGoogleProduct(
            receipt!, productId, ANDROID_PACKAGE_NAME.value(), GOOGLE_PLAY_SERVICE_ACCOUNT.value(),
          ).then((g) => g && {
            txnKey: g.txnKey,
            originalTransactionId: g.orderId,
            purchasedAtMs: g.purchasedAtMs,
          });
    } catch (e) {
      logger.error('verifyPurchase: upstream verification error', e);
      throw new HttpsError('unavailable', 'Could not reach the store for verification.');
    }
    if (!verified) {
      logger.warn(`verifyPurchase: rejected uid=${uid} platform=${platform} product=${productId}`);
      throw new HttpsError('permission-denied', 'Purchase verification failed.');
    }

    // --- 2. Resolve the course: client hint, else server-side intent ---
    const intentRef = db().doc(`purchase_intents/${uid}_${productId}`);
    let courseId = (data.courseId ?? '').trim();
    if (!courseId) {
      const intent = await intentRef.get();
      courseId = (intent.data()?.courseId as string | undefined) ?? '';
    }

    const txnRef = db().collection('_iap_transactions').doc(txnDocId(platform, verified.txnKey));

    // --- 3. Atomic grant: the txn sentinel is created exactly once -----
    const outcome = await db().runTransaction(async (tx) => {
      const seen = await tx.get(txnRef);
      if (seen.exists) {
        const prev = seen.data() ?? {};
        if (prev.uid !== uid) {
          throw new HttpsError('permission-denied', 'This purchase belongs to another account.');
        }
        if (prev.status === 'refunded') {
          throw new HttpsError('permission-denied', 'This purchase was refunded.');
        }
        // A previously-unassigned payment can still be matched once the
        // client supplies the course; everything else is a replay.
        if (prev.courseId || !courseId) {
          return {alreadyGranted: true, courseId: (prev.courseId as string | null) ?? null};
        }
      }

      if (!courseId) {
        // Valid payment we can't map to a course (no hint, no intent).
        // Record it so support can reconcile; don't consume it.
        tx.set(txnRef, {
          uid, courseId: null, productId, platform,
          status: 'unassigned',
          createdAt: FieldValue.serverTimestamp(),
        });
        return {alreadyGranted: false, courseId: null};
      }

      const courseRef = db().doc(`courses/${courseId}`);
      const courseSnap = await tx.get(courseRef);
      const course = courseSnap.data();
      if (!course) throw new HttpsError('not-found', 'Course not found.');

      // Price integrity: the tier paid for must be the course's tier.
      const expectedProduct = courseTierProductId(course.priceTier as string | undefined);
      if (expectedProduct !== productId) {
        throw new HttpsError('failed-precondition',
          `Paid product ${productId} does not match course tier ${expectedProduct}.`);
      }

      const purchaseRef = db().doc(`users/${uid}/purchases/${courseId}`);
      const existing = await tx.get(purchaseRef);
      const student = (await tx.get(db().doc(`users/${uid}`))).data() ?? {};
      const alreadyOwned = existing.exists && existing.data()?.status === 'purchased';
      const purchasedAt = new Date(verified!.purchasedAtMs);
      const ledgerRef = db().collection('transactions').doc();

      tx.set(txnRef, {
        uid, courseId, productId, platform,
        // Human-readable store id: iOS transactionId / Play orderId.
        storeOrderId: platform === 'ios' ? verified!.txnKey : verified!.originalTransactionId,
        ledgerId: ledgerRef.id,
        status: alreadyOwned ? 'duplicate' : 'granted',
        createdAt: FieldValue.serverTimestamp(),
      });

      // Shape matches the admin revenue pages (lib/admin/revenue,
      // docs/instructor_revenue.md). `amountUsd` is the tier's list
      // price — the store's regional price / net proceeds come from
      // App Store Connect / Play Console reports.
      const str = (v: unknown) => (typeof v === 'string' ? v : '');
      tx.set(ledgerRef, {
        courseId,
        courseTitle: str(course.title),
        instructorId: str(course.instructorId),
        instructorName: str(course.instructorName),
        studentUid: uid,
        studentName: str(student.displayName),
        studentEmail: str(student.email),
        productId,
        amountUsd: TIER_LIST_PRICE_USD[str(course.priceTier) || 'basic'] ?? 0,
        amountVnd: 0,
        currency: 'USD',
        platform,
        status: 'paid',
        // A second payment for an already-owned course — kept so support
        // can refund it; doesn't grant anything.
        duplicate: alreadyOwned,
        processorRef: platform === 'ios' ? verified!.txnKey : verified!.originalTransactionId,
        originalTransactionId: verified!.originalTransactionId,
        createdAt: FieldValue.serverTimestamp(),
      });

      if (!alreadyOwned) {
        tx.set(purchaseRef, {
          courseId,
          productId,
          status: 'purchased',
          transactionId: platform === 'ios' ? verified!.txnKey : verified!.originalTransactionId,
          originalTransactionId: verified!.originalTransactionId,
          source: 'purchase',
          purchasedAt,
        }, {merge: true});
        tx.set(db().doc(`enrollments/${uid}_${courseId}`), {
          userId: uid,
          courseId,
          courseTitle: typeof course.title === 'string' ? course.title : '',
          instructorId: typeof course.instructorId === 'string' ? course.instructorId : null,
          status: 'active',
          createdAt: FieldValue.serverTimestamp(),
          source: platform,
        }, {merge: true});
      }
      tx.delete(intentRef);
      return {alreadyGranted: false, courseId};
    });

    // --- 4. Android: consume server-side so the tier can be bought again.
    let consumed = false;
    if (platform === 'android' && outcome.courseId) {
      consumed = await consumeGoogleProduct(
        receipt!, productId, ANDROID_PACKAGE_NAME.value(), GOOGLE_PLAY_SERVICE_ACCOUNT.value(),
      ).catch((e) => {
        logger.error('verifyPurchase: consume failed (will retry on replay)', e);
        return false;
      });
    }

    if (!outcome.courseId) {
      throw new HttpsError('failed-precondition',
        'Payment verified but no course could be matched. Contact support.');
    }

    logger.info(`verifyPurchase: uid=${uid} course=${outcome.courseId} already=${outcome.alreadyGranted}`);
    return {ok: true, courseId: outcome.courseId, alreadyGranted: outcome.alreadyGranted, consumed};
  },
);

// ---------------------------------------------------------------------------
// verifySubscription — auto-renewable Personal Plan
// ---------------------------------------------------------------------------

export const verifySubscription = onCall(
  {secrets: [...APPLE_SECRETS, GOOGLE_PLAY_SERVICE_ACCOUNT]},
  async (request) => {
    requireAppCheck(request, 'verifySubscription');
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign-in required.');

    const data = (request.data ?? {}) as {
      platform?: string;
      productId?: string;
      transactionId?: string | null;
      receipt?: string;
    };
    const {platform, productId, receipt} = data;
    if (platform !== 'ios' && platform !== 'android') {
      throw new HttpsError('invalid-argument', `Unsupported platform: ${platform}`);
    }
    if (!productId || !SUBSCRIPTION_PLANS[productId]) {
      throw new HttpsError('invalid-argument', 'Not a subscription product.');
    }

    let sub: SubscriptionState | null;
    try {
      if (platform === 'ios') {
        const id = data.transactionId ?? transactionIdFromReceipt(receipt);
        sub = id ? await getAppleSubscription(id, productId) : null;
      } else {
        sub = receipt
          ? await fetchGoogleSubscription(receipt, ANDROID_PACKAGE_NAME.value(), GOOGLE_PLAY_SERVICE_ACCOUNT.value())
          : null;
        if (sub && sub.productId !== productId) sub = null;
      }
    } catch (e) {
      logger.error('verifySubscription: upstream verification error', e);
      throw new HttpsError('unavailable', 'Could not reach the store for verification.');
    }
    if (!sub) throw new HttpsError('permission-denied', 'Subscription verification failed.');

    // Bind the store subscription to exactly one iLearnIt account.
    const bindRef = db().collection('_iap_subscriptions')
      .doc(subscriptionBindingId(platform, sub.originalTransactionId));
    await db().runTransaction(async (tx) => {
      const bind = await tx.get(bindRef);
      if (bind.exists && bind.data()?.uid !== uid) {
        throw new HttpsError('permission-denied', 'This subscription belongs to another account.');
      }
      if (!bind.exists) {
        tx.set(bindRef, {uid, platform, productId, createdAt: FieldValue.serverTimestamp()});
      }
    });
    await applySubscription(uid, platform, sub);

    const active = !sub.revoked && sub.expiresAtMs > Date.now();
    return {ok: true, active, expiresAtMs: sub.expiresAtMs};
  },
);

// ---------------------------------------------------------------------------
// Songbooks — non-consumable, one product per songbook
// ---------------------------------------------------------------------------

/**
 * True iff [uid] may open the full content of [songbookId]: owns it,
 * has an active Personal Plan, or is admin. Suspended users never.
 */
export async function hasSongbookAccess(uid: string, songbookId: string): Promise<boolean> {
  const [userSnap, ownSnap] = await Promise.all([
    db().doc(`users/${uid}`).get(),
    db().doc(`users/${uid}/songbooks/${songbookId}`).get(),
  ]);
  const user = userSnap.data() ?? {};
  if (user.isSuspended === true) return false;
  if (user.role === 'admin') return true;
  if (ownSnap.data()?.status === 'purchased') return true;
  const sub = user.subscription as {expiresAt?: Timestamp} | undefined;
  return !!sub?.expiresAt && sub.expiresAt.toMillis() > Date.now();
}

/**
 * Verifies a songbook purchase (or restore) and writes
 * `users/{uid}/songbooks/{songbookId}`.
 *
 * Non-consumable, so the store transaction is keyed by its stable id —
 * iOS `originalTransactionId` (same across restores / devices), Play
 * purchase token — and bound to the first iLearnIt account that claims it.
 * Re-verifying (restore, reinstall) is idempotent.
 */
export const verifySongbookPurchase = onCall(
  {secrets: [...APPLE_SECRETS, GOOGLE_PLAY_SERVICE_ACCOUNT]},
  async (request) => {
    requireAppCheck(request, 'verifySongbookPurchase');
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign-in required.');

    const data = (request.data ?? {}) as {
      platform?: string;
      productId?: string;
      transactionId?: string | null;
      receipt?: string;
    };
    const {platform, productId, receipt} = data;
    const transactionId = data.transactionId ?? null;
    if (platform !== 'ios' && platform !== 'android') {
      throw new HttpsError('invalid-argument', `Unsupported platform: ${platform}`);
    }
    if (!productId || !productId.startsWith(SONGBOOK_PRODUCT_PREFIX)) {
      throw new HttpsError('invalid-argument', 'Not a songbook product.');
    }

    // Which songbook is this product for?
    const books = await db().collection('songbooks')
      .where('productId', '==', productId).limit(1).get();
    const bookDoc = books.docs[0];
    if (!bookDoc) throw new HttpsError('not-found', 'Songbook not found for this product.');
    const book = bookDoc.data();

    // Verify with the store.
    let key: string | null = null;
    let storeRef: string | null = null;
    let purchasedAtMs = Date.now();
    try {
      if (platform === 'ios') {
        const id = transactionId ?? transactionIdFromReceipt(receipt);
        const found = id ? await getAppleTransaction(id) : null;
        const tx = found?.tx;
        if (tx && tx.productId === productId && tx.revocationDate == null) {
          key = tx.originalTransactionId ?? tx.transactionId ?? null;
          storeRef = tx.transactionId ?? null;
          purchasedAtMs = tx.originalPurchaseDate ?? tx.purchaseDate ?? purchasedAtMs;
        }
      } else if (receipt) {
        const g = await verifyGoogleProduct(
          receipt, productId, ANDROID_PACKAGE_NAME.value(), GOOGLE_PLAY_SERVICE_ACCOUNT.value(),
        );
        if (g) {
          key = g.txnKey;
          storeRef = g.orderId;
          purchasedAtMs = g.purchasedAtMs;
        }
      }
    } catch (e) {
      logger.error('verifySongbookPurchase: upstream verification error', e);
      throw new HttpsError('unavailable', 'Could not reach the store for verification.');
    }
    if (!key) throw new HttpsError('permission-denied', 'Purchase verification failed.');

    const txnRef = db().collection('_iap_transactions').doc(txnDocId(platform, key));
    const ownRef = db().doc(`users/${uid}/songbooks/${bookDoc.id}`);

    const alreadyGranted = await db().runTransaction(async (tx) => {
      const seen = await tx.get(txnRef);
      const prev = seen.data();
      if (prev && prev.uid !== uid) {
        throw new HttpsError('permission-denied', 'This purchase belongs to another account.');
      }
      if (prev?.status === 'refunded') {
        throw new HttpsError('permission-denied', 'This purchase was refunded.');
      }
      const student = (await tx.get(db().doc(`users/${uid}`))).data() ?? {};

      if (!prev) {
        const ledgerRef = db().collection('transactions').doc();
        const str = (v: unknown) => (typeof v === 'string' ? v : '');
        tx.set(txnRef, {
          uid, songbookId: bookDoc.id, productId, platform,
          storeOrderId: storeRef, ledgerId: ledgerRef.id,
          status: 'granted', createdAt: FieldValue.serverTimestamp(),
        });
        // Same ledger as courses; `kind` distinguishes songbooks.
        // courseId/courseTitle carry the songbook so the admin
        // transactions page can list it without schema changes.
        tx.set(ledgerRef, {
          kind: 'songbook',
          courseId: `songbook:${bookDoc.id}`,
          courseTitle: str(book.title),
          songbookId: bookDoc.id,
          instructorId: '',
          instructorName: str(book.publisher),
          studentUid: uid,
          studentName: str(student.displayName),
          studentEmail: str(student.email),
          productId,
          amountUsd: typeof book.priceUsd === 'number' ? book.priceUsd : 0,
          amountVnd: 0,
          currency: 'USD',
          platform,
          status: 'paid',
          duplicate: false,
          processorRef: storeRef,
          originalTransactionId: key,
          createdAt: FieldValue.serverTimestamp(),
        });
      }
      tx.set(ownRef, {
        songbookId: bookDoc.id,
        productId,
        status: 'purchased',
        platform,
        purchasedAt: new Date(purchasedAtMs),
      }, {merge: true});
      return !!prev;
    });

    logger.info(`verifySongbookPurchase: uid=${uid} songbook=${bookDoc.id} already=${alreadyGranted}`);
    return {ok: true, songbookId: bookDoc.id, alreadyGranted};
  },
);

