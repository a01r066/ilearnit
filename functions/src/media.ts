/**
 * iLearnIt — paid lecture files in Firebase Storage.
 *
 * Lecture media (legacy, non-Cloudflare video/audio, PDF/DOCX lectures)
 * and lecture resources are stored as `gs://bucket/path` references in the
 * lecture doc — never as token-bearing download URLs, which anyone could
 * copy out of the (public) lecture doc and share.
 *
 *   resolveLectureMedia       — entitlement check → short-lived V4 signed URL
 *   onLectureObjectFinalized  — strips Firebase download tokens from newly
 *                               uploaded lecture media / resources
 *   migrateLectureMediaToPrivate — admin one-off: rewrites legacy
 *                               download URLs to gs:// refs and revokes
 *                               their tokens
 *
 * IAM: V4 signing from Cloud Functions uses the IAM signBlob API. Grant the
 * functions' runtime service account "Service Account Token Creator" on
 * itself (see docs/production_migration.md, Appendix D).
 */

import {getFirestore, Firestore} from 'firebase-admin/firestore';
import {getStorage} from 'firebase-admin/storage';
import {HttpsError, onCall} from 'firebase-functions/v2/https';
import {onObjectFinalized} from 'firebase-functions/v2/storage';
import {logger} from 'firebase-functions/v2';

import {hasCourseAccess, hasSongbookAccess} from './iap';
import {requireAppCheck} from './appCheck';

const db = (): Firestore => getFirestore();

/** Signed URL lifetime. Long enough for a full download / playback session. */
const SIGNED_URL_TTL_MS = 4 * 60 * 60 * 1000;

/** courses/{c}/sections/{s}/lectures/{l}/(media|resources)/{file} */
const LECTURE_OBJECT_RE =
  /^courses\/([^/]+)\/sections\/[^/]+\/lectures\/[^/]+\/(media|resources)\/.+$/;

/** songbooks/{id}/content/{file} — the paid songbook PDF. */
const SONGBOOK_CONTENT_RE = /^songbooks\/([^/]+)\/content\/.+$/;

export interface StorageRef {
  bucket: string;
  path: string;
}

/** Parses `gs://bucket/path` or a Firebase Storage download URL. */
export function parseStorageRef(raw: string | undefined | null): StorageRef | null {
  if (!raw) return null;
  if (raw.startsWith('gs://')) {
    const rest = raw.slice(5);
    const i = rest.indexOf('/');
    if (i <= 0) return null;
    return {bucket: rest.slice(0, i), path: rest.slice(i + 1)};
  }
  try {
    const u = new URL(raw);
    if (u.hostname === 'firebasestorage.googleapis.com') {
      const m = u.pathname.match(/^\/v0\/b\/([^/]+)\/o\/(.+)$/);
      if (m) return {bucket: decodeURIComponent(m[1]), path: decodeURIComponent(m[2])};
    }
  } catch {
    /* not a URL */
  }
  return null;
}

// ---------------------------------------------------------------------------
// resolveLectureMedia
// ---------------------------------------------------------------------------

export const resolveLectureMedia = onCall(async (request) => {
  requireAppCheck(request, 'resolveLectureMedia');
  const courseId = (request.data?.courseId as string | undefined)?.trim();
  const sectionId = (request.data?.sectionId as string | undefined)?.trim();
  const lectureId = (request.data?.lectureId as string | undefined)?.trim();
  const resourceIndex = request.data?.resourceIndex as number | undefined | null;
  if (!courseId || !sectionId || !lectureId) {
    throw new HttpsError('invalid-argument', 'courseId, sectionId and lectureId are required.');
  }

  const snap = await db()
    .doc(`courses/${courseId}/sections/${sectionId}/lectures/${lectureId}`)
    .get();
  const lecture = snap.data();
  if (!lecture) throw new HttpsError('not-found', 'Lecture not found.');

  let raw: string | undefined;
  if (resourceIndex === undefined || resourceIndex === null) {
    raw = lecture.mediaUrl as string | undefined;
  } else {
    const resources = Array.isArray(lecture.resources) ? lecture.resources : [];
    if (!Number.isInteger(resourceIndex) || resourceIndex < 0 || resourceIndex >= resources.length) {
      throw new HttpsError('invalid-argument', 'resourceIndex out of range.');
    }
    raw = (resources[resourceIndex] as {url?: string})?.url;
  }
  if (!raw) throw new HttpsError('not-found', 'This lecture has no file.');

  // Preview lectures (and their resources) are free for everyone.
  if (lecture.isPreview !== true) {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to open this lecture.');
    if (!(await hasCourseAccess(uid, courseId))) {
      throw new HttpsError('permission-denied', 'Purchase this course to open this lecture.');
    }
  }

  const ref = parseStorageRef(raw);
  if (!ref) {
    // External URL (e.g. a CDN link an admin pasted) — nothing to sign.
    if (/^https:\/\//i.test(raw)) return {url: raw, expiresAtMs: null};
    throw new HttpsError('failed-precondition', 'Unsupported media reference.');
  }
  // Only sign objects that belong to THIS course.
  const m = ref.path.match(LECTURE_OBJECT_RE);
  if (!m || m[1] !== courseId) {
    logger.warn(`resolveLectureMedia: path outside course ${courseId}: ${ref.path}`);
    throw new HttpsError('permission-denied', 'File does not belong to this course.');
  }

  const expires = Date.now() + SIGNED_URL_TTL_MS;
  try {
    const [url] = await getStorage().bucket(ref.bucket).file(ref.path).getSignedUrl({
      version: 'v4',
      action: 'read',
      expires,
    });
    return {url, expiresAtMs: expires};
  } catch (e) {
    logger.error(`resolveLectureMedia: signing failed for ${ref.path}`, e);
    throw new HttpsError('internal', 'Could not prepare the file. Please try again.');
  }
});

// ---------------------------------------------------------------------------
// onLectureObjectFinalized — revoke download tokens on upload
// ---------------------------------------------------------------------------

/**
 * Firebase SDK uploads get a `firebaseStorageDownloadTokens` metadata entry
 * automatically; a token makes the object downloadable by anyone holding
 * the URL, bypassing Storage rules. Paid lecture files must only be
 * reachable through resolveLectureMedia's signed URLs, so remove it.
 */
export const onLectureObjectFinalized = onObjectFinalized(async (event) => {
  const path = event.data.name;
  if (!path || !(LECTURE_OBJECT_RE.test(path) || SONGBOOK_CONTENT_RE.test(path))) return;
  if (!event.data.metadata?.firebaseStorageDownloadTokens) return;
  await getStorage()
    .bucket(event.data.bucket)
    .file(path)
    .setMetadata({metadata: {firebaseStorageDownloadTokens: null}});
  logger.info(`onLectureObjectFinalized: revoked download token for ${path}`);
});

// ---------------------------------------------------------------------------
// migrateLectureMediaToPrivate — admin one-off
// ---------------------------------------------------------------------------

export const migrateLectureMediaToPrivate = onCall(
  {timeoutSeconds: 540, memory: '512MiB'},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');
    const me = await db().doc(`users/${uid}`).get();
    if (me.data()?.role !== 'admin') {
      throw new HttpsError('permission-denied', 'Admin role required.');
    }

    const lectures = await db().collectionGroup('lectures').get();
    let docsUpdated = 0;
    let tokensRevoked = 0;
    const failures: string[] = [];

    const privatize = async (raw: unknown): Promise<string | null> => {
      if (typeof raw !== 'string') return null;
      const ref = parseStorageRef(raw);
      if (!ref || !LECTURE_OBJECT_RE.test(ref.path)) return null;
      try {
        const file = getStorage().bucket(ref.bucket).file(ref.path);
        const [meta] = await file.getMetadata();
        if (meta.metadata?.firebaseStorageDownloadTokens) {
          await file.setMetadata({metadata: {firebaseStorageDownloadTokens: null}});
          tokensRevoked++;
        }
      } catch (e) {
        failures.push(ref.path);
        logger.warn(`migrateLectureMediaToPrivate: ${ref.path}: ${e}`);
      }
      const gs = `gs://${ref.bucket}/${ref.path}`;
      return gs === raw ? null : gs;
    };

    for (const doc of lectures.docs) {
      const data = doc.data();
      const patch: Record<string, unknown> = {};

      const media = await privatize(data.mediaUrl);
      if (media) patch.mediaUrl = media;

      if (Array.isArray(data.resources)) {
        let changed = false;
        const next = [];
        for (const r of data.resources as Array<Record<string, unknown>>) {
          const gs = await privatize(r?.url);
          if (gs) {
            changed = true;
            next.push({...r, url: gs});
          } else {
            next.push(r);
          }
        }
        if (changed) patch.resources = next;
      }

      if (Object.keys(patch).length > 0) {
        await doc.ref.update(patch);
        docsUpdated++;
      }
    }

    logger.info(
      `migrateLectureMediaToPrivate: lectures=${lectures.size} updated=${docsUpdated} ` +
        `tokensRevoked=${tokensRevoked} failures=${failures.length}`,
    );
    return {lectures: lectures.size, docsUpdated, tokensRevoked, failures};
  },
);

// ---------------------------------------------------------------------------
// resolveSongbookContent — signed URL for a songbook PDF
// ---------------------------------------------------------------------------

export const resolveSongbookContent = onCall(async (request) => {
  requireAppCheck(request, 'resolveSongbookContent');
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in to open this songbook.');
  const songbookId = (request.data?.songbookId as string | undefined)?.trim();
  if (!songbookId) throw new HttpsError('invalid-argument', 'songbookId is required.');

  if (!(await hasSongbookAccess(uid, songbookId))) {
    throw new HttpsError('permission-denied', 'Get this songbook to open it.');
  }
  const book = (await db().doc(`songbooks/${songbookId}`).get()).data();
  const ref = parseStorageRef(book?.pdfPath as string | undefined);
  const m = ref?.path.match(SONGBOOK_CONTENT_RE);
  if (!ref || !m || m[1] !== songbookId) {
    throw new HttpsError('not-found', 'This songbook has no content yet.');
  }
  const expires = Date.now() + SIGNED_URL_TTL_MS;
  try {
    const [url] = await getStorage().bucket(ref.bucket).file(ref.path).getSignedUrl({
      version: 'v4',
      action: 'read',
      expires,
    });
    return {url, expiresAtMs: expires};
  } catch (e) {
    logger.error(`resolveSongbookContent: signing failed for ${ref.path}`, e);
    throw new HttpsError('internal', 'Could not prepare the file. Please try again.');
  }
});

