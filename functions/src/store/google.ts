/**
 * Google Play Developer API helpers (service-account auth, no extra deps).
 */

import {createSign} from 'crypto';
import {logger} from 'firebase-functions/v2';

export interface VerifiedProduct {
  /** Store-unique id of THIS purchase (the Play purchase token). */
  txnKey: string;
  orderId: string | null;
  purchasedAtMs: number;
}

export interface VerifiedSubscription {
  /** Identifies the subscription chain (Play: purchase token). */
  originalTransactionId: string;
  /** Previous token when the user upgraded / resubscribed. */
  linkedPurchaseToken?: string;
  productId: string;
  startedAtMs: number;
  expiresAtMs: number;
  autoRenew: boolean;
  /** Refunded / revoked — entitlement must end now. */
  revoked: boolean;
}

function playBase(packageName: string): string {
  return 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/' +
    encodeURIComponent(packageName);
}

let cachedToken: {value: string; expiresAt: number} | null = null;

async function accessToken(serviceAccountJson: string): Promise<string> {
  if (cachedToken && cachedToken.expiresAt > Date.now() + 60_000) return cachedToken.value;
  const sa = JSON.parse(serviceAccountJson) as {client_email: string; private_key: string};
  const now = Math.floor(Date.now() / 1000);
  const enc = (o: object) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const unsigned = `${enc({alg: 'RS256', typ: 'JWT'})}.${enc({
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/androidpublisher',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  })}`;
  const signer = createSign('RSA-SHA256');
  signer.update(unsigned);
  const jwt = `${unsigned}.${signer.sign(sa.private_key).toString('base64url')}`;
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const json = (await res.json()) as {access_token?: string; expires_in?: number};
  if (!json.access_token) throw new Error('Google token exchange failed.');
  cachedToken = {value: json.access_token, expiresAt: Date.now() + (json.expires_in ?? 3600) * 1000};
  return json.access_token;
}

/** purchases.products.get — one-time (consumable) purchase. */
export async function verifyGoogleProduct(
  purchaseToken: string,
  productId: string,
  packageName: string,
  serviceAccountJson: string,
): Promise<VerifiedProduct | null> {
  const token = await accessToken(serviceAccountJson);
  const url = `${playBase(packageName)}/purchases/products/${encodeURIComponent(productId)}` +
    `/tokens/${encodeURIComponent(purchaseToken)}`;
  const res = await fetch(url, {headers: {Authorization: `Bearer ${token}`}});
  if (!res.ok) {
    logger.warn(`verifyGoogleProduct: http=${res.status}`);
    return null;
  }
  const json = (await res.json()) as {
    purchaseState?: number; // 0 purchased, 1 canceled, 2 pending
    purchaseTimeMillis?: string;
    orderId?: string;
  };
  if (json.purchaseState !== 0) return null;
  return {
    txnKey: purchaseToken,
    orderId: json.orderId ?? null,
    purchasedAtMs: Number(json.purchaseTimeMillis ?? Date.now()),
  };
}

/** purchases.products.consume — after the grant, so the tier can be rebought. */
export async function consumeGoogleProduct(
  purchaseToken: string,
  productId: string,
  packageName: string,
  serviceAccountJson: string,
): Promise<boolean> {
  const token = await accessToken(serviceAccountJson);
  const url = `${playBase(packageName)}/purchases/products/${encodeURIComponent(productId)}` +
    `/tokens/${encodeURIComponent(purchaseToken)}:consume`;
  const res = await fetch(url, {method: 'POST', headers: {Authorization: `Bearer ${token}`}});
  // 400 "already consumed" on replay is fine.
  return res.ok || res.status === 400;
}

/** purchases.subscriptionsv2.get — authoritative subscription state. */
export async function fetchGoogleSubscription(
  purchaseToken: string,
  packageName: string,
  serviceAccountJson: string,
): Promise<VerifiedSubscription | null> {
  const token = await accessToken(serviceAccountJson);
  const url = `${playBase(packageName)}/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`;
  const res = await fetch(url, {headers: {Authorization: `Bearer ${token}`}});
  if (!res.ok) {
    logger.warn(`fetchGoogleSubscription: http=${res.status}`);
    return null;
  }
  const json = (await res.json()) as {
    subscriptionState?: string;
    startTime?: string;
    linkedPurchaseToken?: string;
    lineItems?: Array<{
      productId?: string;
      expiryTime?: string;
      autoRenewingPlan?: {autoRenewEnabled?: boolean};
    }>;
  };
  const line = (json.lineItems ?? [])
    .filter((l) => l.productId && l.expiryTime)
    .sort((a, b) => Date.parse(b.expiryTime!) - Date.parse(a.expiryTime!))[0];
  if (!line) return null;
  const state = json.subscriptionState ?? '';
  return {
    originalTransactionId: purchaseToken,
    linkedPurchaseToken: json.linkedPurchaseToken,
    productId: line.productId!,
    startedAtMs: Date.parse(json.startTime ?? '') || Date.now(),
    expiresAtMs: Date.parse(line.expiryTime!),
    autoRenew: line.autoRenewingPlan?.autoRenewEnabled ?? false,
    // EXPIRED / ON_HOLD / PAUSED just mean "not entitled after expiry";
    // only a revocation ends access early (handled via voided purchases).
    revoked: state === 'SUBSCRIPTION_STATE_PENDING',
  };
}
