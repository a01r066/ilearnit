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
│       │   ├── admin_courses_datasource.dart  ← CRUD on courses/sections/lectures
│       │   └── admin_storage_service.dart     ← uploads w/ progress
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

Add these to `firestore.rules`. They enforce role and ownership checks server-side so the rules are the source of truth, not the UI.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ---------- helpers ----------
    function isSignedIn() { return request.auth != null; }
    function uid() { return request.auth.uid; }

    function userDoc() {
      return get(/databases/$(database)/documents/users/$(uid())).data;
    }
    function role() {
      return userDoc().role;
    }
    function isAdmin() {
      return isSignedIn() && role() == 'admin' && userDoc().isSuspended != true;
    }
    function isInstructor() {
      return isSignedIn() && (role() == 'instructor' || role() == 'admin')
             && userDoc().isSuspended != true;
    }

    // ---------- users ----------
    match /users/{userId} {
      // Anyone signed-in can read their own doc; admins can read all.
      allow read: if isSignedIn() && (uid() == userId || isAdmin());
      // Users can write their own profile fields except role + isSuspended.
      allow create: if isSignedIn() && uid() == userId;
      allow update: if isSignedIn()
        && uid() == userId
        && !(request.resource.data.diff(resource.data).affectedKeys()
              .hasAny(['role', 'isSuspended']));
      // Admins can update anything on any user (including role + suspend).
      allow update: if isAdmin();
      allow delete: if isAdmin();
    }

    // ---------- instructor applications ----------
    match /instructor_applications/{userId} {
      allow read: if isSignedIn() && (uid() == userId || isAdmin());
      // Applicant can create / overwrite (re-apply) their own pending app.
      allow create, update: if isSignedIn() && uid() == userId
        && request.resource.data.status == 'pending';
      // Only admins can mark approved / rejected.
      allow update: if isAdmin();
      allow delete: if isAdmin();
    }

    // ---------- courses ----------
    match /courses/{courseId} {
      // Anyone (signed in or not) can read published courses.
      allow read: if true;
      // Instructors create their own; admins create on behalf of anyone.
      allow create: if isInstructor()
        && (isAdmin() || request.resource.data.instructorId == uid());
      // Owner or admin can update / delete.
      allow update, delete: if isAdmin()
        || (isInstructor() && resource.data.instructorId == uid());

      match /sections/{sectionId} {
        allow read: if true;
        allow write: if isAdmin()
          || (isInstructor()
              && get(/databases/$(database)/documents/courses/$(courseId))
                   .data.instructorId == uid());

        match /lectures/{lectureId} {
          allow read: if true;
          allow write: if isAdmin()
            || (isInstructor()
                && get(/databases/$(database)/documents/courses/$(courseId))
                     .data.instructorId == uid());
        }
      }
    }
  }
}
```

## Firebase Storage rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    function isSignedIn() { return request.auth != null; }
    function uid() { return request.auth.uid; }
    function userDoc() {
      return firestore.get(/databases/(default)/documents/users/$(uid())).data;
    }
    function isAdmin() {
      return isSignedIn() && userDoc().role == 'admin'
             && userDoc().isSuspended != true;
    }
    function ownsCourse(courseId) {
      return isAdmin() || firestore.get(
        /databases/(default)/documents/courses/$(courseId)
      ).data.instructorId == uid();
    }

    // Course thumbnails + lecture media.
    match /courses/{courseId}/{allPaths=**} {
      allow read: if true; // public — adjust if courses should be gated
      allow write: if ownsCourse(courseId);
    }
  }
}
```

> The Storage rule uses `firestore.get(...)` to cross-reference the user role. This costs an extra Firestore read per write but is the standard pattern for role-based Storage gating. If you need higher throughput, encode `instructorId` into the path (e.g. `courses/{instructorId}/{courseId}/...`) and authorize by uid match alone — but you'll have to rename the buckets if a course changes owners.

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
- [x] Instructor: edit sections + lectures + upload media to Firebase Storage with progress.
- [x] Admin: list, edit, delete every course; feature/unfeature.
- [x] Admin: list active instructors, suspend/restore, revoke role.
- [x] Role-based redirects (`admin_router.dart`).
- [x] Responsive side-nav (drawer on narrow screens).
- [x] Firestore + Storage security rule samples.

## Things deferred (post-v1)

- Rich text editor for course summary / lecture descriptions.
- Drag-to-reorder sections + lectures (UI sketched, mutation TBD).
- Resumable / chunked uploads for very large video files.
- Course preview as students see it (today, instructors open the mobile app to QA).
- Analytics (enrollments / watch-time charts on the dashboard).
- Multiple admins flow (right now admins are promoted by editing Firestore by hand).
