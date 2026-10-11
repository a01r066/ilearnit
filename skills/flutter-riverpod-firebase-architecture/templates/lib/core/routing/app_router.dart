import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/providers/core_providers.dart';

/// Bridges Riverpod auth state into GoRouter.refreshListenable.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthListenable(ref);
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = ref.read(currentUserProvider) != null;
      final loc = state.matchedLocation;
      if (signedIn && loc == '/login') {
        return state.uri.queryParameters['from'] ?? '/home';
      }
      // Guest mode: only account-bound paths require sign-in.
      if (!signedIn && _requiresAuth(loc)) {
        return Uri(path: '/login', queryParameters: {'from': state.uri.toString()}).toString();
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const Placeholder()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => _ShellScaffold(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const Placeholder()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/search', builder: (_, __) => const Placeholder()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (_, __) => const Placeholder(),
              routes: [
                GoRoute(path: 'settings', builder: (_, __) => const Placeholder()),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});

/// Everything public by default; list what needs an account.
bool _requiresAuth(String loc) {
  const protectedPrefixes = ['/profile/', '/purchases', '/notes'];
  return protectedPrefixes.any(loc.startsWith);
}

class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          // Labels come from context.l10n in a real app.
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
