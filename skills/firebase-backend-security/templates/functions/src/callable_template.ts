import {getFirestore, FieldValue} from 'firebase-admin/firestore';
import {HttpsError, onCall} from 'firebase-functions/v2/https';
import {logger} from 'firebase-functions/v2';

import {requireRole} from './access';
import {requireAppCheck} from './app_check';

/**
 * Privileged admin action. Order matters: App Check → auth → validate →
 * authorize → mutate (transaction) → user-safe result.
 */
export const setUserSuspended = onCall(async (request) => {
  requireAppCheck(request, 'setUserSuspended');
  const caller = await requireRole(request.auth?.uid, ['admin']);

  const targetUid = String(request.data?.uid ?? '').trim();
  const suspended = request.data?.suspended;
  if (!targetUid || typeof suspended !== 'boolean') {
    throw new HttpsError('invalid-argument', 'uid and suspended are required.');
  }
  if (targetUid === caller) throw new HttpsError('failed-precondition', 'You cannot suspend yourself.');

  const db = getFirestore();
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`users/${targetUid}`);
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'User not found.');
    tx.update(ref, {isSuspended: suspended, suspendedAt: suspended ? FieldValue.serverTimestamp() : null});
    tx.create(db.collection('audit_log').doc(), {
      action: 'setUserSuspended', actor: caller, target: targetUid, suspended,
      at: FieldValue.serverTimestamp(),
    });
  });
  logger.info(`setUserSuspended: ${caller} → ${targetUid}=${suspended}`);
  return {ok: true};
});
