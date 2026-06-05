import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/domain/entities/user_role.dart';
import '../../../features/auth/presentation/providers/auth_providers.dart';
import '../../routing/admin_route_names.dart';
import '../providers/admin_providers.dart';

/// Responsive admin shell: persistent side-nav on wide screens, drawer on
/// narrow screens. The body is the matched go_router child.
///
/// Nav items are filtered by the current user's [UserRole]:
///   - instructor: Dashboard + My Courses
///   - admin: Dashboard + My Courses + All Courses + Applications + Instructors
class AdminScaffold extends ConsumerWidget {
  const AdminScaffold({super.key, required this.child});
  final Widget child;

  static const _breakpoint = 900.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAdminUserProvider).value;
    final role = user == null ? null : UserRole.fromId(user.role);

    if (role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final wide = MediaQuery.sizeOf(context).width >= _breakpoint;
    final items = _navItemsFor(role);
    final currentPath = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _selectedIndex(items, currentPath);

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _SideNav(
              items: items,
              selectedIndex: selectedIndex,
              role: role,
              userName: user?.displayName ?? user?.email ?? '',
              onSelect: (i) => context.go(items[i].path),
              onLogout: () => _logout(context, ref),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(items[selectedIndex.clamp(0, items.length - 1)].label),
      ),
      drawer: Drawer(
        child: _SideNav(
          items: items,
          selectedIndex: selectedIndex,
          role: role,
          userName: user?.displayName ?? user?.email ?? '',
          onSelect: (i) {
            Navigator.of(context).pop();
            context.go(items[i].path);
          },
          onLogout: () => _logout(context, ref),
        ),
      ),
      body: child,
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authNotifierProvider.notifier).logout();
    if (context.mounted) context.goNamed(AdminRoutes.login);
  }

  int _selectedIndex(List<_NavItem> items, String currentPath) {
    // Match the most specific prefix.
    int best = 0;
    int bestLen = 0;
    for (var i = 0; i < items.length; i++) {
      if (currentPath.startsWith(items[i].path) &&
          items[i].path.length > bestLen) {
        best = i;
        bestLen = items[i].path.length;
      }
    }
    return best;
  }

  List<_NavItem> _navItemsFor(UserRole role) {
    return [
      const _NavItem(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        path: AdminRoutes.dashboardPath,
      ),
      const _NavItem(
        label: 'My Courses',
        icon: Icons.school_outlined,
        path: AdminRoutes.myCoursesPath,
      ),
      if (role.isAdmin) ...const [
        _NavItem(
          label: 'All Courses',
          icon: Icons.library_books_outlined,
          path: AdminRoutes.allCoursesPath,
        ),
        _NavItem(
          label: 'Applications',
          icon: Icons.assignment_ind_outlined,
          path: AdminRoutes.applicationsPath,
        ),
        _NavItem(
          label: 'Instructors',
          icon: Icons.people_outline,
          path: AdminRoutes.instructorsPath,
        ),
        _NavItem(
          label: 'Songbooks',
          icon: Icons.menu_book_outlined,
          path: AdminRoutes.songbooksPath,
        ),
        _NavItem(
          label: 'Subscriptions',
          icon: Icons.workspace_premium_outlined,
          path: AdminRoutes.subscriptionsPath,
        ),
        _NavItem(
          label: 'Notifications',
          icon: Icons.notifications_outlined,
          path: AdminRoutes.notificationsPath,
        ),
      ],
    ];
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.path,
  });
  final String label;
  final IconData icon;
  final String path;
}

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.items,
    required this.selectedIndex,
    required this.role,
    required this.userName,
    required this.onSelect,
    required this.onLogout,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final UserRole role;
  final String userName;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 260,
      child: Material(
        color: theme.colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.music_note_rounded,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'iLearnIt Admin',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            for (var i = 0; i < items.length; i++)
              _NavTile(
                item: items[i],
                selected: i == selectedIndex,
                onTap: () => onSelect(i),
              ),
            const Spacer(),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          role.isAdmin
                              ? Icons.admin_panel_settings_outlined
                              : Icons.person_outline,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              role.id.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign out'),
                    onPressed: onLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = selected ? theme.colorScheme.primary : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(item.icon, color: fg, size: 20),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
