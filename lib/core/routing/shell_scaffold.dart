import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/mini_player/presentation/widgets/mini_player_bar.dart';

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
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.library_music_outlined,
      activeIcon: Icons.library_music_rounded,
      label: 'Courses',
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
      label: 'My learning',
    ),
    _NavItem(
      icon: Icons.account_circle_outlined,
      activeIcon: Icons.account_circle_rounded,
      label: 'Profile',
    ),
  ];

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // Tap the active tab again -> reset its stack to the root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    label: item.label,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
