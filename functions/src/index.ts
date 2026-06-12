/**
 * iLearnIt — push-notification Cloud Functions.
 *
 * Three exported triggers:
 *
 *   1. onApplicationDecision    — fires when an admin approves/rejects an
 *                                  instructor application; DMs the user.
 *   2. onEnrollmentCreated      — fires when a course is purchased;
 *                                  DMs the buyer.
 *   3. onNotificationBroadcast  — fires when the admin portal writes a
 *                                  `notification_broadcasts/{id}` doc;
 *                                  fans out to the requested FCM topic.
 *
 * Deploy:
 *     cd functions
 *     npm install
 *     npm run deploy
 */

import {initializeApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore, FieldValue} from 'firebase-admin/firestore';
import {getMessaging, MulticastMessage, TopicMessage} from 'firebase-admin/messaging';
import {getStorage} from 'firebase-admin/storage';
import {onDocumentCreated, onDocumentUpdated} from 'firebase-functions/v2/firestore';
import {HttpsError, onCall} from 'firebase-functions/v2/https';
import {logger} from 'firebase-functions/v2';
import {defineSecret} from 'firebase-functions/params';

// ---------- Cloudflare Stream secrets -------------------------------------
//
// The API token must NEVER be embedded in the Flutter client. Define it
// as a Firebase Secret and reference it from `resolveStreamPlayback`.
//
// Set the secrets via the CLI before deploying:
//   firebase functions:secrets:set CLOUDFLARE_API_TOKEN
//   firebase functions:secrets:set CLOUDFLARE_ACCOUNT_ID
//
const CLOUDFLARE_API_TOKEN = defineSecret('CLOUDFLARE_API_TOKEN');
const CLOUDFLARE_ACCOUNT_ID = defineSecret('CLOUDFLARE_ACCOUNT_ID');

initializeApp();
const db = getFirestore();
const fcm = getMessaging();
const auth = getAuth();
const storage = getStorage();

// ---------- payload helpers ------------------------------------------------

type DataPayload = Record<string, string>;

/**
 * Strip undefined/null values — FCM rejects non-string data field values.
 */
function dataOnly(input: Record<string, string | null | undefined>): DataPayload {
  const out: DataPayload = {};
  for (const [k, v] of Object.entries(input)) {
    if (v !== null && v !== undefined && v !== '') out[k] = String(v);
  }
  return out;
}

/**
 * Send a notification to a list of FCM tokens belonging to a single user.
 * Silently drops bad tokens and removes them from the user doc.
 */
async function sendToUser(
  userId: string,
  notification: {title: string; body: string},
  data: DataPayload,
): Promise<void> {
  const snap = await db.collection('users').doc(userId).get();
  if (!snap.exists) {
    logger.info(`sendToUser: user ${userId} not found`);
    return;
  }
  const tokens: string[] = snap.get('fcmTokens') ?? [];
  if (tokens.length === 0) {
    logger.info(`sendToUser: ${userId} has no fcmTokens`);
    return;
  }

  const msg: MulticastMessage = {
    tokens,
    notification,
    data,
    android: {priority: 'high'},
    apns: {payload: {aps: {sound: 'default'}}},
  };
  const res = await fcm.sendEachForMulticast(msg);
  logger.info(
    `sendToUser: ${userId} → ${res.successCount}/${tokens.length} delivered`,
  );

  // Clean up invalid tokens (uninstalled apps, expired registrations).
  const dead: string[] = [];
  res.responses.forEach((r, i) => {
    if (
      !r.success &&
      (r.error?.code === 'messaging/invalid-registration-token' ||
        r.error?.code === 'messaging/registration-token-not-registered')
    ) {
      dead.push(tokens[i]);
    }
  });
  if (dead.length > 0) {
    await db
      .collection('users')
      .doc(userId)
      .update({fcmTokens: FieldValue.arrayRemove(...dead)});
  }
}

async function sendToTopic(
  topic: string,
  notification: {title: string; body: string},
  data: DataPayload,
): Promise<string> {
  const msg: TopicMessage = {
    topic,
    notification,
    data,
    android: {priority: 'high'},
    apns: {payload: {aps: {sound: 'default'}}},
  };
  return fcm.send(msg);
}

/**
 * Mirror a 1:1 push into `users/{uid}/notifications/{id}` so the in-app
 * inbox shows the event regardless of OS notification permission. The
 * client subscribes via `notificationsInboxProvider`.
 *
 * Shape matches `NotificationItemModel`:
 *   { type, title, body, payload: {...data}, readAt: null, createdAt }
 */
async function writeInbox(
  userId: string,
  notification: {title: string; body: string},
  data: DataPayload,
): Promise<void> {
  try {
    await db
      .collection('users')
      .doc(userId)
      .collection('notifications')
      .add({
        type: data.type ?? 'unknown',
        title: notification.title,
        body: notification.body,
        payload: data,
        readAt: null,
        createdAt: FieldValue.serverTimestamp(),
      });
  } catch (e) {
    // Inbox is best-effort — never let it fail the push pipeline.
    logger.warn(`writeInbox failed for ${userId}: ${e}`);
  }
}

/**
 * Send the same notification via FCM *and* write a row to the in-app
 * inbox. Order is parallel — neither blocks the other.
 */
async function notifyUser(
  userId: string,
  notification: {title: string; body: string},
  data: DataPayload,
): Promise<void> {
  await Promise.all([
    sendToUser(userId, notification, data),
    writeInbox(userId, notification, data),
  ]);
}

// ---------- 1. application decision ---------------------------------------

/**
 * Fires when an admin flips `instructor_applications/{userId}.status` to
 * `approved` or `rejected`. DMs the applicant.
 */
export const onApplicationDecision = onDocumentUpdated(
  'instructor_applications/{userId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === after.status) return; // status didn't change

    const userId = event.params.userId;

    if (after.status === 'approved') {
      await notifyUser(
        userId,
        {
          title: "You're approved!",
          body: 'You can now author courses in the iLearnIt instructor portal.',
        },
        dataOnly({
          type: 'application_approved',
          route: '/',
        }),
      );
    } else if (after.status === 'rejected') {
      await notifyUser(
        userId,
        {
          title: 'Application update',
          body:
            (after.rejectionReason as string | undefined) ??
            'Your instructor application was not approved this time.',
        },
        dataOnly({
          type: 'application_rejected',
          route: '/pending',
        }),
      );
    }
  },
);

// ---------- 2. enrollment created -----------------------------------------

/**
 * Fires when a new doc lands in `enrollments/{id}`. The mobile app writes
 * this on successful IAP purchase. We DM the buyer with a "you're enrolled"
 * push that deep-links to the course.
 *
 * Shape expected on the doc:
 *   { userId, courseId, courseTitle, createdAt }
 */
export const onEnrollmentCreated = onDocumentCreated(
  'enrollments/{enrollmentId}',
  async (event) => {
    const d = event.data?.data();
    if (!d) return;
    const userId = d.userId as string | undefined;
    const courseId = d.courseId as string | undefined;
    const courseTitle = (d.courseTitle as string | undefined) ?? 'your new course';
    if (!userId || !courseId) return;

    await notifyUser(
      userId,
      {
        title: "You're enrolled!",
        body: `Tap to start learning: ${courseTitle}`,
      },
      dataOnly({
        type: 'enrollment_created',
        courseId,
        route: `/courses/${courseId}`,
      }),
    );
  },
);

// ---------- 3. admin broadcast --------------------------------------------

/**
 * Fires when the admin portal writes to `notification_broadcasts/{id}`.
 * Reads the topic/title/body off the doc, sends via FCM, and stamps the
 * doc with `sentAt` + `status: 'sent' | 'failed'`.
 */
export const onNotificationBroadcast = onDocumentCreated(
  'notification_broadcasts/{broadcastId}',
  async (event) => {
    const ref = event.data?.ref;
    const d = event.data?.data();
    if (!ref || !d) return;

    const topic = d.topic as string | undefined;
    const title = d.title as string | undefined;
    const body = d.body as string | undefined;
    const route = d.route as string | undefined;

    if (!topic || !title || !body) {
      await ref.update({
        status: 'failed',
        failureReason: 'Missing topic, title, or body.',
      });
      return;
    }

    try {
      const messageId = await sendToTopic(
        topic,
        {title, body},
        dataOnly({
          type: 'broadcast',
          broadcastId: event.params.broadcastId,
          route: route ?? '/',
        }),
      );
      await ref.update({
        status: 'sent',
        sentAt: FieldValue.serverTimestamp(),
        fcmMessageId: messageId,
      });
      logger.info(`broadcast ${event.params.broadcastId} → topic ${topic} = ${messageId}`);
    } catch (e: unknown) {
      const reason = e instanceof Error ? e.message : String(e);
      await ref.update({
        status: 'failed',
        failureReason: reason,
      });
      logger.error(`broadcast ${event.params.broadcastId} failed: ${reason}`);
    }
  },
);

// ---------- 4. account deletion -------------------------------------------

/**
 * Hard-delete a user and everything they own.
 *
 * Apple §5.1.1(v) requires apps that allow account creation to also expose
 * an in-app deletion path. This callable is invoked from
 * `Profile → Settings → Delete account` after the client has re-authenticated.
 *
 * What is removed:
 *   • users/{uid}                            (profile + embedded subscription)
 *   • instructor_applications/{uid}          (application, if any)
 *   • enrollments where userId == uid        (and their /progress subcoll)
 *   • courses/{*}/reviews/{uid}              (every authored review)
 *   • songbooks/{*}/reviews/{*}              (where userId == uid)
 *   • Storage objects under users/{uid}/     (avatars, uploads)
 *   • Auth user record                       (admin.auth().deleteUser)
 *
 * Aggregated counters (courses.rating, courses.reviewCount, …) are not
 * back-recomputed here — the per-review trigger recompute step does that.
 *
 * What is NOT touched:
 *   • App Store / Play Store auto-renewing subscriptions. The client copy
 *     and the docs warn the user that the subscription must be canceled
 *     separately through the store.
 *   • Anonymous aggregate analytics (e.g. "total reviews on course X").
 *
 * The function returns `{ ok: true }` on success. Any unexpected throw is
 * surfaced as `HttpsError('internal', …)` so the client can show a generic
 * failure snackbar without leaking server internals.
 */
export const deleteAccount = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError(
      'unauthenticated',
      'You must be signed in to delete your account.',
    );
  }

  logger.info(`deleteAccount: starting for uid=${uid}`);

  try {
    // 1. User profile + instructor application (single batch).
    const batch = db.batch();
    batch.delete(db.collection('users').doc(uid));
    batch.delete(db.collection('instructor_applications').doc(uid));
    await batch.commit();

    // 2. Enrollments + nested progress.
    await deleteEnrollments(uid);

    // 3. Authored reviews on courses + songbooks.
    await deleteAuthoredCourseReviews(uid);
    await deleteAuthoredSongbookReviews(uid);

    // 3a. Wishlist subcollection.
    await deleteSubcollection(
      db.collection('users').doc(uid).collection('wishlist'),
    );

    // 3b. Private lecture notes.
    await deleteSubcollection(
      db.collection('users').doc(uid).collection('notes'),
    );

    // 4. Storage objects under users/{uid}/.
    try {
      await storage.bucket().deleteFiles({prefix: `users/${uid}/`});
    } catch (e) {
      // Storage deletion is best-effort — log and keep going so the user is
      // still removed from Auth + Firestore even if the bucket is empty or
      // not configured.
      logger.warn(`deleteAccount: storage cleanup failed for ${uid}: ${e}`);
    }

    // 5. Auth record — must be last because losing the token mid-flow would
    //    prevent the function from completing.
    await auth.deleteUser(uid);

    logger.info(`deleteAccount: completed for uid=${uid}`);
    return {ok: true};
  } catch (e) {
    const reason = e instanceof Error ? e.message : String(e);
    logger.error(`deleteAccount failed for ${uid}: ${reason}`);
    throw new HttpsError(
      'internal',
      'We could not complete the deletion. Please try again later.',
      {reason},
    );
  }
});

/** Delete the user's enrollments and their /progress subcollection. */
async function deleteEnrollments(uid: string): Promise<void> {
  const snap = await db
    .collection('enrollments')
    .where('userId', '==', uid)
    .get();
  if (snap.empty) return;

  for (const doc of snap.docs) {
    await deleteSubcollection(doc.ref.collection('progress'));
    await doc.ref.delete();
  }
  logger.info(`deleteEnrollments: removed ${snap.size} for ${uid}`);
}

/**
 * Delete every `courses/{*}/reviews/{uid}` doc.
 *
 * The review doc id equals the author uid (we enforce one review per user
 * per course at the data layer), so we can target them directly via a
 * collection-group query.
 */
async function deleteAuthoredCourseReviews(uid: string): Promise<void> {
  const snap = await db.collectionGroup('reviews').where('userId', '==', uid).get();
  if (snap.empty) return;

  const batch = db.batch();
  for (const doc of snap.docs) {
    // Make sure we only touch reviews under `courses/*/reviews/*` —
    // collectionGroup will also match songbook reviews; those are handled
    // separately.
    if (doc.ref.path.startsWith('courses/')) {
      batch.delete(doc.ref);
    }
  }
  await batch.commit();
  logger.info(`deleteAuthoredCourseReviews: cleaned for ${uid}`);
}

/** Delete `songbooks/{*}/reviews/{*}` docs where `userId == uid`. */
async function deleteAuthoredSongbookReviews(uid: string): Promise<void> {
  const snap = await db.collectionGroup('reviews').where('userId', '==', uid).get();
  if (snap.empty) return;

  const batch = db.batch();
  for (const doc of snap.docs) {
    if (doc.ref.path.startsWith('songbooks/')) {
      batch.delete(doc.ref);
    }
  }
  await batch.commit();
  logger.info(`deleteAuthoredSongbookReviews: cleaned for ${uid}`);
}

/**
 * Delete every doc in a subcollection in batches of 200.
 * Firestore caps batch writes at 500 — 200 leaves room for the parent
 * delete + any retries.
 */
async function deleteSubcollection(
  ref: FirebaseFirestore.CollectionReference,
): Promise<void> {
  while (true) {
    const snap = await ref.limit(200).get();
    if (snap.empty) return;
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    if (snap.size < 200) return;
  }
}

// ---------- 5. course price drop → wishlist watchers ---------------------

/**
 * Rank of each [PriceTier]. Lower number == cheaper. Keep in lockstep
 * with `lib/features/purchases/domain/entities/price_tier.dart`.
 */
const PRICE_TIER_RANK: Record<string, number> = {
  basic: 0,
  standard: 1,
  premium: 2,
};

/**
 * Fires on `courses/{id}` update. When the priceTier drops (e.g. an
 * instructor reclassifies a `premium` course to `standard`), fan a push +
 * inbox row out to every user who has the course on their wishlist.
 *
 * Indexed on `wishlist` collection-group via the `courseId` field — see
 * `firestore.indexes.json`.
 *
 * For very popular courses (thousands of savers) this fan-out can blow
 * past Firestore's per-call write quota. We page the results and accept
 * the limitation that a Cloud Function timeout would lose the tail.
 * That's fine for v1 — escalate to a queue-based fan-out when a course
 * crosses ~5k saves.
 */
export const onCoursePriceDrop = onDocumentUpdated(
  'courses/{courseId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const beforeTier = (before.priceTier as string | undefined) ?? 'standard';
    const afterTier = (after.priceTier as string | undefined) ?? 'standard';
    if (beforeTier === afterTier) return;

    const beforeRank = PRICE_TIER_RANK[beforeTier] ?? 1;
    const afterRank = PRICE_TIER_RANK[afterTier] ?? 1;
    if (afterRank >= beforeRank) return; // not a drop

    const courseId = event.params.courseId;
    const courseTitle =
      (after.title as string | undefined) ?? 'a saved course';

    logger.info(
      `onCoursePriceDrop: ${courseId} ${beforeTier} → ${afterTier}`,
    );

    // Find every wishlist doc that references this course.
    const snap = await db
      .collectionGroup('wishlist')
      .where('courseId', '==', courseId)
      .get();
    if (snap.empty) return;

    // Each wishlist doc lives under `users/{uid}/wishlist/{courseId}` —
    // the saver's uid is the parent doc id.
    const savers: string[] = [];
    for (const d of snap.docs) {
      const userRef = d.ref.parent.parent;
      if (userRef) savers.push(userRef.id);
    }

    // Update the denormalized `priceTier` field on each saver's wishlist
    // doc so the Saved page reflects the new price immediately.
    {
      const updateBatch = db.batch();
      for (const d of snap.docs) {
        updateBatch.set(
          d.ref,
          {priceTier: afterTier},
          {merge: true},
        );
      }
      await updateBatch.commit();
    }

    const notification = {
      title: 'Price drop on a saved course',
      body: `${courseTitle} is now available at a lower tier.`,
    };
    const data = dataOnly({
      type: 'broadcast',
      route: `/courses/${courseId}`,
      courseId,
    });

    // Fan out — 1:1 push + inbox doc per saver. Parallel but capped to
    // 20 at a time so we don't hammer the FCM quota.
    const chunkSize = 20;
    for (let i = 0; i < savers.length; i += chunkSize) {
      const chunk = savers.slice(i, i + chunkSize);
      await Promise.all(chunk.map((uid) => notifyUser(uid, notification, data)));
    }
    logger.info(
      `onCoursePriceDrop: notified ${savers.length} wishlisters of ${courseId}`,
    );
  },
);

// ---------- 7. course question created ------------------------------------

/**
 * Fires when a learner posts a new question on a lecture:
 * `courses/{cid}/sections/{sid}/lectures/{lid}/questions/{qid}`.
 *
 * DMs the course's instructor so they can jump in and answer. The mobile
 * app deep-links to the thread page at:
 *   /courses/{cid}/lectures/{lid}/qa/{qid}?sectionId={sid}
 *
 * No-ops if:
 *   • The question is being authored by the instructor themselves.
 *   • The course doc is missing or has no `instructorId`.
 *
 * Cap: this trigger fans out to a single user (the instructor), so no
 * batching is needed — we lean on `notifyUser` to handle FCM + inbox.
 */
export const onCourseQuestionCreated = onDocumentCreated(
  'courses/{cid}/sections/{sid}/lectures/{lid}/questions/{qid}',
  async (event) => {
    const d = event.data?.data();
    if (!d) return;

    const {cid, sid, lid, qid} = event.params;
    const authorId = d.userId as string | undefined;
    const authorName =
      (d.userName as string | undefined) ?? 'A student';
    const body = (d.body as string | undefined) ?? '';

    // Look up the course's instructor.
    const courseSnap = await db.collection('courses').doc(cid).get();
    if (!courseSnap.exists) {
      logger.warn(`onCourseQuestionCreated: course ${cid} not found`);
      return;
    }
    const course = courseSnap.data() ?? {};
    const instructorId = course.instructorId as string | undefined;
    if (!instructorId) {
      logger.warn(`onCourseQuestionCreated: course ${cid} has no instructorId`);
      return;
    }

    // Don't notify the instructor about their own question (rare, but
    // possible if the instructor is also testing student flows).
    if (authorId && authorId === instructorId) return;

    const courseTitle =
      (course.title as string | undefined) ?? 'your course';
    // Trim long bodies — push notifications truncate aggressively.
    const preview =
      body.length > 140 ? `${body.substring(0, 137)}…` : body;

    await notifyUser(
      instructorId,
      {
        title: `New question on ${courseTitle}`,
        body: `${authorName}: ${preview}`,
      },
      dataOnly({
        type: 'course_question_created',
        courseId: cid,
        sectionId: sid,
        lectureId: lid,
        questionId: qid,
        route: `/courses/${cid}/lectures/${lid}/qa/${qid}?sectionId=${sid}`,
      }),
    );

    logger.info(
      `onCourseQuestionCreated: notified instructor ${instructorId} of question ${qid}`,
    );
  },
);

// ---------- 8. resolve Cloudflare Stream playback -------------------------

interface StreamPlaybackResult {
  hlsUrl: string | null;
  dashUrl: string | null;
  thumbnailUrl: string | null;
  durationSec: number;
  readyToStream: boolean;
}

/**
 * Resolves a Cloudflare Stream video UID to playback URLs.
 *
 * The Flutter client sends `{videoId: "bf53017eb..."}` and gets back
 * `{hlsUrl, dashUrl, thumbnailUrl, durationSec, readyToStream}`.
 *
 * The API token lives in a Firebase Secret and never leaves the
 * server. We require auth on the client side so anonymous strangers
 * can't enumerate the catalogue's video UIDs.
 *
 * Path: POST https://api.cloudflare.com/client/v4/accounts/{accountId}/stream/{videoId}
 */
export const resolveStreamPlayback = onCall(
  {secrets: [CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID]},
  async (request): Promise<StreamPlaybackResult> => {
    if (!request.auth) {
      throw new HttpsError(
        'unauthenticated',
        'Sign in to play this lecture.',
      );
    }

    const videoId = (request.data?.videoId as string | undefined)?.trim();
    if (!videoId) {
      throw new HttpsError('invalid-argument', 'videoId is required.');
    }
    // Cloudflare Stream UIDs are 32-char hex.
    if (!/^[a-f0-9]{32}$/i.test(videoId)) {
      throw new HttpsError(
        'invalid-argument',
        'videoId must be a Cloudflare Stream UID (32 hex chars).',
      );
    }

    // Trim aggressively — `firebase functions:secrets:set` reads from
    // stdin and a trailing newline silently corrupts the Authorization
    // header (request becomes `Bearer abc\n`) which Cloudflare rejects
    // with 400. Same risk on the account id; a trailing `\n` in the URL
    // path also triggers 400. Both are accepted as plain hex/alpha-num.
    const accountId = CLOUDFLARE_ACCOUNT_ID.value().trim();
    const token = CLOUDFLARE_API_TOKEN.value().trim();

    if (!/^[a-f0-9]{32}$/i.test(accountId)) {
      logger.error(
        `CLOUDFLARE_ACCOUNT_ID malformed (length=${accountId.length}). ` +
          'Re-set the secret without trailing whitespace.',
      );
      throw new HttpsError(
        'failed-precondition',
        'Server misconfiguration — account id invalid.',
      );
    }
    if (!token) {
      throw new HttpsError(
        'failed-precondition',
        'Server misconfiguration — token missing.',
      );
    }

    const url =
      `https://api.cloudflare.com/client/v4/accounts/${accountId}` +
      `/stream/${videoId}`;

    let response: Response;
    try {
      response = await fetch(url, {
        headers: {Authorization: `Bearer ${token}`},
      });
    } catch (e) {
      logger.error(`Cloudflare fetch failed for ${videoId}: ${e}`);
      throw new HttpsError(
        'unavailable',
        'Could not reach Cloudflare Stream.',
      );
    }

    if (!response.ok) {
      // Read the body so we can see what Cloudflare is actually
      // complaining about. The 400 path almost always carries a JSON
      // `errors: [{code, message}]` array that names the bad field.
      let bodyText = '';
      try {
        bodyText = (await response.text()).slice(0, 500);
      } catch (_) {
        /* ignore */
      }
      logger.warn(
        `Cloudflare returned ${response.status} for video ${videoId}. ` +
          `Body: ${bodyText}`,
      );
      // 404 / 403 from Cloudflare → surface as not-found to the client
      // so the UI can show a "video missing" message.
      throw new HttpsError(
        response.status === 404 ? 'not-found' : 'internal',
        `Cloudflare Stream returned ${response.status}: ${bodyText}`,
      );
    }

    interface CFResponse {
      success: boolean;
      result?: {
        readyToStream?: boolean;
        duration?: number;
        thumbnail?: string;
        playback?: {hls?: string; dash?: string};
      };
    }
    const payload = (await response.json()) as CFResponse;
    if (!payload.success || !payload.result) {
      throw new HttpsError(
        'internal',
        'Cloudflare response was not successful.',
      );
    }

    return {
      hlsUrl: payload.result.playback?.hls ?? null,
      dashUrl: payload.result.playback?.dash ?? null,
      thumbnailUrl: payload.result.thumbnail ?? null,
      durationSec: Math.round(payload.result.duration ?? 0),
      readyToStream: payload.result.readyToStream === true,
    };
  },
);

// =============================================================================
// Instructor revenue & student management — three callables
// =============================================================================

/**
 * Look up a user's role from `users/{uid}`. Returns 'student' if the
 * doc doesn't exist (matches the default in the admin router).
 */
async function getRole(uid: string): Promise<string> {
  const snap = await db.collection('users').doc(uid).get();
  return (snap.data()?.role as string) || 'student';
}

/**
 * Admin-only: flip a transaction's status to 'refunded', cancel the
 * matching enrollment, and notify the student.
 *
 * In v1 NO money is moved — this is bookkeeping only. A future
 * version will also call the App Store / Play Store refund API
 * inside this function so the audit trail covers both sides.
 */
export const processRefund = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  if ((await getRole(request.auth.uid)) !== 'admin') {
    throw new HttpsError('permission-denied', 'Admin role required.');
  }

  const txnId = (request.data?.transactionId as string | undefined)?.trim();
  const reason = (request.data?.reason as string | undefined)?.trim() || null;
  if (!txnId) {
    throw new HttpsError('invalid-argument', 'transactionId is required.');
  }

  const txnRef = db.collection('transactions').doc(txnId);
  const txnSnap = await txnRef.get();
  if (!txnSnap.exists) {
    throw new HttpsError('not-found', `Transaction ${txnId} not found.`);
  }
  const txn = txnSnap.data() || {};
  if (txn.status === 'refunded') {
    throw new HttpsError(
      'failed-precondition',
      'Transaction is already refunded.',
    );
  }

  const courseId = txn.courseId as string;
  const studentUid = txn.studentUid as string;

  // Batched write: refund the txn + cancel any matching enrollment
  // for this student/course in one go.
  const batch = db.batch();
  batch.update(txnRef, {
    status: 'refunded',
    refundedAt: FieldValue.serverTimestamp(),
    refundedByUid: request.auth.uid,
    refundReason: reason,
  });

  const enrSnap = await db
    .collection('enrollments')
    .where('userId', '==', studentUid)
    .where('courseId', '==', courseId)
    .limit(5)
    .get();
  for (const doc of enrSnap.docs) {
    batch.update(doc.ref, {
      status: 'cancelled',
      cancelledAt: FieldValue.serverTimestamp(),
      cancelledReason: 'refund',
    });
  }

  await batch.commit();

  // Best-effort notify — failure must not roll back the refund.
  try {
    await notifyUser(
      studentUid,
      {
        title: 'Refund processed',
        body: `Your purchase of ${
          txn.courseTitle || 'a course'
        } has been refunded.`,
      },
      dataOnly({
        type: 'refund_processed',
        route: '/profile/purchases',
        courseId: courseId,
        transactionId: txnId,
      }),
    );
  } catch (e) {
    logger.warn(`Refund notify failed for ${studentUid}: ${e}`);
  }

  return {ok: true};
});

/**
 * Admin-only: flip a payout's status to 'paid'. The actual money
 * transfer happens out-of-band; this just records the bookkeeping.
 */
export const markPayoutPaid = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  if ((await getRole(request.auth.uid)) !== 'admin') {
    throw new HttpsError('permission-denied', 'Admin role required.');
  }

  const payoutId = (request.data?.payoutId as string | undefined)?.trim();
  const method = (request.data?.method as string | undefined)?.trim() || null;
  if (!payoutId) {
    throw new HttpsError('invalid-argument', 'payoutId is required.');
  }

  const ref = db.collection('payouts').doc(payoutId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError('not-found', `Payout ${payoutId} not found.`);
  }
  if ((snap.data()?.status as string) === 'paid') {
    throw new HttpsError('failed-precondition', 'Payout is already paid.');
  }

  await ref.update({
    status: 'paid',
    paidAt: FieldValue.serverTimestamp(),
    paidByUid: request.auth.uid,
    payoutMethod: method,
  });
  return {ok: true};
});

/**
 * Instructor-only: broadcast a message to every student enrolled in
 * one of the instructor's courses. Re-uses the existing notifyUser
 * helper (FCM push + inbox row) for each recipient.
 *
 * Privacy: the instructor never sees student email addresses or
 * device tokens — they only specify the courseId. The fan-out runs
 * under Admin SDK and resolves recipients server-side.
 */
export const instructorBroadcast = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  const role = await getRole(request.auth.uid);
  if (role !== 'instructor' && role !== 'admin') {
    throw new HttpsError(
      'permission-denied',
      'Instructor or admin role required.',
    );
  }

  const courseId = (request.data?.courseId as string | undefined)?.trim();
  const title = (request.data?.title as string | undefined)?.trim();
  const body = (request.data?.body as string | undefined)?.trim();
  if (!courseId || !title || !body) {
    throw new HttpsError(
      'invalid-argument',
      'courseId, title, and body are required.',
    );
  }
  if (title.length > 80 || body.length > 800) {
    throw new HttpsError(
      'invalid-argument',
      'Title max 80 chars; body max 800 chars.',
    );
  }

  // Verify the caller is the course's instructor (admin bypass).
  const courseSnap = await db.collection('courses').doc(courseId).get();
  if (!courseSnap.exists) {
    throw new HttpsError('not-found', `Course ${courseId} not found.`);
  }
  const courseInstructorId = courseSnap.data()?.instructorId as
    | string
    | undefined;
  if (role !== 'admin' && courseInstructorId !== request.auth.uid) {
    throw new HttpsError(
      'permission-denied',
      'You do not own this course.',
    );
  }

  // Collect recipients from enrollments — distinct userIds.
  const enrSnap = await db
    .collection('enrollments')
    .where('courseId', '==', courseId)
    .get();
  const recipients = new Set<string>();
  for (const doc of enrSnap.docs) {
    const uid = doc.data()?.userId as string | undefined;
    if (uid) recipients.add(uid);
  }

  // Fan out in chunks of 20 to keep within rate limits.
  const data = dataOnly({
    type: 'instructor_broadcast',
    route: `/courses/${courseId}`,
    courseId,
    instructorUid: request.auth.uid,
  });
  const uids = Array.from(recipients);
  for (let i = 0; i < uids.length; i += 20) {
    const chunk = uids.slice(i, i + 20);
    await Promise.all(
      chunk.map((uid) => notifyUser(uid, {title, body}, data)),
    );
  }

  return {ok: true, recipientCount: uids.length};
});
