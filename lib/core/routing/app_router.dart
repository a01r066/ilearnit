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
import '../../features/learning_paths/presentation/pages/learning_path_detail_page.dart';
import '../../features/notes/presentation/pages/notes_page.dart';
import '../../features/progress/presentation/pages/my_learning_page.dart';
import '../../features/practice/presentation/pages/practice_page.dart';
import '../../features/qa/presentation/pages/question_thread_page.dart';
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
import '../observability/observability_providers.dart';
import 'route_names.dart';
import 'shell_scaffold.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _homeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _coursesKey = GlobalKey<NavigatorState>(debugLabel: 'courses');
final _instructorsKey = GlobalKey<NavigatorState>(debugLabel: 'instructors');
final _myLearningKey = GlobalKey<NavigatorState>(debugLabel: 'myLearning');
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

  // Auto `screen_view` events. The observer reads route names off
  // each pushed `Page`, so every named `GoRoute` lands in Analytics
  // without per-page wiring.
  final analyticsObserver = ref.read(firebaseAnalyticsObserverProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    observers: [analyticsObserver],
    redirect: (context, state) {
      final auth = notifier.value;
      final loc = state.matchedLocation;

      final isOnSplash = loc == RoutePaths.splash;
      final isOnLoginOrSignup =
          loc == RoutePaths.login || loc == RoutePaths.signup;
      final isOnOnboarding = loc == RoutePaths.onboarding;
      // Legal pages are reachable anywhere in the flow — they're the
      // privacy / terms screens linked from the sign-in footer.
      final isOnLegal = loc.startsWith('/legal/');

      // 1. Auth still resolving — show splash. Don't re-push splash if
      //    we're already on it (loop protection).
      if (auth.isResolving) {
        return isOnSplash ? null : RoutePaths.splash;
      }

      // 2. First-run onboarding precedes everything else — runs for
      //    BOTH guests and signed-in users when prefs.onboardingDone
      //    is false. The flow is:
      //       Splash → Onboarding → Login (skippable) → Home
      //    so a brand-new install sees the picker steps before any
      //    auth prompt. Allow legal pages through so the footer links
      //    on the onboarding screens still work.
      if (!prefs.onboardingDone) {
        if (isOnOnboarding || isOnLegal) return null;
        return RoutePaths.onboarding;
      }

      // 3. Signed in — kick out of pre-shell screens (splash / login /
      //    signup / onboarding) and land on Home.
      if (auth.isAuthenticated) {
        if (isOnOnboarding ||
            isOnSplash ||
            isOnLoginOrSignup) {
          return RoutePaths.home;
        }
        return null;
      }

      // 4. Guest (signed out, onboarding done).
      //
      // After completing onboarding the next stop is /login. The
      // Login page exposes a "Continue as guest" CTA that pushes to
      // /home — once on /home, the per-user-route allow-list below
      // gates only routes that need a uid (subscription, wishlist,
      // notes, …). Everything else stays guest-reachable.
      //
      // Splash never sticks for a returning guest — it bounces to
      // /login so they get the "Sign in or skip" entry point.
      if (isOnSplash) return RoutePaths.login;
      if (_requiresAuth(loc)) return RoutePaths.login;
      return null;
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
      // ----- Learning path detail ---------------------------------------
      // Top-level so the Home rail + the (future) course-detail link
      // both push the same screen.
      GoRoute(
        path: RoutePaths.learningPathDetail,
        name: RouteNames.learningPathDetail,
        parentNavigatorKey: _rootKey,
        builder: (_, state) => LearningPathDetailPage(
          pathId: state.pathParameters['id']!,
        ),
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
      // ----- Songbooks (no longer a bottom-nav tab) ---------------------
      // Kept reachable by direct URL + search deep-links. Pushed above
      // the shell so the bottom nav doesn't render — feels consistent
      // with /learning-paths/:id and /notifications which behave the
      // same way.
      GoRoute(
        path: RoutePaths.songbooks,
        name: RouteNames.songbooks,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SongbooksPage(),
        routes: [
          GoRoute(
            path: RoutePaths.songbookDetail,
            name: RouteNames.songbookDetail,
            parentNavigatorKey: _rootKey,
            builder: (_, s) => SongbookDetailPage(
              id: s.pathParameters['id']!,
            ),
          ),
        ],
      ),
      // ----- Instructors (no longer a bottom-nav tab) -------------------
      // Same pattern as Songbooks. Course detail and search both still
      // deep-link into instructor profiles; the bottom-nav slot was
      // claimed by My learning.
      GoRoute(
        path: RoutePaths.instructors,
        name: RouteNames.instructors,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const InstructorsPage(),
        routes: [
          GoRoute(
            path: RoutePaths.instructorDetail,
            name: RouteNames.instructorDetail,
            parentNavigatorKey: _rootKey,
            builder: (_, s) => InstructorDetailPage(
              instructorId: s.pathParameters['id']!,
            ),
          ),
        ],
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
                          initialPositionSec: int.tryParse(
                            s.uri.queryParameters['at'] ?? '',
                          ),
                        ),
                        routes: [
                          GoRoute(
                            path: RoutePaths.questionThread,
                            name: RouteNames.questionThread,
                            builder: (_, s) => QuestionThreadPage(
                              courseId: s.pathParameters['id']!,
                              lectureId:
                                  s.pathParameters['lectureId']!,
                              questionId:
                                  s.pathParameters['questionId']!,
                              // sectionId is needed to find the right
                              // Firestore subpath. Passed via query so
                              // bookmarkable URLs still work.
                              sectionId:
                                  s.uri.queryParameters['sectionId'] ??
                                      '',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // My learning — replaces the Instructors branch in the
          // bottom nav. Per the screenshot reference + product
          // request. /instructors + /instructors/:id are re-registered
          // ABOVE the shell so they stay reachable as deep-links
          // (course detail → instructor name still pushes), same
          // pattern Songbooks already uses.
          StatefulShellBranch(
            navigatorKey: _myLearningKey,
            routes: [
              GoRoute(
                path: '/my-learning',
                name: RouteNames.myLearning,
                builder: (_, __) => const MyLearningPage(),
              ),
            ],
          ),
          // Songbooks tab removed from the bottom nav (see
          // shell_scaffold.dart for context). The /songbooks +
          // /songbooks/:id routes are re-registered ABOVE the shell
          // below so direct URL access + search-result deep-links
          // still work — they just open without the bottom nav, like
          // /learning-paths/:id and /notifications already do.
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
                    path: RoutePaths.practice,
                    name: RouteNames.practice,
                    builder: (_, __) => const PracticePage(),
                  ),
                  GoRoute(
                    path: RoutePaths.notes,
                    name: RouteNames.notes,
                    builder: (_, __) => const NotesPage(),
                  ),
                  // My learning moved to a bottom-nav branch at
                  // `/my-learning`. The route name + page are unchanged;
                  // only the path moved. Profile no longer hosts it.
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

/// Routes that require a signed-in user even in guest-browse mode.
///
/// Everything not listed here is reachable by guests. The criterion
/// is "does this page write to or read from `users/{uid}`?":
///   • Subscription + checkout — writes `users/{uid}.subscription`.
///   • Wishlist — reads/writes `users/{uid}/wishlist/{courseId}`.
///   • Notes — reads/writes `users/{uid}/notes/{noteId}`.
///   • Notification preferences — reads/writes
///     `users/{uid}.subscribedTopics` + FCM token bindings.
///   • Delete account — destroys the user record.
///
/// The Downloads page is intentionally NOT here — downloads live in
/// per-device storage with no Firestore footprint, so a guest can
/// browse the (empty) downloads page without an account.
///
/// Action-level gates (buttons inside browse pages — BuyCourseButton,
/// BookmarkButton, "Ask a question", "Write a review", "Add note")
/// still need to detect `currentUser == null` and bounce the user to
/// `/login` on tap. The router gate only catches direct URL access.
bool _requiresAuth(String loc) {
  // Anything under /profile/* except /profile itself.
  const protected = <String>{
    '/profile/subscription',
    '/profile/subscription/checkout',
    '/profile/wishlist',
    '/profile/notes',
    '/profile/delete-account',
    '/profile/settings/notifications',
    // My learning is a top-level bottom-nav tab now. It's user-bound
    // (reads users/{uid}/courseProgress) so guests hitting the tab
    // get bounced to /login.
    '/my-learning',
  };
  if (protected.contains(loc)) return true;
  // Notifications inbox is per-user.
  if (loc == '/notifications') return true;
  return false;
}
