# Admin Portal — Setup & Deploy

The admin portal is a **Flutter web target** of the same `ilearnit` codebase. It shares the same Firebase project, Firestore schemas, and `UserModel` as the mobile app — there's no second backend. The portal is just an alternate entry point (`lib/main_admin.dart`) that mounts a different `MaterialApp.router`.

## Roles

Authorization is driven by a single string field on the `users/{uid}` Firestore doc:

| `role` value | Where they go after sign-in | What they can do |
|---|---|---|
| `student` | `/apply` or `/pending` | Apply to become an instructor. Cannot reach the dashboard. |
| `instructor` | `/` (dashboard) → My Courses | Create/edit/delete **their own** courses, sections, lectures, media uploads. |
| `admin` | `/` (dashboard) | Everything an instructor can do **plus** review applications, manage all instructors, edit/delete every course. |

`isSuspended: true` on the user doc bumps the user to `/unauthorized` regardless of role.

## Architecture

```
lib/
├── main_admin.dart                 ← web entry point
├── bootstrap_admin.dart            ← Firebase init + ProviderScope
├── admin/
│   ├── admin_app.dart              ← MaterialApp.router for the portal
│   ├── routing/
│   │   ├── admin_router.dart       ← go_router + role-based redirect
│   │   └── admin_route_names.dart
│   ├── shared/
│   │   ├── providers/admin_providers.dart   ← datasources + current role
│   │   ├── widgets/admin_scaffold.dart      ← responsive side-nav shell
│   │   └── pages/unauthorized_page.dart
│   ├── auth/admin_login_page.dart
│   ├── dashboard/admin_dashboard_page.dart
│   ├── instructors/
│   │   ├── domain/entities/{application_status,instructor_application}.dart
│   │   ├── data/instructor_application_datasource.dart
│   │   └── presentation/
│   │       ├── instructor_apply_page.dart
│   │       ├── instructor_pending_page.dart
│   │       ├── admin_applications_page.dart   ← admin queue
│   │       └── admin_instructors_page.dart    ← admin manage active instructors
│   └── courses/
│       ├── data/
│       │   ├── admin_courses_datasource.dart  ← CRUD + cascade deletes
│       │   ├── admin_storage_service.dart     ← uploads w/ progress (gs:// for paid files)
│       │   └── cloudflare_upload_service.dart ← Stream direct upload / delete
│       └── presentation/
│           ├── instructor_my_courses_page.dart
│           ├── course_editor_page.dart         ← metadata + curriculum (incl. media upload)
│           └── admin_courses_page.dart         ← admin: all courses
```

The mobile app's existing `lib/features/courses/data/models/*` are reused — the wire format is identical so the consumer app reads what instructors author with zero schema drift.

## Bootstrapping the first admin

The portal will refuse to let any account in unless its `users/{uid}.role` is `instructor` or `admin`. Bootstrap your first admin manually:

1. Sign up via the mobile app (or create the user in Firebase Console → Authentication).
2. Open Firebase Console → Firestore → `users/{your-uid}` (or create the doc if missing).
3. Add field `role` (string) = `admin`. Save.
4. Open the admin portal at `/`, sign in with that account — you should land on the dashboard.

Subsequent admins can be promoted by an existing admin via the **Instructors** page (or by an admin manually setting `role: 'admin'` in Firestore — the portal doesn't expose a UI to mint new admins, intentionally).

## Firestore security rules

The source of truth is `firestore.rules` at the repo root — don't copy
snippets from docs. The parts that shape the portal:

- **users** — owners can't create themselves as anything but a
  non-suspended `student`, and can never change `role`, `isSuspended` or
  `subscription`. Only admins (the portal's Instructors / role tools)
  change roles.
- **courses** — `get`: published for everyone; any status for the
  course's instructor, admins, moderators, and buyers. `list`: queries
  must filter `status == 'published'` or `instructorId == <me>` (the
  portal's "My courses" query does; "All courses" runs as admin).
  Instructors create only `draft` courses for themselves, edit only their
  own (no admin-only fields), may only move `draft | changes_requested →
  submitted`, and may delete only drafts. `rating` / `reviewCount` are
  server-maintained.
- **sections / lectures** — public read; writes by the course's
  instructor or admins.
- **enrollments / transactions / purchases** — never written by the
  portal client; created by Cloud Functions (`verifyPurchase`,
  `processRefund`).

See `docs/security_model.md` for the full model.

## Firebase Storage rules

Source of truth: `storage.rules`. Course files are authorized with
`canManageCourse(courseId)` = admin, or an instructor who owns
`courses/{courseId}` (or the course doc doesn't exist yet, so a new
course can upload its thumbnail before the first save).

| Path | Read | Write |
|---|---|---|
| `courses/{c}/thumbnail/*` | public | `canManageCourse` + image ≤ 8 MB |
| `courses/{c}/sections/*/lectures/*/media/*` | `canManageCourse` only | `canManageCourse` + audio/video/PDF/DOC ≤ 2 GB |
| `courses/{c}/sections/*/lectures/*/resources/*` | `canManageCourse` only | `canManageCourse` + PDF/DOC/image/audio/video ≤ 200 MB |
| `songbooks/*`, `learning_paths/*` covers | public | admin |

Lecture media and resources are **paid content**: the editor stores a
`gs://bucket/path` reference (not a download URL), the
`onLectureObjectFinalized` function strips the download token, and
students receive short-lived signed URLs from `resolveLectureMedia`
(`docs/offline_downloads.md` §11). The `firestore.get(...)` in
`canManageCourse` costs one extra read per Storage write.

## Notifications in the portal

Browsers only show the notification prompt after a user gesture, so the
portal never prompts at startup. `NotificationPermissionBanner` (in the
admin scaffold) offers **Enable** until the admin decides; granting binds
the browser's FCM token to the signed-in user
(`NotificationBootstrap.requestPermissionAndBind`).

## Build & run

```bash
# Local dev (Chrome)
flutter run -d chrome -t lib/main_admin.dart --dart-define=FLAVOR=dev

# Production build
flutter build web -t lib/main_admin.dart --dart-define=FLAVOR=prod --release
# → output: build/web/
```

> **Important — no `--flavor` on web.** Flutter web actively rejects the
> `--flavor` flag (`Could not find an option named "--flavor"`). It's a
> mobile-only argument. The admin web entry reads `FLAVOR` from the
> compile-time env via `String.fromEnvironment` in `main_admin.dart`,
> so `--dart-define=FLAVOR=prod` does the same job.

## Deploy to Firebase Hosting

The repo already has Firebase Hosting wired up for the landing page (see `docs/signing_and_publishing.md`). To host the admin portal at a separate site:

1. `firebase target:apply hosting admin ilearnit-admin` (creates a target alias).
2. Add a second `hosting` entry to `firebase.json`:

   ```json
   {
     "hosting": [
       { "target": "landing", "public": "public", "rewrites": [...] },
       {
         "target": "admin",
         "public": "build/web",
         "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
         "rewrites": [{ "source": "**", "destination": "/index.html" }]
       }
     ]
   }
   ```

3. `flutter build web -t lib/main_admin.dart --dart-define=FLAVOR=prod --release`
4. `firebase deploy --only hosting:admin`

For a custom domain (e.g. `admin.ilearnit.app`):
- Firebase Console → Hosting → "admin" site → Add custom domain.
- Add the displayed `A` / `TXT` records at your DNS provider.

## v1 scope checklist

- [x] User can apply to become an instructor (`/apply`).
- [x] Application status page polls live (`/pending`).
- [x] Admin reviews + approves/rejects applications.
- [x] Approval atomically promotes `users/{uid}.role = 'instructor'`.
- [x] Instructor: list, create, edit own courses.
- [x] Instructor: edit sections + lectures + upload media (Cloudflare Stream direct upload, or private Firebase Storage objects) with progress.
- [x] Course review workflow (draft → submitted → under review → approved / changes requested → published / unpublished / archived).
- [x] Admin: list, edit, delete every course; feature/unfeature.
- [x] Admin: list active instructors, suspend/restore, revoke role.
- [x] Role-based redirects (`admin_router.dart`).
- [x] Responsive side-nav (drawer on narrow screens).
- [x] Firestore + Storage rules enforce ownership + workflow (see `docs/security_model.md`).

## Things deferred (post-v1)

- Rich text editor for course summary / lecture descriptions.
- Drag-to-reorder (lectures can be moved up/down today).
- Resumable / chunked uploads for very large video files.
- Course preview as students see it (today, instructors open the mobile app to QA).
- Analytics (enrollments / watch-time charts on the dashboard).
- Multiple admins flow (right now admins are promoted by editing Firestore by hand).
