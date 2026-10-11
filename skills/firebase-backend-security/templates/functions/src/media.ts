/**
 * Paid media served through short-lived V4 signed URLs.
 *
 *   resolveMedia          — entitlement check → signed URL (4 h)
 *   stripDownloadTokens   — removes firebaseStorageDownloadTokens on upload
 *
 * IAM: the Functions runtime service account needs
 * "Service Account Token Creator" on itself for getSignedUrl().
 */
import {getFirestore} from 'firebase-admin/firestore';
import {getStorage} from 'firebase-admin/storage';
import {HttpsError, onCall} from 'firebase-functions/v2/https';
import {onObjectFinalized} from 'firebase-functions/v2/storage';
import {logger} from 'firebase-functions/v2';

import {hasAccess} from './access';
import {requireAppCheck} from './app_check';

const SIGNED_URL_TTL_MS = 4 * 60 * 60 * 1000;
/** items/{itemId}/private/... */
const PRIVATE_OBJECT_RE = /^items\/([^/]+)\/private\/.+$/;

export function parseGsUri(raw: unknown): {bucket: string; path: string} | null {
  if (typeof raw !== 'string' || !raw.startsWith('gs://')) return null;
  const rest = raw.slice(5);
  const i = rest.indexOf('/');
  return i > 0 ? {bucket: rest.slice(0, i), path: rest.slice(i + 1)} : null;
}

export const resolveMedia = onCall(async (request) => {
  requireAppCheck(request, 'resolveMedia');
  const itemId = String(request.data?.itemId ?? '').trim();
  const partId = String(request.data?.partId ?? '').trim();
  if (!itemId || !partId) throw new HttpsError('invalid-argument', 'itemId and partId are required.');

  const part = (await getFirestore().doc(`items/${itemId}/parts/${partId}`).get()).data();
  if (!part) throw new HttpsError('not-found', 'Not found.');

  if (part.isPreview !== true) {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to continue.');
    if (!(await hasAccess(uid, itemId))) throw new HttpsError('permission-denied', 'Purchase required.');
  }

  const ref = parseGsUri(part.mediaRef);
  const m = ref?.path.match(PRIVATE_OBJECT_RE);
  // Only sign objects that belong to THIS item — a doc edited to point at
  // another item's file must not leak it.
  if (!ref || !m || m[1] !== itemId) {
    logger.warn(`resolveMedia: bad ref for ${itemId}/${partId}`);
    throw new HttpsError('failed-precondition', 'Unsupported media reference.');
  }

  const expires = Date.now() + SIGNED_URL_TTL_MS;
  const [url] = await getStorage().bucket(ref.bucket).file(ref.path)
    .getSignedUrl({version: 'v4', action: 'read', expires});
  return {url, expiresAtMs: expires};
});

/**
 * SDK uploads get a download token, which makes the object readable by
 * anyone holding the URL — bypassing storage.rules. Remove it.
 */
export const stripDownloadTokens = onObjectFinalized(async (event) => {
  const path = event.data.name;
  if (!path || !PRIVATE_OBJECT_RE.test(path)) return;
  if (!event.data.metadata?.firebaseStorageDownloadTokens) return;
  await getStorage().bucket(event.data.bucket).file(path)
    .setMetadata({metadata: {firebaseStorageDownloadTokens: null}});
  logger.info(`stripDownloadTokens: ${path}`);
});
