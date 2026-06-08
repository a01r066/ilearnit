# Course Q&A

Per-lecture comment threads where learners ask questions and instructors
reply. The reply trail is locked to a single nested level — replies don't
have replies — to keep moderation simple and the UI flat.

## Data model

```
courses/{courseId}/
  sections/{sectionId}/
    lectures/{lectureId}/
      questions/{questionId}
        userId            : string           // author uid
        userName          : string           // denormalized at write time
        userPhotoUrl      : string?
        body              : string           // 5..2000 chars (rule-enforced)
        createdAt         : Timestamp
        updatedAt         : Timestamp
        replyCount        : int              // FieldValue.increment aggregator
        isInstructorAnswered : bool          // one-shot flag

        replies/{replyId}
          userId          : string
          userName        : string
          userPhotoUrl    : string?
          body            : string           // 1..2000 chars
          createdAt       : Timestamp
          updatedAt       : Timestamp
          isInstructor    : bool             // denormalized verified badge
```

### Why denormalize `isInstructor` on the reply

The verified-instructor badge is computed at write time and stored on
the reply. This means:

1. The badge survives an instructor losing their role — useful when an
   instructor leaves a platform mid-thread; their old replies stay
   verified.
2. The reply-list UI doesn't have to cross-query the user doc on every
   render to colour the badge.
3. Firestore rules can enforce that only the actual course instructor
   (or an admin) may write `isInstructor: true`. The denorm is therefore
   non-forgeable.

### Aggregator strategy

`replyCount` is bumped via `FieldValue.increment(1)` in the same batch as
the reply write. We rely on the increment being atomic on the Firestore
side; no client-side recompute is needed (contrast `courses.reviewCount`,
which rolls up via a full re-scan).

`isInstructorAnswered` is a *one-shot* flag — it flips to `true` the
moment an instructor replies, and we deliberately do NOT reset it when
the last instructor reply is deleted. The flag is meant to drive a
"✅ Answered by instructor" badge on the question list, not be a
real-time mirror of the reply set. Resetting on delete would create a
score-chase incentive for instructors to delete and re-post.

## Cloud Function: `onCourseQuestionCreated`

Fires on `courses/{cid}/sections/{sid}/lectures/{lid}/questions/{qid}`
create. Reads the course's `instructorId`, then DMs the instructor with:

- title: `New question on {courseTitle}`
- body:  `{authorName}: {first 140 chars of question body}`
- deep-link route: `/courses/{cid}/lectures/{lid}/qa/{qid}?sectionId={sid}`

The function no-ops when:

- The course doc is missing or has no `instructorId`
- The question's author *is* the instructor (rare, but happens during
  instructor self-testing)

The notification goes through the shared `notifyUser` helper, which
sends an FCM push and mirrors a row into the instructor's
`users/{uid}/notifications/` inbox.

## Firestore rules summary

```
courses/{cid}/sections/{sid}/lectures/{lid}/questions/{qid}
  read   : public
  create : signed in && userId == uid && 5 <= len(body) <= 2000
  update : (own + only body/updatedAt) || (only replyCount/isInstructorAnswered)
  delete : own || course instructor || admin

  replies/{rid}
    read   : public
    create : signed in && userId == uid && 1 <= len(body) <= 2000
             && (isInstructor == false || writer IS course instructor || admin)
    update : own + only body/updatedAt
    delete : own || course instructor || admin
```

The `isInstructor == false || writer IS course instructor || admin`
carve-out is critical — it prevents a student from spoofing the verified
badge via direct Firestore writes.

The `replyCount / isInstructorAnswered` carve-out allows any signed-in
user to bump the aggregator counters as part of a reply submission. We
can't actually validate that they bumped by `±1` (rules don't see
field values pre-`increment`), so we trust the client. Worst case: a
malicious user inflates `replyCount` — but they'd need to also write a
valid reply doc, so the damage is bounded.

## UI structure

`LectureQASection` — compact panel embedded in `_LectureBody` (the video
+ audio player bodies). Shows up to 3 latest questions plus an
"Ask a question" CTA and "See all N" link.

`WriteQuestionSheet.show(context, qaKey: …)` — modal bottom sheet for
posting a new question. Returns the new question id so the caller can
deep-link straight to the thread.

`QuestionThreadPage` — full screen. Question card at top, scrollable
reply list, sticky composer at bottom. Resolves
`isInstructorOfCourse` by comparing the viewer's uid against the
course's `instructorId` from `courseByIdProvider`, then captures that
flag in the `ReplyFormKey` so the reply submission stamps it
correctly.

`VerifiedInstructorBadge` — pill component used in two modes:
`compact: true` for inline use on the question list, default for the
thread.

## i18n keys

`qaSectionHeader`, `qaAsk`, `qaAskTitle`, `qaQuestionLabel`,
`qaQuestionHint`, `qaPostQuestion`, `qaEmptyAnonymous`,
`qaEmptyAuthenticated`, `qaSeeAll(count)`, `qaReplyCount(count)`,
`qaThreadTitle`, `qaThreadMissing`, `qaReplies`, `qaNoRepliesYet`,
`qaAnonymous`, `qaReplyHint`, `qaSend`, `qaVerifiedInstructor`.

Both `en` and `vi` are wired. The plural form on `qaReplyCount` uses
the standard `=0/=1/other` triplet.

## Routing

Top-level lecture player route is unchanged:

```
/courses/:id/lectures/:lectureId
```

The thread is nested under it:

```
/courses/:id/lectures/:lectureId/qa/:questionId?sectionId=...
```

`sectionId` rides as a query parameter rather than a path segment so the
public URL stays short and shareable. The page reads it via
`state.uri.queryParameters['sectionId']`.

## Testing checklist

- Post a question as a student → instructor receives a push within ~3s
  and an inbox row appears in `users/{instructorUid}/notifications/`.
- Tap the inbox row → app deep-links into `QuestionThreadPage` with the
  correct course/section/lecture/question ids.
- Instructor replies → `_ReplyTile` shows `VerifiedInstructorBadge`,
  parent question's `isInstructorAnswered` flips to `true`.
- Student replies → no badge, `replyCount` bumps by 1.
- Student deletes their own question → reply docs cascade-delete (up to
  200 — anything beyond that requires a second call), question doc is
  gone.
- Attempt to write a reply with `isInstructor: true` while signed in as
  a regular student → Firestore rules reject with PERMISSION_DENIED.
- Sign out → `LectureQASection` shows `qaEmptyAnonymous` and the "Ask"
  CTA is hidden.
- Switch device locale to `vi` → all visible strings translate.
