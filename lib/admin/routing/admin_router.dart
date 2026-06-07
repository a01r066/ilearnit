import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/user_role.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../auth/admin_login_page.dart';
import '../courses/presentation/admin_courses_page.dart';
import '../courses/presentation/course_editor_page.dart';
import '../courses/presentation/instructor_my_courses_page.dart';
import '../dashboard/admin_dashboard_page.dart';
import '../instructors/presentation/admin_applications_page.dart';
import '../instructors/presentation/admin_instructors_page.dart';
import '../instructors/presentation/instructor_apply_page.dart';
import '../instructors/presentation/instructor_pending_page.dart';
import '../notifications/presentation/admin_notifications_page.dart';
import '../shared/pages/unauthorized_page.dart';
import '../learning_paths/presentation/admin_learning_paths_page.dart';
import '../learning_paths/presentation/learning_path_editor_page.dart';
import '../songbooks/presentation/admin_songbooks_page.dart';
import '../songbooks/presentation/songbook_editor_page.dart';
import '../subscriptions/presentation/admin_subscriptions_page.dart';
import '../shared/providers/admin_providers.dart';
import '../shared/widgets/admin_scaffold.dart';
import 'admin_route_names.dart';

/// go_router instance for the admin web portal.
///
/// Implements role-based redirects via the `redirect` callback:
///
/// |  Auth state           | role           | request → resolves to     |
/// |  --------------------|----------------|---------------------------|
/// |  signed out           | n/a            | `/login`                  |
/// |  signed in, suspended | (any)          | `/unauthorized`           |
/// |  signed in            | student        | `/apply` or `/pending`    |
/// |  signed in            | instructor     | `/` (dashboard)           |
/// |  signed in            | admin          | `/` (dashboard)           |
///
/// Routes restricted to admin (under `/admin/*`) are additionally gated by
/// the per-route redirect.
final adminGoRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _GoRouterRefreshStream(ref);

  return GoRouter(
    initialLocation: AdminRoutes.dashboardPath,
    refreshListenable: refresh,
    debugLogDiagnostics: false,
    redirect: (context, state) => _redirect(ref, state.matchedLocation),
    routes: [
      GoRoute(
        path: AdminRoutes.loginPath,
        name: AdminRoutes.login,
        builder: (_, __) => const AdminLoginPage(),
      ),
      GoRoute(
        path: AdminRoutes.applyPath,
        name: AdminRoutes.apply,
        builder: (_, __) => const InstructorApplyPage(),
      ),
      GoRoute(
        path: AdminRoutes.pendingPath,
        name: AdminRoutes.pending,
        builder: (_, __) => const InstructorPendingPage(),
      ),
      GoRoute(
        path: AdminRoutes.unauthorizedPath,
        name: AdminRoutes.unauthorized,
        builder: (_, __) => const UnauthorizedPage(),
      ),

      // All authenticated portal pages share the AdminScaffold (side-nav).
      ShellRoute(
        builder: (context, state, child) => AdminScaffold(child: child),
        routes: [
          GoRoute(
            path: AdminRoutes.dashboardPath,
            name: AdminRoutes.dashboard,
            builder: (_, __) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: AdminRoutes.myCoursesPath,
            name: AdminRoutes.myCourses,
            builder: (_, __) => const InstructorMyCoursesPage(),
          ),
          GoRoute(
            path: AdminRoutes.courseEditorPath,
            name: AdminRoutes.courseEditor,
            builder: (_, state) => CourseEditorPage(
              courseId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: AdminRoutes.allCoursesPath,
            name: AdminRoutes.allCourses,
            builder: (_, __) => const AdminCoursesPage(),
          ),
          GoRoute(
            path: AdminRoutes.applicationsPath,
            name: AdminRoutes.applications,
            builder: (_, __) => const AdminApplicationsPage(),
          ),
          GoRoute(
            path: AdminRoutes.instructorsPath,
            name: AdminRoutes.instructors,
            builder: (_, __) => const AdminInstructorsPage(),
          ),
          GoRoute(
            path: AdminRoutes.notificationsPath,
            name: AdminRoutes.notifications,
            builder: (_, __) => const AdminNotificationsPage(),
          ),
          GoRoute(
            path: AdminRoutes.songbooksPath,
            name: AdminRoutes.songbooks,
            builder: (_, __) => const AdminSongbooksPage(),
            routes: [
              GoRoute(
                path: ':id',
                name: AdminRoutes.songbookEditor,
                builder: (_, s) => SongbookEditorPage(
                  songbookId: s.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AdminRoutes.subscriptionsPath,
            name: AdminRoutes.subscriptions,
            builder: (_, __) => const AdminSubscriptionsPage(),
          ),
          GoRoute(
            path: AdminRoutes.learningPathsPath,
            name: AdminRoutes.learningPaths,
            builder: (_, __) => const AdminLearningPathsPage(),
            routes: [
              GoRoute(
                path: ':id',
                name: AdminRoutes.learningPathEditor,
                builder: (_, s) => LearningPathEditorPage(
                  pathId: s.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

String? _redirect(Ref ref, String location) {
  final auth = ref.read(authNotifierProvider);
  final user = ref.read(currentAdminUserProvider).value;

  final isPublic = location == AdminRoutes.loginPath ||
      location == AdminRoutes.unauthorizedPath;

  // Auth resolving — let the requested page render briefly (it's almost
  // always the login or dashboard, both safe).
  if (auth.isResolving) return null;

  if (auth.isUnauthenticated) {
    return isPublic ? null : AdminRoutes.loginPath;
  }

  // Authenticated.
  if (user == null) {
    // Profile doc still loading. Allow current route; UI will show a spinner.
    return null;
  }

  if (user.isSuspended) {
    return location == AdminRoutes.unauthorizedPath
        ? null
        : AdminRoutes.unauthorizedPath;
  }

  final role = UserRole.fromId(user.role);

  // Don't sit on /login if already signed in.
  if (location == AdminRoutes.loginPath) {
    return _landingFor(role);
  }

  switch (role) {
    case UserRole.admin:
    case UserRole.instructor:
      // Approved members: keep them out of the apply/pending pages.
      if (location == AdminRoutes.applyPath ||
          location == AdminRoutes.pendingPath) {
        return _landingFor(role);
      }
      // Admin-only routes — gate instructors out.
      if (role == UserRole.instructor && _isAdminOnly(location)) {
        return AdminRoutes.dashboardPath;
      }
      return null;
    case UserRole.student:
      // Students belong on /apply or /pending only — never the dashboard.
      if (location == AdminRoutes.applyPath ||
          location == AdminRoutes.pendingPath) {
        return null;
      }
      return AdminRoutes.applyPath;
  }
}

bool _isAdminOnly(String location) =>
    location == AdminRoutes.allCoursesPath ||
    location == AdminRoutes.applicationsPath ||
    location == AdminRoutes.instructorsPath ||
    location == AdminRoutes.notificationsPath ||
    location.startsWith(AdminRoutes.songbooksPath) ||
    location.startsWith(AdminRoutes.learningPathsPath) ||
    location == AdminRoutes.subscriptionsPath;

String _landingFor(UserRole role) {
  switch (role) {
    case UserRole.admin:
    case UserRole.instructor:
      return AdminRoutes.dashboardPath;
    case UserRole.student:
      return AdminRoutes.applyPath;
  }
}

/// Bridge Riverpod auth + role streams into go_router's [Listenable]
/// refresh hook so redirects re-evaluate whenever either changes.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Ref ref) {
    ref.listen<AuthState>(
      authNotifierProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
    ref.listen(
      currentAdminUserProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }
}
