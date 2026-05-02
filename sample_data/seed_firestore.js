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
const args = process.argv.slice(2).reduce((acc, raw) => {
  if (raw.startsWith('--')) {
    const [key, value] = raw.replace(/^--/, '').split('=');
    acc[key] = value === undefined ? true : value;
  }
  return acc;
}, {});

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

// ── Main ─────────────────────────────────────────────────────────────
(async () => {
  const here = __dirname;
  const instructors = JSON.parse(
    fs.readFileSync(path.join(here, 'instructors.json'), 'utf-8'),
  );
  const courses = JSON.parse(
    fs.readFileSync(path.join(here, 'courses.json'), 'utf-8'),
  );

  console.log(`iLearnIt Firestore seed — flavor=${flavor} dry=${isDry} wipe=${shouldWipe}`);

  if (shouldWipe && !isDry) {
    if (!onlyCollection || onlyCollection === 'courses') {
      const n = await deleteCollection('courses');
      console.log(`✗ wiped courses (${n} docs)`);
    }
    if (!onlyCollection || onlyCollection === 'instructors') {
      const n = await deleteCollection('instructors');
      console.log(`✗ wiped instructors (${n} docs)`);
    }
  }

  if (!onlyCollection || onlyCollection === 'instructors') {
    await writeCollection('instructors', instructors);
  }
  if (!onlyCollection || onlyCollection === 'courses') {
    await writeCollection('courses', courses);
  }

  console.log('✅ Done.');
  process.exit(0);
})().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
