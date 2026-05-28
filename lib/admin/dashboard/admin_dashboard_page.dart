import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/user_role.dart';
import '../routing/admin_route_names.dart';
import '../shared/providers/admin_providers.dart';

/// Landing page after sign-in. Shows quick stats + role-appropriate
/// shortcuts.
class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAdminUserProvider).value;
    final role = user == null ? UserRole.student : UserRole.fromId(user.role);
    final theme = Theme.of(context);

    final myCoursesStream = user == null
        ? null
        : ref.watch(adminCoursesDataSourceProvider).watchMyCourses(user.id);

    final allCoursesStream = role.isAdmin
        ? ref.watch(adminCoursesDataSourceProvider).watchAllCourses()
        : null;

    final pendingApplicationsStream = role.isAdmin
        ? ref
            .watch(instructorApplicationDataSourceProvider)
            .watchPending()
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome, ${user?.displayName ?? user?.email ?? "instructor"}',
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            role.isAdmin
                ? 'Manage every course, instructor, and pending application.'
                : 'Author your own courses below.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              if (myCoursesStream != null)
                _StatTile(
                  label: 'My courses',
                  icon: Icons.school_outlined,
                  stream: myCoursesStream.map((l) => l.length),
                  onTap: () =>
                      context.goNamed(AdminRoutes.myCourses),
                ),
              if (allCoursesStream != null)
                _StatTile(
                  label: 'All courses',
                  icon: Icons.library_books_outlined,
                  stream: allCoursesStream.map((l) => l.length),
                  onTap: () =>
                      context.goNamed(AdminRoutes.allCourses),
                ),
              if (pendingApplicationsStream != null)
                _StatTile(
                  label: 'Pending applications',
                  icon: Icons.assignment_ind_outlined,
                  stream: pendingApplicationsStream.map((l) => l.length),
                  onTap: () =>
                      context.goNamed(AdminRoutes.applications),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.icon,
    required this.stream,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Stream<int> stream;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 220,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                StreamBuilder<int>(
                  stream: stream,
                  builder: (_, snap) {
                    final n = snap.data;
                    return Text(
                      n == null ? '—' : n.toString(),
                      style: theme.textTheme.displaySmall,
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
