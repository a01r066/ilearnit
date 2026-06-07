import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ilearnit/features/profile/presentation/pages/settings_page.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../notifications/presentation/pages/notification_preferences_page.dart';
import '../notifications/presentation/pages/notifications_inbox_page.dart';
import '../../features/courses/presentation/pages/course_detail_page.dart';
import '../../features/courses/presentation/pages/courses_page.dart';
import '../../features/courses/presentation/pages/lecture_player_page.dart';
import '../../features/downloads/presentation/pages/downloads_page.dart';
import '../../features/wishlist/presentation/pages/wishlist_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/instructors/presentation/pages/instructor_detail_page.dart';
import '../../features/instructors/presentation/pages/instructors_page.dart';
import '../../features/legal/presentation/pages/legal_document_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/delete_account_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/songbooks/presentation/pages/songbook_detail_page.dart';
import '../../features/songbooks/presentation/pages/songbooks_page.dart';
import '../../features/subscriptions/presentation/pages/subscription_checkout_page.dart';
import '../../features/subscriptions/presentation/pages/subscription_page.dart';
import '../../shared/providers/storage_providers.dart';
import 'route_names.dart';
import 'shell_scaffold.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _homeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _coursesKey = GlobalKey<NavigatorState>(debugLabel: 'courses');
final _instructorsKey = GlobalKey<NavigatorState>(debugLabel: 'instructors');
final _songbooksKey = GlobalKey<NavigatorState>(debugLabel: 'songbooks');
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
  // Cached PrefsService reference — same instance used by every redirect
  // tick. `onboardingDone` is read synchronously off SharedPreferences.
  final prefs = ref.read(prefsProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = notifier.value;
      final loc = state.matchedLocation;

      final isOnSplash = loc == RoutePaths.splash;
      final isOnLoginOrSignup =
          loc == RoutePaths.login || loc == RoutePaths.signup;
      final isOnOnboarding = loc == RoutePaths.onboarding;

      // 1. Auth not yet resolved — keep showing splash, but do not
      //    push splash on every redirect (avoids loops).
      if (auth.isResolving) {
        return isOnSplash ? null : RoutePaths.splash;
      }

      // 2. Signed in.
      if (auth.isAuthenticated) {
        // Gate the entire shell behind onboarding for first-time installs.
        if (!prefs.onboardingDone) {
          return isOnOnboarding ? null : RoutePaths.onboarding;
        }
        // Onboarding is one-shot — once done, kick out of /onboarding.
        if (isOnOnboarding ||
            isOnSplash ||
            isOnLoginOrSignup) {
          return RoutePaths.home;
        }
        return null;
      }

      // 3. Signed out — login, signup, and legal pages are reachable.
      final isOnLegal = loc.startsWith('/legal/');
      if (isOnLoginOrSignup || isOnLegal) return null;
      return RoutePaths.login;
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
      // Onboarding — top-level so it can replace the shell during the
      // first-run flow. The redirect above gates it behind auth +
      // `!prefs.onboardingDone`.
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(
        path: RoutePaths.search,
        name: RouteNames.search,
        // Push above the shell so the bottom nav isn't visible during
        // search — mirrors the attached design (full-screen search).
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SearchPage(),
      ),
      // ----- Notifications inbox ----------------------------------------
      // Top-level so the bell on every shell tab pushes the same modal-
      // style page (consistent back behaviour).
      GoRoute(
        path: RoutePaths.notificationsInbox,
        name: RouteNames.notificationsInbox,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const NotificationsInboxPage(),
      ),
      // ----- Legal (privacy / terms) ------------------------------------
      // Reachable from auth + profile + checkout. Routed top-level so the
      // sign-up / login pages (outside the shell) can push it.
      GoRoute(
        path: RoutePaths.legal,
        name: RouteNames.legal,
        parentNavigatorKey: _rootKey,
        builder: (_, state) {
          final slug = state.pathParameters['slug'] ?? '';
          final doc = LegalDocument.fromSlug(slug) ??
              LegalDocument.privacyPolicy;
          return LegalDocumentPage(document: doc);
        },
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
                    routes: [
                      GoRoute(
                        path: RoutePaths.lecturePlayer,
                        name: RouteNames.lecturePlayer,
                        builder: (_, s) => LecturePlayerPage(
                          courseId: s.pathParameters['id']!,
                          lectureId: s.pathParameters['lectureId']!,
                        ),
                      ),
                    ],
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
          // Songbooks
          StatefulShellBranch(
            navigatorKey: _songbooksKey,
            routes: [
              GoRoute(
                path: RoutePaths.songbooks,
                name: RouteNames.songbooks,
                builder: (_, __) => const SongbooksPage(),
                routes: [
                  GoRoute(
                    path: RoutePaths.songbookDetail,
                    name: RouteNames.songbookDetail,
                    builder: (_, s) => SongbookDetailPage(
                      id: s.pathParameters['id']!,
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
                routes: [
                  GoRoute(
                    path: RoutePaths.settings,
                    name: RouteNames.setting,
                    builder: (_, __) => SettingsPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.deleteAccount,
                    name: RouteNames.deleteAccount,
                    builder: (_, __) => const DeleteAccountPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.notificationPreferences,
                    name: RouteNames.notificationPreferences,
                    builder: (_, __) =>
                        const NotificationPreferencesPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.downloads,
                    name: RouteNames.downloads,
                    builder: (_, __) => const DownloadsPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.wishlist,
                    name: RouteNames.wishlist,
                    builder: (_, __) => const WishlistPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.subscription,
                    name: RouteNames.subscription,
                    builder: (_, __) => const SubscriptionPage(),
                    routes: [
                      GoRoute(
                        path: RoutePaths.subscriptionCheckout,
                        name: RouteNames.subscriptionCheckout,
                        builder: (_, __) => const SubscriptionCheckoutPage(),
                      ),
                    ],
                  ),
                ],
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
