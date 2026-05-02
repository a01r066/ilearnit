# Sample Firestore data

Seed data for the iLearnIt project: **10 instructors** and **100 courses**
spread across guitar (35) / piano (35) / violin (30).

## Files

| File                  | Purpose                                              |
| --------------------- | ---------------------------------------------------- |
| `instructors.json`    | Map keyed by doc id. Goes into `instructors/`.       |
| `courses.json`        | Map keyed by doc id. Goes into `courses/`.           |
| `seed_firestore.js`   | Node.js seeder (Admin SDK, batched writes).          |
| `package.json`        | Just for `firebase-admin` and convenience scripts.   |
| `generate_seed.py`    | (Optional) regenerator — produces both JSON files.   |

Timestamps in JSON are stored as ISO strings (e.g. `2025-08-01T22:26:08.000Z`).
The seed script converts any field named `publishedAt`, `createdAt`, or
`joinedAt` to a Firestore `Timestamp` automatically.

## Seed via Firebase Admin SDK (recommended)

### One-time setup

```bash
cd sample_data
npm install                 # pulls firebase-admin
```

Provide a service account key — either:

**Option A** — environment variable (cleanest):
```bash
export GOOGLE_APPLICATION_CREDENTIALS=/abs/path/to/key-dev.json
```

**Option B** — drop the key file next to the script:
```
sample_data/service-account.dev.json
sample_data/service-account.prod.json
```
The script picks up the right one based on `--flavor`. Both filenames are in
`.gitignore`.

> Get a service-account key at:
> Firebase Console → Project settings → Service accounts → Generate new private key.

### Run

```bash
npm run seed:dev            # writes to ilearnit-dev
npm run seed:prod           # writes to ilearnit-31f41 (prod)

npm run seed:dev:dry        # logs only, writes nothing
npm run seed:dev:wipe       # deletes existing courses + instructors first
```

Or call the script directly with any combination:

```bash
node seed_firestore.js --flavor dev
node seed_firestore.js --flavor dev --wipe
node seed_firestore.js --flavor dev --only=courses
node seed_firestore.js --flavor dev --dry
```

Batched writes (400 docs/batch) keep you under Firestore's 500-op batch
limit and well below the 1 MB request cap.

## Seed via Firebase Local Emulator

If you'd rather populate the emulator than touch a real project:

```bash
# 1. Start the emulator (in repo root)
firebase emulators:start --only firestore

# 2. Tell the seed script to talk to the emulator
export FIRESTORE_EMULATOR_HOST=localhost:8080
export GCLOUD_PROJECT=ilearnit-dev          # any project id works locally
node seed_firestore.js --flavor dev
```

The Admin SDK respects `FIRESTORE_EMULATOR_HOST` — no code change needed.

## Schema (matches `CourseModel` and the planned `InstructorModel`)

### `instructors/{id}`
```ts
{
  id: string,
  name: string,
  primaryInstrument: 'guitar' | 'piano' | 'violin',
  bio: string,
  specialties: string[],
  yearsExperience: number,
  country: string,
  photoUrl: string,
  rating: number,         // 0–5
  studentCount: number,
  joinedAt: Timestamp,
  featuredCourseIds: string[],
}
```

### `courses/{id}`
```ts
{
  id: string,
  title: string,
  summary: string,
  thumbnailUrl: string,
  category: 'guitar' | 'piano' | 'violin',
  level: 'beginner' | 'intermediate' | 'advanced',
  instructorId: string,                 // -> instructors/{id}
  instructorName: string,               // denormalized for list rendering
  lessonCount: number,
  enrollmentCount: number,
  rating: number,                       // 0–5
  durationMinutes: number,
  isFeatured: boolean,
  tags: string[],
  publishedAt: Timestamp,
}
```

The Flutter app's `CoursesRepositoryImpl.fetchFeatured()` queries
`where('isFeatured', isEqualTo: true)` — composite index on
`(isFeatured, publishedAt desc)` is recommended.

## Regenerating

The data is reproducible; the Python generator uses a fixed seed
(`random.seed(20260502)`).

```bash
python3 generate_seed.py
```

This rewrites `instructors.json` and `courses.json` deterministically.
