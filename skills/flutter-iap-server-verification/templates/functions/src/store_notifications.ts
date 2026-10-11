/**
 * Store → server notifications. Keep entitlements right when the app is
 * closed: renewals, expirations, refunds, revocations.
 *
 * appStoreNotifications — App Store Server Notifications v2 (HTTPS).
 *   App Store Connect → App → App Information → App Store Server
 *   Notifications → Production + Sandbox URL = this function, Version 2.
 *   Body is UNAUTHENTICATED: JWS-verify before trusting anything.
 *
 * playRtdn — Google Play Real-time Developer Notifications (Pub/Sub).
 *   Topic `play-billing`; grant
 *   google-play-developer-notifications@system.gserviceaccount.com
 *   "Pub/Sub Publisher"; set the topic in Play Console → Monetization setup.
 *   Messages carry no state — always re-read from the Play API.
 *
 * Both are idempotent and converge on the store's current state.
 */
import {onRequest} from 'firebase-functions/v2/https';
import {onMessagePublished} from 'firebase-functions/v2/pubsub';
import {logger} from 'firebase-functions/v2';
import {FieldValue, getFirestore} from 'firebase-admin/firestore';

import {
  ANDROID_PACKAGE_NAME, GOOGLE_PLAY_SERVICE_ACCOUNT, NON_CONSUMABLE_PREFIX, SUBSCRIPTION_PLANS, TIER_PREFIX,
  applySubscription, revokePurchase, subscriptionBindingId, uidForSubscription,
} from './iap';
import {APPLE_SECRETS, decodeAppleSubscription, decodeAppleTransaction, getAppleSubscription, verifyAppleNotification} from './store/apple';
import {fetchGoogleSubscription} from './store/google';

const REFUND_TYPES = new Set(['REFUND', 'REVOKE']);

export const appStoreNotifications = onRequest({secrets: APPLE_SECRETS}, async (req, res) => {
  if (req.method !== 'POST') { res.status(405).send('Method not allowed'); return; }
  const signedPayload = (req.body as {signedPayload?: unknown})?.signedPayload;
  if (typeof signedPayload !== 'string') { res.status(400).send('Missing signedPayload'); return; }

  let note;
  try {
    note = await verifyAppleNotification(signedPayload);
  } catch {
    res.status(400).send('Invalid signature');
    return;
  }
  const {env, payload} = note;
  const type = String(payload.notificationType ?? '');
  const signedTx = payload.data?.signedTransactionInfo;
  logger.info(`appStoreNotifications: ${type}/${payload.subtype ?? ''} env=${env}`);

  try {
    if (signedTx) {
      const tx = await decodeAppleTransaction(env, signedTx);
      const productId = tx.productId ?? '';
      if (productId.startsWith(TIER_PREFIX)) {
        if (REFUND_TYPES.has(type) && tx.transactionId) await revokePurchase('ios', tx.transactionId, type.toLowerCase());
      } else if (productId.startsWith(NON_CONSUMABLE_PREFIX)) {
        const key = tx.originalTransactionId ?? tx.transactionId;
        if (REFUND_TYPES.has(type) && key) await revokePurchase('ios', key, type.toLowerCase());
      } else if (SUBSCRIPTION_PLANS[productId] && tx.originalTransactionId) {
        const uid = await uidForSubscription('ios', tx.originalTransactionId);
        if (uid) {
          // Re-read latest status; notifications can arrive out of order.
          const latest = await getAppleSubscription(tx.originalTransactionId, productId).catch(() => null) ??
            await decodeAppleSubscription(env, signedTx, payload.data?.signedRenewalInfo);
          if (latest) {
            if (REFUND_TYPES.has(type)) latest.revoked = true;
            await applySubscription(uid, 'ios', latest);
          }
        }
        // Unbound: verifySubscription will bind it when the app reports it.
      }
    }
  } catch (e) {
    logger.error('appStoreNotifications: failed', e);
    res.status(500).send('Retry'); // Apple retries 5xx with backoff
    return;
  }
  res.status(200).send('OK');
});

interface RtdnMessage {
  packageName?: string;
  testNotification?: unknown;
  subscriptionNotification?: {notificationType?: number; purchaseToken?: string};
  voidedPurchaseNotification?: {purchaseToken?: string; productType?: number};
}
const SUB_REVOKED = 12;

async function applyGoogleSubscription(token: string, revoked: boolean): Promise<void> {
  const sub = await fetchGoogleSubscription(token, ANDROID_PACKAGE_NAME.value(), GOOGLE_PLAY_SERVICE_ACCOUNT.value());
  if (!sub) return;
  let uid = await uidForSubscription('android', token);
  if (!uid && sub.linkedPurchaseToken) {
    // Upgrade / resubscribe: new token, same user → carry the binding.
    uid = await uidForSubscription('android', sub.linkedPurchaseToken);
    if (uid) {
      await getFirestore().collection('_iap_subscriptions').doc(subscriptionBindingId('android', token))
        .set({uid, platform: 'android', productId: sub.productId, createdAt: FieldValue.serverTimestamp()});
    }
  }
  if (!uid) return;
  if (revoked) sub.revoked = true;
  await applySubscription(uid, 'android', sub);
}

export const playRtdn = onMessagePublished({topic: 'play-billing', secrets: [GOOGLE_PLAY_SERVICE_ACCOUNT]}, async (event) => {
  let msg: RtdnMessage;
  try { msg = event.data.message.json as RtdnMessage; } catch { return; }
  if (msg.testNotification) return;
  if (msg.packageName && msg.packageName !== ANDROID_PACKAGE_NAME.value()) return; // other flavor
  const sn = msg.subscriptionNotification;
  if (sn?.purchaseToken) { await applyGoogleSubscription(sn.purchaseToken, sn.notificationType === SUB_REVOKED); return; }
  const vn = msg.voidedPurchaseNotification;
  if (vn?.purchaseToken) {
    if (vn.productType === 2) await revokePurchase('android', vn.purchaseToken, 'voided');
    else if (vn.productType === 1) await applyGoogleSubscription(vn.purchaseToken, true);
  }
});
