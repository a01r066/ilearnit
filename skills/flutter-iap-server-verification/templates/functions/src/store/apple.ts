/**
 * App Store Server API + JWS verification (replaces the deprecated
 * /verifyReceipt endpoint).
 *
 * Uses Apple's official `@apple/app-store-server-library`:
 *   • AppStoreServerAPIClient — authenticated lookups by transaction id
 *   • SignedDataVerifier      — verifies JWS x5c chains up to Apple's root
 *     CAs (bundled in functions/certs/) for API responses AND for App Store
 *     Server Notifications v2, which arrive unauthenticated.
 *
 * Configuration
 *   Secrets  APPLE_IAP_KEY_ID, APPLE_IAP_ISSUER_ID, APPLE_IAP_PRIVATE_KEY
 *            (App Store Connect → Users and Access → Integrations →
 *            In-App Purchase key; paste the .p8 contents)
 *   Params   APPLE_BUNDLE_ID (com.example.app / com.example.app.dev),
 *            APPLE_APP_ID    (numeric Apple ID of the app; required to
 *            verify Production-signed data)
 *   Certs    functions/certs/*.cer — Apple Root CA G2 + G3 from
 *            https://www.apple.com/certificateauthority/
 */

import {readdirSync, readFileSync} from 'fs';
import {join} from 'path';
import {
  APIException,
  AppStoreServerAPIClient,
  Environment,
  JWSRenewalInfoDecodedPayload,
  JWSTransactionDecodedPayload,
  ReceiptUtility,
  ResponseBodyV2DecodedPayload,
  SignedDataVerifier,
} from '@apple/app-store-server-library';
import {defineSecret, defineString} from 'firebase-functions/params';
import {logger} from 'firebase-functions/v2';

export const APPLE_IAP_KEY_ID = defineSecret('APPLE_IAP_KEY_ID');
export const APPLE_IAP_ISSUER_ID = defineSecret('APPLE_IAP_ISSUER_ID');
export const APPLE_IAP_PRIVATE_KEY = defineSecret('APPLE_IAP_PRIVATE_KEY');
export const APPLE_BUNDLE_ID = defineString('APPLE_BUNDLE_ID');
export const APPLE_APP_ID = defineString('APPLE_APP_ID', {default: ''});

/** Secrets every Apple-touching function must declare. */
export const APPLE_SECRETS = [APPLE_IAP_KEY_ID, APPLE_IAP_ISSUER_ID, APPLE_IAP_PRIVATE_KEY];

/**
 * Production first, Sandbox second (TestFlight / sandbox testers). The
 * Production verifier needs the numeric app id, so a project without
 * APPLE_APP_ID (e.g. the dev project) only talks to Sandbox.
 */
function environments(): Environment[] {
  return Number(APPLE_APP_ID.value())
    ? [Environment.PRODUCTION, Environment.SANDBOX]
    : [Environment.SANDBOX];
}

let rootCerts: Buffer[] | null = null;
function appleRootCerts(): Buffer[] {
  if (!rootCerts) {
    // Compiled to functions/lib → certs live at functions/certs.
    const dir = join(__dirname, '..', '..', 'certs');
    rootCerts = readdirSync(dir)
      .filter((f) => f.endsWith('.cer') || f.endsWith('.der'))
      .map((f) => readFileSync(join(dir, f)));
    if (rootCerts.length === 0) throw new Error(`No Apple root certificates in ${dir}`);
  }
  return rootCerts;
}

const verifiers = new Map<Environment, SignedDataVerifier>();
function verifier(env: Environment): SignedDataVerifier {
  let v = verifiers.get(env);
  if (!v) {
    const appId = Number(APPLE_APP_ID.value()) || undefined;
    v = new SignedDataVerifier(appleRootCerts(), true, env, APPLE_BUNDLE_ID.value(), appId);
    verifiers.set(env, v);
  }
  return v;
}

const clients = new Map<Environment, AppStoreServerAPIClient>();
function client(env: Environment): AppStoreServerAPIClient {
  let c = clients.get(env);
  if (!c) {
    c = new AppStoreServerAPIClient(
      APPLE_IAP_PRIVATE_KEY.value(),
      APPLE_IAP_KEY_ID.value().trim(),
      APPLE_IAP_ISSUER_ID.value().trim(),
      APPLE_BUNDLE_ID.value(),
      env,
    );
    clients.set(env, c);
  }
  return c;
}

function isNotFound(e: unknown): boolean {
  return e instanceof APIException && e.httpStatusCode === 404;
}

/** Runs [fn] against Production, falling back to Sandbox on 404. */
async function withEnvFallback<T>(fn: (env: Environment) => Promise<T>): Promise<T> {
  let last: unknown;
  for (const env of environments()) {
    try {
      return await fn(env);
    } catch (e) {
      last = e;
      if (!isNotFound(e)) throw e;
    }
  }
  throw last;
}

/** Transaction id from a StoreKit 1 app receipt (fallback when missing). */
export function transactionIdFromReceipt(receipt: string | undefined): string | null {
  if (!receipt) return null;
  try {
    return new ReceiptUtility().extractTransactionIdFromAppReceipt(receipt);
  } catch {
    return null;
  }
}

export interface AppleTransaction {
  env: Environment;
  tx: JWSTransactionDecodedPayload;
}

/** Get Transaction Info → verified, decoded transaction. */
export async function getAppleTransaction(transactionId: string): Promise<AppleTransaction | null> {
  try {
    return await withEnvFallback(async (env) => {
      const res = await client(env).getTransactionInfo(transactionId);
      if (!res.signedTransactionInfo) throw new Error('empty signedTransactionInfo');
      const tx = await verifier(env).verifyAndDecodeTransaction(res.signedTransactionInfo);
      return {env, tx};
    });
  } catch (e) {
    if (isNotFound(e)) return null;
    throw e;
  }
}

/** Verifies + decodes a signedTransactionInfo JWS. */
export function decodeAppleTransaction(
  env: Environment,
  signedTransactionInfo: string,
): Promise<JWSTransactionDecodedPayload> {
  return verifier(env).verifyAndDecodeTransaction(signedTransactionInfo);
}

export interface AppleSubscriptionState {
  originalTransactionId: string;
  productId: string;
  startedAtMs: number;
  expiresAtMs: number;
  autoRenew: boolean;
  revoked: boolean;
}

/** Decodes a transaction + renewal info pair into our subscription shape. */
export async function decodeAppleSubscription(
  env: Environment,
  signedTransactionInfo: string,
  signedRenewalInfo?: string,
): Promise<AppleSubscriptionState | null> {
  const tx = await verifier(env).verifyAndDecodeTransaction(signedTransactionInfo);
  if (!tx.originalTransactionId || !tx.productId || !tx.expiresDate) return null;
  let renewal: JWSRenewalInfoDecodedPayload | null = null;
  if (signedRenewalInfo) {
    renewal = await verifier(env).verifyAndDecodeRenewalInfo(signedRenewalInfo);
  }
  return {
    originalTransactionId: tx.originalTransactionId,
    productId: tx.productId,
    startedAtMs: tx.originalPurchaseDate ?? tx.purchaseDate ?? Date.now(),
    expiresAtMs: tx.expiresDate,
    // AutoRenewStatus: 1 = on, 0 = off.
    autoRenew: renewal ? Number(renewal.autoRenewStatus) === 1 : true,
    revoked: tx.revocationDate != null,
  };
}

/**
 * Get All Subscription Statuses for any transaction id in the chain and
 * return the latest state for [productId] (or any product when omitted).
 */
export async function getAppleSubscription(
  transactionId: string,
  productId?: string,
): Promise<AppleSubscriptionState | null> {
  try {
    return await withEnvFallback(async (env) => {
      const res = await client(env).getAllSubscriptionStatuses(transactionId);
      let best: AppleSubscriptionState | null = null;
      for (const group of res.data ?? []) {
        for (const item of group.lastTransactions ?? []) {
          if (!item.signedTransactionInfo) continue;
          const s = await decodeAppleSubscription(env, item.signedTransactionInfo, item.signedRenewalInfo);
          if (!s || (productId && s.productId !== productId)) continue;
          if (!best || s.expiresAtMs > best.expiresAtMs) best = s;
        }
      }
      return best;
    });
  } catch (e) {
    if (isNotFound(e)) return null;
    throw e;
  }
}

export interface AppleNotification {
  env: Environment;
  payload: ResponseBodyV2DecodedPayload;
}

/** Verifies an App Store Server Notification v2 `signedPayload`. */
export async function verifyAppleNotification(signedPayload: string): Promise<AppleNotification> {
  let last: unknown;
  for (const env of environments()) {
    try {
      const payload = await verifier(env).verifyAndDecodeNotification(signedPayload);
      return {env, payload};
    } catch (e) {
      last = e; // wrong environment or invalid signature — try the next one
    }
  }
  logger.warn('verifyAppleNotification: signature / environment check failed');
  throw last;
}

export {Environment};
