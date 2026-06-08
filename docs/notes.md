# Lecture notes

Private, per-user notes attached to a lecture. Each note can optionally
pin itself to a playback position so the user can jump back to the
moment that prompted the thought.

## Data model

```
users/{uid}/notes/{noteId}
  userId              : string     # always == {uid}
  courseId            : string
  courseTitle         : string     # denormalized at write time
  courseThumbnailUrl  : string?    # denormalized
  sectionId           : string
  lectureId           : string
  lectureTitle        : string     # denormalized
  body                : string     # 1..4000 chars
  timestampSec        : int?       # null = unpinned
  createdAt           : Timestamp
  updatedAt           : Timestamp
```

### Why store under `users/{uid}` instead of under the lecture?

1. The "My notes" page on the profile tab needs a single cross-course
   query. Putting notes under each lecture would force a
   `collectionGroup('notes').where('userId', '==', uid)` query and a
   composite index. A flat `users/{uid}/notes` is simpler.
2. Account deletion only has to clear one subcollection (already wired
   in `deleteAccount` Cloud Function).
3. The Firestore rule is one line: owner-only.

The trade-off: course / lecture metadata (title, thumbnail) is
denormalized at write time and won't propagate on a rename. We consider
that fine — notes are personal mnemonics, not search indexes.

## Playback position bus

`PlaybackPositionRegistry` is a plain singleton (exposed via Riverpod
`Provider`) that the video / audio player writes into on every
`onTick`. The "Add note" button reads it once at tap time to pre-fill
`timestampSec` on the form.

Why not a `StateProvider<int>`? The position changes every second.
Listening to it would rebuild every consumer in the lecture body
(Q&A list, downloads tile, etc.) for no visible reason. We only need
to *poll* the position at tap time, not subscribe.

The registry is keyed by `lectureId`. We don't clear stale entries on
player dispose — a small leak of "last seen position per lecture" is
fine in app memory.

## Jump-to-timestamp

Tapping a note's timestamp pill from the "My notes" page routes to the
lecture player at:

```
/courses/:id/lectures/:lectureId?at=42
```

`LecturePlayerPage` reads the `at` query parameter and passes it as
`initialPositionOverrideSec` to `_VideoBody` / `_AudioBody`, which use
it instead of the saved progress position when seeding
`initialPositionSec` on the player.

Within the lecture player body the same jump isn't wired yet — see the
inline TODO on `LectureNotesSection.onJumpTo`. Wiring it requires
either (a) a `VideoPlayerController` lifted up to the body, or (b) a
"seek bus" provider similar to the position registry. Either change
is straightforward but out of scope for this initial cut.

## Firestore rules

```
match /users/{userId}/notes/{noteId} {
  allow read, write: if isSignedIn() && uid() == userId;
}
```

Owner-only, period. No admin override — notes are private even from
moderation tools. If we ever need to support exporting a user's notes
on request, the `deleteAccount` Cloud Function template covers it.

## Account deletion

`deleteAccount` calls `deleteSubcollection(users/{uid}/notes)` as part
of step 3 (alongside wishlist).

## UI structure

- **`LectureNotesSection`** — embedded in the lecture body above the
  Q&A section. Shows up to 5 timestamped notes plus an "Add note" CTA.
- **`WriteNoteSheet`** — modal bottom sheet for create / edit flow.
  Pre-fills timestamp from the position registry on open. Clears
  timestamp via inline button if the user wants an unpinned note.
- **`NoteTile`** — renders one note: timestamp pill (tap to jump,
  when `onJump` is set), updatedAt date, body, and an overflow menu
  with Edit + Delete. Delete shows a confirmation dialog.
- **`NotesPage`** — full-screen list of every note, grouped by course
  title. Reachable from `Profile → My notes`.

## Routing

```
RouteNames.notes = 'notes'
RoutePaths.notes = 'notes'   // nested under /profile → /profile/notes
```

## i18n keys

`notesSectionHeader`, `notesAddCta`, `notesAddTitle`, `notesEditTitle`,
`notesBodyHint`, `notesNoTimestamp`, `notesClearTimestamp`,
`notesSaveNew`, `notesSaveChanges`, `notesEmptyAnonymous`,
`notesEmptyAuthenticated`, `notesMoreInProfile(count)`, `notesEdit`,
`notesDelete`, `notesCancel`, `notesDeleted`,
`notesDeleteConfirmTitle`, `notesDeleteConfirmBody`, `notesPageTitle`,
`notesProfileSubtitle`, `notesEmptyPageTitle`, `notesEmptyPageBody`.

Both `en` and `vi` are wired.

## Testing checklist

- Open a video lecture as a signed-in user, let it play 30s, tap
  "Add note", confirm the timestamp shows "00:30".
- Type a body, save → snackbar dismisses, sheet closes, new note
  appears in the section list with the correct timestamp pill.
- Type a body without letting playback advance → timestamp is "00:00"
  (the registry has that value from the first tick).
- Open the sheet, tap "Clear" on the timestamp chip, save → note
  saves with `timestampSec: null` and renders without a pill.
- From the "My notes" page (Profile → My notes), tap a note's
  timestamp pill → routes into the lecture player and the player
  starts at that position.
- Edit a note from its overflow menu → sheet pre-fills with the
  existing body + timestamp, save works.
- Delete a note → confirmation dialog, then snackbar "Note deleted",
  note vanishes from both the lecture section and the My notes page.
- Sign out → `LectureNotesSection` shows the anonymous empty state
  and hides the Add CTA.
- Run `deleteAccount` on a user with notes → all notes are gone after
  the function completes.
- Switch locale to `vi` → every visible string translates.

## Build steps

After editing `LectureNote*` files run:

```
dart run build_runner build --delete-conflicting-outputs
```

to regenerate `.freezed.dart` + `.g.dart` sidecars.
