/**
 * In-app purchase verification + entitlements. Every entitlement is minted
 * HERE with the Admin SDK after the store confirms the transaction;
 * firestore.rules deny client writes to all of these paths:
 *
 *   users/{uid}/purchases/{itemId}   ownership (consumable tiers + non-consumables)
 *   users/{uid}.subscription         auto-renewable plan state
 *   transactions/{id}                ledger (anonymized on account deletion)
 *   _iap_transactions/{hash}         one doc per store transaction (idempotency + uid binding)
 *   _iap_subscriptions/{hash}        subscription chain → uid binding
 *   purchase_intents/{uid_product}   "uid is about to buy itemId with product X"
 *
 * Product design (pick per item type):
 *   • Many items, few price points → CONSUMABLE tier products
 *     (`<prefix>tier_basic`, `…_standard`) shared by all items. Needs an
 *     intent to map payment → item, and server-side consume on Play.
 *   • Few, permanent items → NON-CONSUMABLE product per item
 *     (`<prefix>item.<id>`). Restorable by the store; keyed by
 *     originalTransactionId.
 *   • Access to everything → auto-renewable SUBSCRIPTION.
 *
 * Config:
 *   secrets  APPLE_IAP_KEY_ID, APPLE_IAP_ISSUER_ID, APPLE_IAP_PRIVATE_KEY, GOOGLE_PLAY_SERVICE_ACCOUNT
 *   params   APPLE_BUNDLE_ID, APPLE_APP_ID, ANDROID_PACKAGE_NAME  (functions/.env.<alias>)
 */

import {createHash} from 'crypto';
import {FieldValue, Firestore, Timestamp, getFirestore} from 'firebase-admin/firestore';
import {HttpsError, onCall} from 'firebase-functions/v2/https';
import {logger} from 'firebase-functions/v2';
import {defineSecret, defineString} from 'firebase-functions/params';

import {APPLE_SECRETS, getAppleSubscription, getAppleTransaction, transactionIdFromReceipt} from './store/apple';
import {consumeGoogleProduct, fetchGoogleSubscription, verifyGoogleProduct} from './store/google';
import {requireAppCheck} from './app_check';

export const GOOGLE_PLAY_SERVICE_ACCOUNT = defineSecret('GOOGLE_PLAY_SERVICE_ACCOUNT');
/** Server-side truth — never trust a package name from the client. */
export const ANDROID_PACKAGE_NAME = defineString('ANDROID_PACKAGE_NAME');

const db = (): Firestore => getFirestore();
export type StorePlatform = 'ios' | 'android';

// ---------------------------------------------------------------------------
// Catalogue — MUST match the client's product ids and store configuration.
// ---------------------------------------------------------------------------

export const PRODUCT_PREFIX = 'com.example.app.';
export const TIER_PREFIX = `${PRODUCT_PREFIX}tier_`;
export const NON_CONSUMABLE_PREFIX = `${PRODUCT_PREFIX}item.`;

export function tierProductId(tier: string | undefined): string {
  return `${TIER_PREFIX}${tier || 'basic'}`;
}

/** List prices for reporting only; real proceeds come from store reports. */
const TIER_LIST_PRICE_USD: Record<string, number> = {basic: 9.99, standard: 19.99, premium: 39.99};

export const SUBSCRIPTION_PLANS: Record<string, {planId: string}> = {
  [`${PRODUCT_PREFIX}plus_monthly`]: {planId: 'monthly'},
  [`${PRODUCT_PREFIX}plus_yearly`]: {planId: 'yearly'},
};

const sha256 = (s: string) => createHash('sha256').update(s).digest('hex');
export const txnDocId = (p: StorePlatform, key: string) => sha256(`${p}:${key}`);
export const subscriptionBindingId = (p: StorePlatform, originalId: string) => sha256(`${p}:${originalId}`);

// ---------------------------------------------------------------------------
// Entitlement writers shared with storeNotifications.ts
// ---------------------------------------------------------------------------

export interface SubscriptionState {
  originalTransactionId: string;
  productId: string;
  startedAtMs: number;
  expiresAtMs: number;
  autoRenew: boolean;
  revoked: boolean;
}

export async function applySubscription(uid: string, platform: StorePlatform, s: SubscriptionState): Promise<void> {
  const plan = SUBSCRIPTION_PLANS[s.productId];
  // Refund / revoke ends access now, not at period end.
  const expiresAt = new Date(s.revoked ? Math.min(Date.now(), s.expiresAtMs) : s.expiresAtMs);
  await db().doc(`users/${uid}`).set({
    subscription: {
      planId: plan?.planId ?? null,
      productId: s.productId,
      startedAt: new Date(s.startedAtMs),
      expiresAt,
      autoRenew: s.revoked ? false : s.autoRenew,
      platform,
      originalTransactionId: s.originalTransactionId,
      verifiedAt: FieldValue.serverTimestamp(),
    },
  }, {merge: true});
}

export async function uidForSubscription(platform: StorePlatform, originalId: string): Promise<string | null> {
  const snap = await db().collection('_iap_subscriptions').doc(subscriptionBindingId(platform, originalId)).get();
  return (snap.data()?.uid as string | undefined) ?? null;
}

/** Refund / revocation of a one-time purchase. Idempotent. */
export async function revokePurchase(platform: StorePlatform, txnKey: string, reason: string): Promise<boolean> {
  const txnRef = db().collection('_iap_transactions').doc(txnDocId(platform, txnKey));
  return db().runTransaction(async (tx) => {
    const t = (await tx.get(txnRef)).data();
    if (!t) return false;
    if (t.status === 'refunded') return true;
    tx.update(txnRef, {status: 'refunded', refundReason: reason, refundedAt: FieldValue.serverTimestamp()});
    if (t.ledgerId) {
      tx.update(db().doc(`transactions/${t.ledgerId}`), {status: 'refunded', refundedAt: FieldValue.serverTimestamp()});
    }
    // Only a 'granted' transaction gave access; refunding a 'duplicate'
    // payment must not remove the original purchase.
    if (t.itemId && t.status === 'granted') {
      tx.set(db().doc(`users/${t.uid}/purchases/${t.itemId}`),
        {status: 'refunded', refundedAt: FieldValue.serverTimestamp()}, {merge: true});
    }
    logger.info(`revokePurchase: uid=${t.uid} item=${t.itemId ?? '-'} reason=${reason}`);
    return true;
  });
}

// ---------------------------------------------------------------------------
// Shared input parsing
// ---------------------------------------------------------------------------

interface VerifyInput {
  uid: string;
  platform: StorePlatform;
  productId: string;
  transactionId: string | null;
  receipt?: string;
  itemId: string;
}

function parseInput(request: {auth?: {uid: string}; data: unknown}): VerifyInput {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign-in required.');
  const d = (request.data ?? {}) as Record<string, unknown>;
  const platform = d.platform;
  if (platform !== 'ios' && platform !== 'android') throw new HttpsError('invalid-argument', 'Unsupported platform.');
  const productId = typeof d.productId === 'string' ? d.productId : '';
  const receipt = typeof d.receipt === 'string' ? d.receipt : undefined;
  const transactionId = typeof d.transactionId === 'string' ? d.transactionId : null;
  if (platform === 'android' && !receipt) throw new HttpsError('invalid-argument', 'Purchase token required.');
  if (platform === 'ios' && !transactionId && !receipt) throw new HttpsError('invalid-argument', 'transactionId required.');
  return {uid, platform, productId, transactionId, receipt,
    itemId: typeof d.itemId === 'string' ? d.itemId.trim() : ''};
}

interface VerifiedOneTime { txnKey: string; storeOrderId: string | null; originalTransactionId: string | null; purchasedAtMs: number }

/** Asks the store; null = not a valid, unrevoked purchase of productId. */
async function verifyOneTime(i: VerifyInput, keyBy: 'transaction' | 'original'): Promise<VerifiedOneTime | null> {
  try {
    if (i.platform === 'ios') {
      const id = i.transactionId ?? transactionIdFromReceipt(i.receipt);
      const found = id ? await getAppleTransaction(id) : null;
      const tx = found?.tx;
      if (!tx || tx.productId !== i.productId || tx.revocationDate != null || !tx.transactionId) return null;
      return {
        // Consumables: each purchase is unique. Non-consumables: the
        // original id is stable across restores and devices.
        txnKey: keyBy === 'original' ? (tx.originalTransactionId ?? tx.transactionId) : tx.transactionId,
        storeOrderId: tx.transactionId,
        originalTransactionId: tx.originalTransactionId ?? null,
        purchasedAtMs: tx.purchaseDate ?? Date.now(),
      };
    }
    const g = await verifyGoogleProduct(i.receipt!, i.productId, ANDROID_PACKAGE_NAME.value(), GOOGLE_PLAY_SERVICE_ACCOUNT.value());
    return g && {txnKey: g.txnKey, storeOrderId: g.orderId, originalTransactionId: g.orderId, purchasedAtMs: g.purchasedAtMs};
  } catch (e) {
    logger.error('verifyOneTime: store error', e);
    // 'unavailable' tells the client to keep the transaction open and retry.
    throw new HttpsError('unavailable', 'Could not reach the store for verification.');
  }
}

// ---------------------------------------------------------------------------
// createPurchaseIntent — consumable tiers
// ---------------------------------------------------------------------------

export const createPurchaseIntent = onCall(async (request) => {
  requireAppCheck(request, 'createPurchaseIntent');
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign-in required.');
  const itemId = String(request.data?.itemId ?? '').trim();
  if (!itemId) throw new HttpsError('invalid-argument', 'itemId is required.');

  const item = (await db().doc(`items/${itemId}`).get()).data();
  if (!item) throw new HttpsError('not-found', 'Item not found.');
  if (item.status !== 'published') throw new HttpsError('failed-precondition', 'Not available for purchase.');
  const owned = (await db().doc(`users/${uid}/purchases/${itemId}`).get()).data();
  if (owned?.status === 'purchased') throw new HttpsError('already-exists', 'Already owned.');

  // The SERVER picks the product from the item's tier — a stale or
  // tampered client can't pay a cheaper tier.
  const productId = tierProductId(item.priceTier as string | undefined);
  await db().doc(`purchase_intents/${uid}_${productId}`).set({
    uid, itemId, productId, createdAt: FieldValue.serverTimestamp(),
  });
  return {productId};
});

// ---------------------------------------------------------------------------
// verifyPurchase — consumable tier → grants one item
// ---------------------------------------------------------------------------

export const verifyPurchase = onCall({secrets: [...APPLE_SECRETS, GOOGLE_PLAY_SERVICE_ACCOUNT]}, async (request) => {
  requireAppCheck(request, 'verifyPurchase');
  const i = parseInput(request);
  if (!i.productId.startsWith(TIER_PREFIX)) throw new HttpsError('invalid-argument', 'Not a tier product.');

  // 1. Store first — no writes for bad purchases.
  const v = await verifyOneTime(i, 'transaction');
  if (!v) throw new HttpsError('permission-denied', 'Purchase verification failed.');

  // 2. Which item? Client hint, else the server-side intent (covers app
  //    kill between payment and verification).
  const intentRef = db().doc(`purchase_intents/${i.uid}_${i.productId}`);
  const itemId = i.itemId || ((await intentRef.get()).data()?.itemId as string | undefined) || '';
  const txnRef = db().collection('_iap_transactions').doc(txnDocId(i.platform, v.txnKey));

  // 3. Atomic, idempotent grant.
  const out = await db().runTransaction(async (tx) => {
    const prev = (await tx.get(txnRef)).data();
    if (prev) {
      if (prev.uid !== i.uid) throw new HttpsError('permission-denied', 'This purchase belongs to another account.');
      if (prev.status === 'refunded') throw new HttpsError('permission-denied', 'This purchase was refunded.');
      if (prev.itemId || !itemId) return {itemId: (prev.itemId as string | null) ?? null, already: true};
    }
    if (!itemId) {
      // Paid but unmatchable — record for support, don't consume.
      tx.set(txnRef, {uid: i.uid, itemId: null, productId: i.productId, platform: i.platform,
        status: 'unassigned', createdAt: FieldValue.serverTimestamp()});
      return {itemId: null, already: false};
    }
    const item = (await tx.get(db().doc(`items/${itemId}`))).data();
    if (!item) throw new HttpsError('not-found', 'Item not found.');
    if (tierProductId(item.priceTier as string | undefined) !== i.productId) {
      throw new HttpsError('failed-precondition', 'Paid tier does not match the item.');
    }
    const purchaseRef = db().doc(`users/${i.uid}/purchases/${itemId}`);
    const alreadyOwned = (await tx.get(purchaseRef)).data()?.status === 'purchased';
    const ledgerRef = db().collection('transactions').doc();

    tx.set(txnRef, {uid: i.uid, itemId, productId: i.productId, platform: i.platform,
      storeOrderId: v.storeOrderId, ledgerId: ledgerRef.id,
      status: alreadyOwned ? 'duplicate' : 'granted', createdAt: FieldValue.serverTimestamp()});
    tx.set(ledgerRef, {userId: i.uid, itemId, itemTitle: String(item.title ?? ''), productId: i.productId,
      amountUsd: TIER_LIST_PRICE_USD[String(item.priceTier || 'basic')] ?? 0, currency: 'USD',
      platform: i.platform, status: 'paid', duplicate: alreadyOwned,
      processorRef: v.storeOrderId, createdAt: FieldValue.serverTimestamp()});
    if (!alreadyOwned) {
      tx.set(purchaseRef, {itemId, productId: i.productId, status: 'purchased', platform: i.platform,
        purchasedAt: new Date(v.purchasedAtMs)}, {merge: true});
    }
    tx.delete(intentRef);
    return {itemId, already: false};
  });

  // 4. Android: consume server-side AFTER granting so the tier can be bought again.
  let consumed = false;
  if (i.platform === 'android' && out.itemId) {
    consumed = await consumeGoogleProduct(i.receipt!, i.productId, ANDROID_PACKAGE_NAME.value(),
      GOOGLE_PLAY_SERVICE_ACCOUNT.value()).catch(() => false);
  }
  if (!out.itemId) throw new HttpsError('failed-precondition', 'Payment verified but no item matched. Contact support.');
  return {ok: true, itemId: out.itemId, alreadyGranted: out.already, consumed};
});

// ---------------------------------------------------------------------------
// verifyNonConsumable — one product per item, restorable
// ---------------------------------------------------------------------------

export const verifyNonConsumable = onCall({secrets: [...APPLE_SECRETS, GOOGLE_PLAY_SERVICE_ACCOUNT]}, async (request) => {
  requireAppCheck(request, 'verifyNonConsumable');
  const i = parseInput(request);
  if (!i.productId.startsWith(NON_CONSUMABLE_PREFIX)) throw new HttpsError('invalid-argument', 'Not an item product.');

  // Map product → item from YOUR data, not the client.
  const q = await db().collection('items').where('productId', '==', i.productId).limit(1).get();
  const itemDoc = q.docs[0];
  if (!itemDoc) throw new HttpsError('not-found', 'No item for this product.');

  const v = await verifyOneTime(i, 'original');
  if (!v) throw new HttpsError('permission-denied', 'Purchase verification failed.');
  const txnRef = db().collection('_iap_transactions').doc(txnDocId(i.platform, v.txnKey));

  const already = await db().runTransaction(async (tx) => {
    const prev = (await tx.get(txnRef)).data();
    if (prev && prev.uid !== i.uid) throw new HttpsError('permission-denied', 'This purchase belongs to another account.');
    if (prev?.status === 'refunded') throw new HttpsError('permission-denied', 'This purchase was refunded.');
    if (!prev) {
      const ledgerRef = db().collection('transactions').doc();
      tx.set(txnRef, {uid: i.uid, itemId: itemDoc.id, productId: i.productId, platform: i.platform,
        storeOrderId: v.storeOrderId, ledgerId: ledgerRef.id, status: 'granted', createdAt: FieldValue.serverTimestamp()});
      tx.set(ledgerRef, {userId: i.uid, itemId: itemDoc.id, itemTitle: String(itemDoc.data().title ?? ''),
        productId: i.productId, amountUsd: Number(itemDoc.data().priceUsd ?? 0), currency: 'USD',
        platform: i.platform, status: 'paid', processorRef: v.storeOrderId, createdAt: FieldValue.serverTimestamp()});
    }
    // Restores re-run this; merge keeps it idempotent.
    tx.set(db().doc(`users/${i.uid}/purchases/${itemDoc.id}`), {itemId: itemDoc.id, productId: i.productId,
      status: 'purchased', platform: i.platform, purchasedAt: new Date(v.purchasedAtMs)}, {merge: true});
    return !!prev;
  });
  return {ok: true, itemId: itemDoc.id, alreadyGranted: already};
});

// ---------------------------------------------------------------------------
// verifySubscription
// ---------------------------------------------------------------------------

export const verifySubscription = onCall({secrets: [...APPLE_SECRETS, GOOGLE_PLAY_SERVICE_ACCOUNT]}, async (request) => {
  requireAppCheck(request, 'verifySubscription');
  const i = parseInput(request);
  if (!SUBSCRIPTION_PLANS[i.productId]) throw new HttpsError('invalid-argument', 'Not a subscription product.');

  let sub: SubscriptionState | null;
  try {
    if (i.platform === 'ios') {
      const id = i.transactionId ?? transactionIdFromReceipt(i.receipt);
      sub = id ? await getAppleSubscription(id, i.productId) : null;
    } else {
      sub = await fetchGoogleSubscription(i.receipt!, ANDROID_PACKAGE_NAME.value(), GOOGLE_PLAY_SERVICE_ACCOUNT.value());
      if (sub && sub.productId !== i.productId) sub = null;
    }
  } catch (e) {
    logger.error('verifySubscription: store error', e);
    throw new HttpsError('unavailable', 'Could not reach the store for verification.');
  }
  if (!sub) throw new HttpsError('permission-denied', 'Subscription verification failed.');

  // One store subscription ↔ one account (stops sharing one Apple ID's
  // subscription across many app accounts).
  const bindRef = db().collection('_iap_subscriptions').doc(subscriptionBindingId(i.platform, sub.originalTransactionId));
  await db().runTransaction(async (tx) => {
    const b = await tx.get(bindRef);
    if (b.exists && b.data()?.uid !== i.uid) throw new HttpsError('permission-denied', 'This subscription belongs to another account.');
    if (!b.exists) tx.set(bindRef, {uid: i.uid, platform: i.platform, productId: i.productId, createdAt: FieldValue.serverTimestamp()});
  });
  await applySubscription(i.uid, i.platform, sub);
  return {ok: true, active: !sub.revoked && sub.expiresAtMs > Date.now(), expiresAtMs: sub.expiresAtMs};
});

/** Helper for media endpoints: subscription active? */
export function subscriptionActive(user: {subscription?: {expiresAt?: Timestamp}}): boolean {
  const e = user.subscription?.expiresAt;
  return !!e && e.toMillis() > Date.now();
}
