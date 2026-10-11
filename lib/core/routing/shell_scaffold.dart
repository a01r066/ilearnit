import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/mini_player/presentation/widgets/mini_player_bar.dart';
import '../../features/moderation/eula/eula_reacceptance_gate.dart';
import '../../l10n/l10n.dart';

/// The bottom-nav scaffold that wraps the four primary tabs.
///
/// Used by [StatefulShellRoute.indexedStack] so each tab keeps its own
/// navigation stack while switching.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = <_NavItem>[
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      labelOf: _home,
    ),
    _NavItem(
      icon: Icons.library_music_outlined,
      activeIcon: Icons.library_music_rounded,
      labelOf: _courses,
    ),
    // Instructors tab moved out of the bottom nav per product request —
    // /instructors + /instructors/:id remain reachable by deep link
    // (course detail → instructor name → push), just not from the
    // bottom nav. Same pattern Songbooks already uses.
    //
    // My learning replaces it as the primary mid-nav destination.
    _NavItem(
      icon: Icons.play_circle_outline,
      activeIcon: Icons.play_circle_rounded,
      labelOf: _myLearning,
    ),
    _NavItem(
      icon: Icons.account_circle_outlined,
      activeIcon: Icons.account_circle_rounded,
      labelOf: _profile,
    ),
  ];

  static String _home(AppLocalizations t) => t.navHome;
  static String _courses(AppLocalizations t) => t.navCourses;
  static String _myLearning(AppLocalizations t) => t.navMyLearning;
  static String _profile(AppLocalizations t) => t.navProfile;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // Tap the active tab again -> reset its stack to the root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return EulaReacceptanceGate(
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Persistent mini-player above the bottom nav. Self-hides
          // when nothing is loaded. See lib/features/mini_player.
          const MiniPlayerBar(),
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onTap,
            destinations: _items
                .map(
                  (item) => NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.activeIcon),
                    label: item.labelOf(context.l10n),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.labelOf,
  });
  final IconData icon;
  final IconData activeIcon;
  final String Function(AppLocalizations) labelOf;
}
