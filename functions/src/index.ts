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
import {getFirestore, FieldValue} from 'firebase-admin/firestore';
import {getMessaging, MulticastMessage, TopicMessage} from 'firebase-admin/messaging';
import {onDocumentCreated, onDocumentUpdated} from 'firebase-functions/v2/firestore';
import {logger} from 'firebase-functions/v2';

initializeApp();
const db = getFirestore();
const fcm = getMessaging();

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
      await sendToUser(
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
      await sendToUser(
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

    await sendToUser(
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
