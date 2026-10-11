/**
 * Store server-to-server notifications — keep entitlements correct when the
 * app isn't open: renewals, expirations, cancellations, refunds, revokes.
 *
 *   appStoreNotifications — HTTPS endpoint for App Store Server
 *       Notifications v2. Configure in App Store Connect → App →
 *       App Information → App Store Server Notifications (Production +
 *       Sandbox URL = this function's URL, Version 2).
 *       The body is UNAUTHENTICATED; every payload is JWS-verified to
 *       Apple's root CA before anything is trusted.
 *
 *   playRtdn — Pub/Sub trigger for Google Play Real-time Developer
 *       Notifications. Create topic `play-billing`, grant
 *       google-play-developer-notifications@system.gserviceaccount.com
 *       "Pub/Sub Publisher" on it, and set it in Play Console →
 *       Monetization setup → Real-time developer notifications.
 *       State is always re-read from the Play Developer API.
 *
 * Both handlers are idempotent and always converge on the store's
 * current state, so retries / out-of-order delivery are safe.
 */

import {onRequest} from 'firebase-functions/v2/https';
import {onMessagePublished} from 'firebase-functions/v2/pubsub';
import {logger} from 'firebase-functions/v2';
import {getFirestore, FieldValue} from 'firebase-admin/firestore';

import {
  ANDROID_PACKAGE_NAME,
  GOOGLE_PLAY_SERVICE_ACCOUNT,
  SONGBOOK_PRODUCT_PREFIX,
  SUBSCRIPTION_PLANS,
  applySubscription,
  revokeCoursePurchase,
  subscriptionBindingId,
  uidForSubscription,
} from './iap';
import {
  APPLE_SECRETS,
  decodeAppleSubscription,
  decodeAppleTransaction,
  getAppleSubscription,
  verifyAppleNotification,
} from './store/apple';
import {fetchGoogleSubscription} from './store/google';

const REFUND_TYPES = new Set(['REFUND', 'REVOKE']);

// ---------------------------------------------------------------------------
// Apple — App Store Server Notifications v2
// ---------------------------------------------------------------------------

export const appStoreNotifications = onRequest(
  {secrets: APPLE_SECRETS},
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed');
      return;
    }
    const signedPayload = (req.body as {signedPayload?: unknown})?.signedPayload;
    if (typeof signedPayload !== 'string') {
      res.status(400).send('Missing signedPayload');
      return;
    }

    let note;
    try {
      note = await verifyAppleNotification(signedPayload);
    } catch {
      // Not from Apple (or wrong environment / bundle). Don't process.
      res.status(400).send('Invalid signature');
      return;
    }

    const {env, payload} = note;
    const type = String(payload.notificationType ?? '');
    const subtype = payload.subtype ? String(payload.subtype) : '';
    const signedTx = payload.data?.signedTransactionInfo;
    logger.info(`appStoreNotifications: ${type}/${subtype} env=${env}`);

    try {
      if (signedTx) {
        const tx = await decodeAppleTransaction(env, signedTx);
        const productId = tx.productId ?? '';

        if (productId.startsWith('info.ilearnit.course_tier_')) {
          // Consumable course purchase — only refunds / revokes matter.
          if (REFUND_TYPES.has(type) && tx.transactionId) {
            await revokeCoursePurchase('ios', tx.transactionId, type.toLowerCase());
          }
        } else if (productId.startsWith(SONGBOOK_PRODUCT_PREFIX)) {
          // Non-consumable songbook — keyed by originalTransactionId.
          const key = tx.originalTransactionId ?? tx.transactionId;
          if (REFUND_TYPES.has(type) && key) {
            await revokeCoursePurchase('ios', key, type.toLowerCase());
          }
        } else if (SUBSCRIPTION_PLANS[productId] && tx.originalTransactionId) {
          const uid = await uidForSubscription('ios', tx.originalTransactionId);
          if (!uid) {
            // Never verified through the app yet; verifySubscription will
            // bind + apply it when the client reports the purchase.
            logger.info(`appStoreNotifications: unbound subscription ${tx.originalTransactionId}`);
          } else {
            // Re-read the latest status rather than trusting this single
            // (possibly out-of-order) notification.
            const latest = await getAppleSubscription(tx.originalTransactionId, productId)
              .catch(() => null) ??
              await decodeAppleSubscription(env, signedTx, payload.data?.signedRenewalInfo);
            if (latest) {
              if (REFUND_TYPES.has(type)) latest.revoked = true;
              await applySubscription(uid, 'ios', latest);
            }
          }
        }
      }
    } catch (e) {
      // 5xx → Apple retries with backoff.
      logger.error('appStoreNotifications: processing failed', e);
      res.status(500).send('Retry');
      return;
    }

    res.status(200).send('OK');
  },
);

// ---------------------------------------------------------------------------
// Google — Real-time Developer Notifications (Pub/Sub)
// ---------------------------------------------------------------------------

interface RtdnMessage {
  packageName?: string;
  testNotification?: unknown;
  subscriptionNotification?: {
    notificationType?: number;
    purchaseToken?: string;
    subscriptionId?: string;
  };
  voidedPurchaseNotification?: {
    purchaseToken?: string;
    orderId?: string;
    productType?: number; // 1 = subscription, 2 = one-time
    refundType?: number;
  };
}

/** SubscriptionNotification.notificationType values that end access now. */
const SUB_REVOKED = 12; // SUBSCRIPTION_REVOKED

async function applyGoogleSubscription(token: string, revoked: boolean): Promise<void> {
  const sub = await fetchGoogleSubscription(
    token, ANDROID_PACKAGE_NAME.value(), GOOGLE_PLAY_SERVICE_ACCOUNT.value(),
  );
  if (!sub) return;
  let uid = await uidForSubscription('android', token);
  if (!uid && sub.linkedPurchaseToken) {
    // Upgrade / resubscribe: new token, same user — carry the binding over.
    uid = await uidForSubscription('android', sub.linkedPurchaseToken);
    if (uid) {
      await getFirestore().collection('_iap_subscriptions')
        .doc(subscriptionBindingId('android', token))
        .set({uid, platform: 'android', productId: sub.productId, createdAt: FieldValue.serverTimestamp()});
    }
  }
  if (!uid) {
    logger.info('playRtdn: unbound subscription token (will bind on verifySubscription)');
    return;
  }
  if (revoked) sub.revoked = true;
  await applySubscription(uid, 'android', sub);
}

export const playRtdn = onMessagePublished(
  {topic: 'play-billing', secrets: [GOOGLE_PLAY_SERVICE_ACCOUNT]},
  async (event) => {
    let msg: RtdnMessage;
    try {
      msg = event.data.message.json as RtdnMessage;
    } catch {
      logger.warn('playRtdn: non-JSON message ignored');
      return;
    }
    if (msg.testNotification) {
      logger.info('playRtdn: test notification');
      return;
    }
    if (msg.packageName && msg.packageName !== ANDROID_PACKAGE_NAME.value()) {
      // Another app/flavor publishing to the same topic.
      return;
    }

    const sn = msg.subscriptionNotification;
    if (sn?.purchaseToken) {
      await applyGoogleSubscription(sn.purchaseToken, sn.notificationType === SUB_REVOKED);
      return;
    }

    const vn = msg.voidedPurchaseNotification;
    if (vn?.purchaseToken) {
      if (vn.productType === 2) {
        // One-time product: course tier or songbook (both keyed by token).
        await revokeCoursePurchase('android', vn.purchaseToken, 'voided');
      } else if (vn.productType === 1) {
        await applyGoogleSubscription(vn.purchaseToken, true);
      }
    }
  },
);
