import {getAuth} from 'firebase-admin/auth';
import {getFirestore, FieldValue} from 'firebase-admin/firestore';
import {getStorage} from 'firebase-admin/storage';
import {HttpsError, onCall} from 'firebase-functions/v2/https';
import {logger} from 'firebase-functions/v2';

import {requireAppCheck} from './app_check';

/**
 * Store-mandated in-app account deletion. Client re-authenticates first
 * (recent-login), calls this, then signs out + runs session cleanup.
 * Ledger rows are retained for accounting but anonymized.
 */
export const deleteAccount = onCall({timeoutSeconds: 300}, async (request) => {
  requireAppCheck(request, 'deleteAccount');
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign-in required.');
  const db = getFirestore();

  // 1. UGC authored by the user (adapt collection groups to your app).
  for (const group of ['reviews', 'comments']) {
    const snap = await db.collectionGroup(group).where('authorId', '==', uid).get();
    const w = db.bulkWriter();
    snap.docs.forEach((d) => w.delete(d.ref));
    await w.close();
  }

  // 2. Anonymize financial records (keep for tax/accounting).
  const tx = await db.collection('transactions').where('userId', '==', uid).get();
  const w = db.bulkWriter();
  tx.docs.forEach((d) => w.update(d.ref, {
    userName: 'Deleted user', userEmail: FieldValue.delete(), anonymizedAt: FieldValue.serverTimestamp(),
  }));
  await w.close();

  // 3. User doc and EVERY subcollection (purchases, notifications, …).
  await db.recursiveDelete(db.doc(`users/${uid}`));

  // 4. Storage under users/{uid}/.
  await getStorage().bucket().deleteFiles({prefix: `users/${uid}/`}).catch((e) =>
    logger.warn(`deleteAccount: storage cleanup failed for ${uid}`, e));

  // 5. Auth record last — after this the caller's token is useless.
  await getAuth().deleteUser(uid);
  logger.info(`deleteAccount: ${uid}`);
  return {ok: true};
});
