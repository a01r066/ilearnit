/**
 * Single server-side answers to "who is this" and "may they use this".
 * Every paid-content endpoint calls hasAccess(); never duplicate the logic.
 */
import {getFirestore, Timestamp} from 'firebase-admin/firestore';
import {HttpsError} from 'firebase-functions/v2/https';

const db = () => getFirestore();

export type Role = 'user' | 'moderator' | 'admin';

export async function getRole(uid: string): Promise<{role: Role; suspended: boolean}> {
  const d = (await db().doc(`users/${uid}`).get()).data() ?? {};
  return {role: (d.role as Role) ?? 'user', suspended: d.isSuspended === true};
}

/** Throws unless the caller is a non-suspended user with one of [roles]. */
export async function requireRole(uid: string | undefined, roles: Role[]): Promise<string> {
  if (!uid) throw new HttpsError('unauthenticated', 'Sign-in required.');
  const {role, suspended} = await getRole(uid);
  if (suspended || !roles.includes(role)) {
    throw new HttpsError('permission-denied', 'Not allowed.');
  }
  return uid;
}

/**
 * Owner (purchase), active subscriber, item owner, or admin.
 * Suspended accounts never have access.
 */
export async function hasAccess(uid: string, itemId: string): Promise<boolean> {
  const [userSnap, purchaseSnap, itemSnap] = await Promise.all([
    db().doc(`users/${uid}`).get(),
    db().doc(`users/${uid}/purchases/${itemId}`).get(),
    db().doc(`items/${itemId}`).get(),
  ]);
  const user = userSnap.data() ?? {};
  if (user.isSuspended === true) return false;
  if (user.role === 'admin') return true;
  if (itemSnap.data()?.ownerId === uid) return true;
  if (purchaseSnap.data()?.status === 'purchased') return true;
  const exp = (user.subscription as {expiresAt?: Timestamp} | undefined)?.expiresAt;
  return !!exp && exp.toMillis() > Date.now();
}
