# Lecture Progress Tracking

Implements **P0-8** from `docs/go_live_roadmap.md` — persisted per-lecture
viewing progress so the user can resume where they left off, see a per-
course completion percentage, and (eventually) earn completion certificates.

---

## 1. Data model

### Firestore paths

```
users/{uid}/courseProgress/{courseId}
              │
              ├── courseId                  string  (denormalized — equals doc id)
              ├── title                     string  (denormalized course title)
              ├── thumbnailUrl              string? (denormalized cover)
              ├── lastWatchedLectureId      string? (drives Resume CTA)
              ├── lastWatchedSectionId      string?
              ├── lastWatchedAt             timestamp
              ├── completedCount            int
              ├── totalLectures             int
              │
              └── lectures/{lectureId}
                    ├── positionSec         int     (last play-head, whole seconds)
                    ├── durationSec         int     (lecture duration as the player saw it)
                    ├── completed           bool    (true once positionSec ≥ 0.95 × durationSec)
                    └── lastWatchedAt       timestamp
```

### Why denormalize?

The Home tab's "Continue learning" rail is the highest-frequency read on
this data. A `users/{uid}/courseProgress order by lastWatchedAt desc limit
3` query has to render with title + cover. Pulling those from `courses/{id}`
would be three N+1 reads. Storing them on the rollup doc costs one extra
write per upsert but turns the rail into a single Firestore read.

The rollup is updated on **every** lecture-progress write (the same batch),
so the denormalized fields can't drift.

### Why `0.95 × duration` for completion?

Most players never reach the exact end (encoder padding, buffer cut-off,
intentional outros). A 95 % threshold ships completion roughly in line
with what users perceive as "I finished it."

---

## 2. Write path

```
Player tick (≈1 Hz)
   ↓
LectureProgressNotifier.onTick(positionSec, durationSec)
   ↓
[update in-memory state immediately]
   ↓
[throttle: at most one write per 10 s] OR [completion transition: immediate]
   ↓
LectureProgressDataSource.upsertLectureProgress(...)
   ↓
Batch:
   set users/{uid}/courseProgress/{cid}/lectures/{lid}  (merge)
   set users/{uid}/courseProgress/{cid}                 (merge + increment)
```

The rollup's `completedCount` is **only** incremented on the
non-completed → completed edge. We read the prior `completed` value before
the batch to determine this, which adds one extra read per write but
guarantees the counter never double-counts when the user rewatches a
lecture.

### Triggers

- `LecturePlayerPage` builds a `CourseMetaSnapshot` once the curriculum has
  loaded and writes it to a per-app `MetaRegistry`. The notifier reads
  from the registry on every flush, so admin edits to the course title /
  cover surface on the next write without recreating the notifier.
- `VideoLecturePlayer` adds a `VideoPlayerController` listener that emits
  on whole-second boundaries and on the playing → paused edge.
- `AudioLecturePlayer` subscribes to `just_audio`'s `positionStream` +
  `playerStateStream` and follows the same contract.
- `LectureProgressNotifier.dispose()` performs one final flush so the
  position-on-pop is captured.

---

## 3. Read paths

| Provider | Where used |
|---|---|
| `courseProgressSummaryProvider(courseId)` | Course detail — drives `CourseProgressCard` |
| `lectureProgressByCourseProvider(courseId)` | Lecture player — seeds `initialPositionSec` and (future) shows checkmarks on the curriculum |
| `continueLearningProvider(limit)` | Home — drives the "Continue learning" rail |

All three are `StreamProvider.autoDispose.family` so they tear down with
the screen and don't keep idle Firestore connections alive.

---

## 4. Throttling policy

Implemented in `LectureProgressNotifier`:

- The first tick of a fresh notifier flushes immediately so the user sees
  an early checkpoint instead of waiting 10 s for any persistence at all.
- Subsequent ticks coalesce: a single `Timer` schedules one write per 10 s
  window. Position updates within the window only mutate in-memory state.
- Completion transitions short-circuit the timer — they flush
  immediately so the rollup increments even if the user closes the page
  within the next 10 s.
- `flush()` is called on the playing → paused edge and from `dispose()`.
- All flushes are wrapped in try/catch — progress is best-effort and never
  surfaces an error to the UI.

Wall-clock budget:

```
60-minute lecture at 1 Hz player ticks
  6 writes per minute × 60 minutes = 360 raw ticks
  Throttled to 10 s / write          → 6 writes per minute
  60-min lecture                    ≈ 360 writes
  + 1 completion write              ≈ 361 writes
```

For 10 000 simultaneous viewers that's roughly 100 writes/sec
project-wide — well within Firestore's default per-write quota. If the
user base scales 10×, switch to either (a) batch upserts via a Cloud
Function that consumes a queue, or (b) the lecture-progress writes only
on pause + on every full minute (raise throttle to 60 s).

---

## 5. Security rules

```
match /users/{userId}/courseProgress/{courseId} {
  allow read, write: if isSignedIn() && uid() == userId;
  match /lectures/{lectureId} {
    allow read, write: if isSignedIn() && uid() == userId;
  }
}
```

- Owner-only by design. Even admins cannot read another user's viewing
  history — that data is private.
- No instructor-level read access either. Aggregate "how many students
  finished my course?" stats should be computed by a Cloud Function that
  writes denormalized totals to `courses/{id}.studentCompletionCount`.

Deploy with:

```bash
firebase deploy --only firestore:rules
```

---

## 6. Files added

| Path | Role |
|---|---|
| `lib/features/progress/domain/entities/lecture_progress.dart` | freezed LectureProgress |
| `lib/features/progress/domain/entities/course_progress.dart` | freezed CourseProgress + getters |
| `lib/features/progress/data/models/lecture_progress_model.dart` | freezed + JsonSerializable + TimestampConverter |
| `lib/features/progress/data/models/course_progress_model.dart` | freezed + JsonSerializable |
| `lib/features/progress/data/datasources/lecture_progress_datasource.dart` | dual-write per-lecture + rollup |
| `lib/features/progress/presentation/providers/lecture_progress_state.dart` | hand-rolled state (no freezed) |
| `lib/features/progress/presentation/providers/lecture_progress_notifier.dart` | 10s-throttled StateNotifier |
| `lib/features/progress/presentation/providers/progress_providers.dart` | Riverpod wiring + MetaRegistry |
| `lib/features/progress/presentation/widgets/course_progress_card.dart` | LinearProgressIndicator + Resume CTA |
| `lib/features/progress/presentation/widgets/continue_learning_rail.dart` | Home tab horizontal carousel |

## 7. Files changed

- `lib/features/courses/presentation/widgets/video_lecture_player.dart` —
  added `initialPositionSec`, `onTick`, `onPause`, whole-second tick
  emission.
- `lib/features/courses/presentation/widgets/audio_lecture_player.dart` —
  same callback surface, backed by just_audio's position/state streams.
- `lib/features/courses/presentation/pages/lecture_player_page.dart` —
  wires the notifier, seeds the player from saved position, registers
  course meta with the registry.
- `lib/features/courses/presentation/pages/course_detail_page.dart` —
  embeds `CourseProgressCard`, resumes BuyCourseButton to the saved
  lecture.
- `lib/features/home/presentation/pages/home_page.dart` — adds the
  `ContinueLearningRail` above the instrument grid.
- `lib/l10n/app_en.arb`, `app_vi.arb` + generated `app_localizations*.dart`
  — 5 new keys: `continueLearningTitle`, `courseProgressInProgress`,
  `courseProgressFinished`, `courseProgressResume`,
  `courseProgressUntitled`.
- `firestore.rules` — owner-only carve-out under `users/{uid}`.

## 8. Testing checklist

| Scenario | Expected |
|---|---|
| Open lecture for the first time | No initial seek; ticks start; first write within 10 s |
| Pause | Immediate flush; `lectures/{lid}.positionSec` matches |
| Close player mid-lecture | `dispose()` triggers final flush |
| Reopen the same lecture | Player seeks to saved `positionSec` |
| Reach 95 % of duration | `completed: true` written immediately; rollup `completedCount` +1 |
| Rewatch a completed lecture | `completedCount` does not double-increment |
| Open course detail with saved progress | Progress bar + Resume CTA appear |
| Tap Resume | Routes to the saved lecture, player resumes at saved position |
| Open Home with 3+ in-progress courses | Rail appears, sorted by `lastWatchedAt desc` |
| Open Home with 0 in-progress courses | Rail self-hides (no dead space) |
| Sign out + sign in as another user | Other user's progress is invisible |

## 9. Follow-up ideas (out of scope)

- Per-lecture checkmarks on the curriculum (read
  `lectureProgressByCourseProvider`).
- "Mark complete" overflow action on lecture rows (datasource already
  exposes `markLectureCompleted`).
- Completion certificate generation (Cloud Function watching the rollup
  for `completedCount == totalLectures`).
- Streak tracking (separate doc `users/{uid}/streak`).
