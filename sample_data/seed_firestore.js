#!/usr/bin/env node
/**
 * Firestore seed script for iLearnIt.
 *
 * Reads `instructors.json` and `courses.json` (which use ISO date strings
 * for any timestamp fields), then writes them to Firestore using the
 * Admin SDK with batched writes (max 500 ops per batch).
 *
 * Usage:
 *
 *   # 1. Install the Admin SDK once (in this folder):
 *   npm install firebase-admin
 *
 *   # 2. Provide service-account credentials. Two options:
 *   #    a) Point GOOGLE_APPLICATION_CREDENTIALS at a JSON key file.
 *   #    b) Place `service-account.dev.json` / `service-account.prod.json`
 *   #       next to this script and the code will pick them up by flavor.
 *
 *   # 3. Seed dev:
 *   node seed_firestore.js --flavor dev
 *
 *   # 4. Seed prod:
 *   node seed_firestore.js --flavor prod
 *
 *   # Optional flags:
 *   #   --dry           : log everything but don't write
 *   #   --wipe          : delete the existing `courses` and `instructors`
 *   #                     collections before writing (use with care)
 *   #   --only=courses  : seed only one collection (courses | instructors)
 */
'use strict';

const fs = require('fs');
const path = require('path');

// ── CLI args ─────────────────────────────────────────────────────────
// Accept both `--flavor=dev` and `--flavor dev` forms. When a `--flag`
// is followed by a non-`--` token, that token becomes the value.
// `--flag --next` keeps `flag` as a boolean `true` (no value consumed).
const argv = process.argv.slice(2);
const args = {};
for (let i = 0; i < argv.length; i++) {
  const raw = argv[i];
  if (!raw.startsWith('--')) continue;
  const eq = raw.indexOf('=');
  if (eq !== -1) {
    args[raw.slice(2, eq)] = raw.slice(eq + 1);
    continue;
  }
  const key = raw.slice(2);
  const peek = argv[i + 1];
  if (peek !== undefined && !peek.startsWith('--')) {
    args[key] = peek;
    i += 1; // consume the value token
  } else {
    args[key] = true;
  }
}

const flavor = args.flavor || 'dev';
if (!['dev', 'prod'].includes(flavor)) {
  console.error(`Invalid --flavor: ${flavor}. Use 'dev' or 'prod'.`);
  process.exit(1);
}

const isDry = !!args.dry;
const shouldWipe = !!args.wipe;
const onlyCollection = args.only;

// ── Admin SDK init ───────────────────────────────────────────────────
const admin = require('firebase-admin');

const localKeyPath = path.join(__dirname, `service-account.${flavor}.json`);
if (!process.env.GOOGLE_APPLICATION_CREDENTIALS && fs.existsSync(localKeyPath)) {
  admin.initializeApp({
    credential: admin.credential.cert(require(localKeyPath)),
  });
} else {
  // Falls back to GOOGLE_APPLICATION_CREDENTIALS env var.
  admin.initializeApp();
}

const db = admin.firestore();
const { Timestamp } = admin.firestore;

// ── Helpers ──────────────────────────────────────────────────────────
const TIMESTAMP_FIELDS = new Set(['publishedAt', 'createdAt', 'joinedAt']);

/** Convert any ISO-string fields named in TIMESTAMP_FIELDS to Firestore Timestamps. */
function hydrate(doc) {
  const out = { ...doc };
  for (const key of TIMESTAMP_FIELDS) {
    if (typeof out[key] === 'string') {
      out[key] = Timestamp.fromDate(new Date(out[key]));
    }
  }
  return out;
}

async function deleteCollection(name, batchSize = 400) {
  const ref = db.collection(name);
  const snap = await ref.limit(batchSize).get();
  if (snap.empty) return 0;
  let deleted = 0;
  let batch = db.batch();
  for (const doc of snap.docs) {
    batch.delete(doc.ref);
    deleted += 1;
  }
  await batch.commit();
  return deleted + (await deleteCollection(name, batchSize));
}

async function writeCollection(name, docs) {
  const ids = Object.keys(docs);
  console.log(`→ Writing ${ids.length} docs to "${name}"…`);

  const CHUNK = 400; // Firestore batch limit is 500; stay safely under.
  for (let i = 0; i < ids.length; i += CHUNK) {
    const batch = db.batch();
    const slice = ids.slice(i, i + CHUNK);
    for (const id of slice) {
      const ref = db.collection(name).doc(id);
      batch.set(ref, hydrate(docs[id]));
    }
    if (isDry) {
      console.log(`  [dry] would commit batch ${i / CHUNK + 1} (${slice.length} docs)`);
    } else {
      await batch.commit();
      console.log(`  ✓ committed batch ${i / CHUNK + 1} (${slice.length} docs)`);
    }
  }
}

/**
 * Write the `sections` subcollection under each course AND the
 * `lectures` sub-subcollection under each section.
 *
 * Wire format on Firestore:
 *   courses/{cid}                              (top-level doc)
 *     sections/{sid}                           (id, title, order)
 *       lectures/{lid}                         (id, title, type, durationSeconds, mediaUrl, …)
 *
 * The consumer reader (`CoursesRemoteDataSource.fetchSections`) hydrates
 * each `CourseSectionModel.lectures` field by reading the lectures
 * subcollection in parallel. The admin portal writes lectures the same
 * way (`AdminCoursesDataSource.createLecture` →
 * `courses/{cid}/sections/{sid}/lectures.doc()`), so the seed has to
 * match — embedding lectures on the section doc renders nothing on
 * mobile.
 *
 * `sectionsByCourse` source-of-truth shape (preserved for editor
 * ergonomics — easy to scan diffs):
 *   { courseId: [ { id, title, order, lectures: [{id, title, …}, …] } ] }
 */
async function writeSections(sectionsByCourse) {
  const courseIds = Object.keys(sectionsByCourse);

  // Flatten section + lecture writes into two parallel lists so we can
  // batch each across the 500-op Firestore limit independently.
  const sectionPairs = [];
  const lecturePairs = [];
  for (const courseId of courseIds) {
    for (const section of sectionsByCourse[courseId]) {
      const lectures = section.lectures || [];
      // Strip the embedded array — lectures now live as their own docs.
      // Spread copy so we don't mutate the in-memory source data
      // (matters if the caller re-uses sectionsByCourse later).
      const { lectures: _stripped, ...sectionDoc } = section;
      sectionPairs.push({ courseId, section: sectionDoc });
      for (const lecture of lectures) {
        lecturePairs.push({ courseId, sectionId: section.id, lecture });
      }
    }
  }

  console.log(
    `→ Writing ${sectionPairs.length} sections + ` +
    `${lecturePairs.length} lecture docs across ${courseIds.length} courses…`,
  );

  const CHUNK = 400;

  // ── Sections ───────────────────────────────────────────────────────
  for (let i = 0; i < sectionPairs.length; i += CHUNK) {
    const batch = db.batch();
    const slice = sectionPairs.slice(i, i + CHUNK);
    for (const { courseId, section } of slice) {
      const ref = db
        .collection('courses')
        .doc(courseId)
        .collection('sections')
        .doc(section.id);
      batch.set(ref, hydrate(section));
    }
    if (isDry) {
      console.log(`  [dry] would commit sections batch ${i / CHUNK + 1} (${slice.length} docs)`);
    } else {
      await batch.commit();
      console.log(`  ✓ committed sections batch ${i / CHUNK + 1} (${slice.length} docs)`);
    }
  }

  // ── Lectures (sub-subcollection per section) ───────────────────────
  for (let i = 0; i < lecturePairs.length; i += CHUNK) {
    const batch = db.batch();
    const slice = lecturePairs.slice(i, i + CHUNK);
    for (const { courseId, sectionId, lecture } of slice) {
      const ref = db
        .collection('courses')
        .doc(courseId)
        .collection('sections')
        .doc(sectionId)
        .collection('lectures')
        .doc(lecture.id);
      batch.set(ref, hydrate(lecture));
    }
    if (isDry) {
      console.log(`  [dry] would commit lectures batch ${i / CHUNK + 1} (${slice.length} docs)`);
    } else {
      await batch.commit();
      console.log(`  ✓ committed lectures batch ${i / CHUNK + 1} (${slice.length} docs)`);
    }
  }
}

/**
 * Recursively delete the curriculum subtree for every course:
 *   courses/{cid}/sections/{sid}/lectures/{lid}   ← deleted first (deep)
 *   courses/{cid}/sections/{sid}                  ← then the section docs
 *
 * Firestore requires deleting subcollection docs before the parent so
 * the parent doc fully disappears (otherwise the parent stays as a
 * tombstone holding the subcollection). Slow but thorough — only
 * runs when --wipe is set.
 */
async function wipeAllSections() {
  const coursesSnap = await db.collection('courses').get();
  let totalSections = 0;
  let totalLectures = 0;
  for (const courseDoc of coursesSnap.docs) {
    const sectionsRef = courseDoc.ref.collection('sections');
    const sectionsSnap = await sectionsRef.get();

    // 1. Lectures first.
    for (const sectionDoc of sectionsSnap.docs) {
      const lecturesRef = sectionDoc.ref.collection('lectures');
      while (true) {
        const snap = await lecturesRef.limit(400).get();
        if (snap.empty) break;
        const batch = db.batch();
        for (const d of snap.docs) batch.delete(d.ref);
        await batch.commit();
        totalLectures += snap.size;
        if (snap.size < 400) break;
      }
    }

    // 2. Then sections.
    while (true) {
      const snap = await sectionsRef.limit(400).get();
      if (snap.empty) break;
      const batch = db.batch();
      for (const d of snap.docs) batch.delete(d.ref);
      await batch.commit();
      totalSections += snap.size;
      if (snap.size < 400) break;
    }
  }
  console.log(`  (wiped ${totalLectures} lectures + ${totalSections} sections)`);
  return totalSections + totalLectures;
}

// ── Main ─────────────────────────────────────────────────────────────
(async () => {
  const here = __dirname;
  const instructors = JSON.parse(
    fs.readFileSync(path.join(here, 'instructors.json'), 'utf-8'),
  );
  const courses = JSON.parse(
    fs.readFileSync(path.join(here, 'courses.json'), 'utf-8'),
  );

  const songbooks = JSON.parse(
      fs.readFileSync(path.join(here, 'songbooks.json'), 'utf-8'),
    );

  // sections.json is optional (for backward compat), but when present we
  // write the curriculum subcollection.
  const sectionsPath = path.join(here, 'sections.json');
  const sectionsByCourse = fs.existsSync(sectionsPath)
    ? JSON.parse(fs.readFileSync(sectionsPath, 'utf-8'))
    : null;

    const songbooksPath = path.join(here, 'songbooks.json');

  console.log(`iLearnIt Firestore seed — flavor=${flavor} dry=${isDry} wipe=${shouldWipe}`);

  if (shouldWipe && !isDry) {
    if (!onlyCollection || onlyCollection === 'sections') {
      const n = await wipeAllSections();
      console.log(`✗ wiped sections subcollections (${n} docs)`);
    }
    if (!onlyCollection || onlyCollection === 'courses') {
      const n = await deleteCollection('courses');
      console.log(`✗ wiped courses (${n} docs)`);
    }
    if (!onlyCollection || onlyCollection === 'instructors') {
      const n = await deleteCollection('instructors');
      console.log(`✗ wiped instructors (${n} docs)`);
    }
    if (!onlyCollection || onlyCollection === 'songbooks') {
          const n = await deleteCollection('songbooks');
          console.log(`✗ wiped songbooks (${n} docs)`);
        }
  }

  if (!onlyCollection || onlyCollection === 'instructors') {
    await writeCollection('instructors', instructors);
  }
  if (!onlyCollection || onlyCollection === 'courses') {
    await writeCollection('courses', courses);
  }
  if (sectionsByCourse && (!onlyCollection || onlyCollection === 'sections')) {
    await writeSections(sectionsByCourse);
  }

  if (!onlyCollection || onlyCollection === 'songbooks') {
      await writeCollection('songbooks', songbooks);
    }

  console.log('✅ Done.');
  process.exit(0);
})().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
