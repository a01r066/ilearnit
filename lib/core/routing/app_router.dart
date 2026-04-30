import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/courses/presentation/pages/course_detail_page.dart';
import '../../features/courses/presentation/pages/courses_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/instructors/presentation/pages/instructor_detail_page.dart';
import '../../features/instructors/presentation/pages/instructors_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import 'route_names.dart';
import 'shell_scaffold.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _homeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _coursesKey = GlobalKey<NavigatorState>(debugLabel: 'courses');
final _instructorsKey = GlobalKey<NavigatorState>(debugLabel: 'instructors');
final _profileKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

/// Provides a [GoRouter] that redirects based on auth state.
///
/// We listen to `authNotifierProvider` so the router refreshes whenever
/// authentication changes — e.g. signing out kicks the user back to /login.
final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<AuthState>(ref.read(authNotifierProvider));
  ref.onDispose(notifier.dispose);
  ref.listen<AuthState>(
    authNotifierProvider,
    (_, next) => notifier.value = next,
  );

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = notifier.value;
      final loc = state.matchedLocation;

      final isOnAuthArea = loc == RoutePaths.login ||
          loc == RoutePaths.signup ||
          loc == RoutePaths.splash;

      return auth.maybeWhen(
        initial: () => RoutePaths.splash,
        loading: () => null,
        unauthenticated: (_) => isOnAuthArea ? null : RoutePaths.login,
        authenticated: (_) =>
            isOnAuthArea ? RoutePaths.home : null,
        orElse: () => null,
      );
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.signup,
        name: RouteNames.signup,
        builder: (_, __) => const SignupPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ShellScaffold(navigationShell: shell),
        branches: [
          // Home
          StatefulShellBranch(
            navigatorKey: _homeKey,
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: RouteNames.home,
                builder: (_, __) => const HomePage(),
              ),
            ],
          ),
          // Courses
          StatefulShellBranch(
            navigatorKey: _coursesKey,
            routes: [
              GoRoute(
                path: RoutePaths.courses,
                name: RouteNames.courses,
                builder: (_, __) => const CoursesPage(),
                routes: [
                  GoRoute(
                    path: RoutePaths.courseDetail,
                    name: RouteNames.courseDetail,
                    builder: (_, s) => CourseDetailPage(
                      courseId: s.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Instructors
          StatefulShellBranch(
            navigatorKey: _instructorsKey,
            routes: [
              GoRoute(
                path: RoutePaths.instructors,
                name: RouteNames.instructors,
                builder: (_, __) => const InstructorsPage(),
                routes: [
                  GoRoute(
                    path: RoutePaths.instructorDetail,
                    name: RouteNames.instructorDetail,
                    builder: (_, s) => InstructorDetailPage(
                      instructorId: s.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Profile
          StatefulShellBranch(
            navigatorKey: _profileKey,
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                name: RouteNames.profile,
                builder: (_, __) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});
