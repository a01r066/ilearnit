import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/presentation/providers/auth_providers.dart';
import '../../routing/admin_route_names.dart';
import '../../shared/providers/admin_providers.dart';
import '../domain/entities/application_status.dart';

/// Holding page for users whose application is pending or was rejected.
///
/// Live-binds to the application doc; the moment an admin approves the
/// `users/{uid}.role` flip will be picked up by the router's redirect and
/// the user lands on the dashboard automatically.
class InstructorPendingPage extends ConsumerWidget {
  const InstructorPendingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final appStream =
        ref.watch(instructorApplicationDataSourceProvider).watchMine(user.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application status'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.goNamed(AdminRoutes.login);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: StreamBuilder(
            stream: appStream,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const CircularProgressIndicator();
              }
              final app = snap.data;
              if (app == null) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('No application yet',
                          style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Apply to become an instructor and start authoring '
                        'courses.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => context.goNamed(AdminRoutes.apply),
                        child: const Text('Apply now'),
                      ),
                    ],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      _icon(app.status),
                      size: 56,
                      color: _color(theme, app.status),
                    ),
                    const SizedBox(height: 12),
                    Text(_title(app.status),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(_subtitle(app.status, app.rejectionReason),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium),
                    if (app.status == ApplicationStatus.rejected) ...[
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => context.goNamed(AdminRoutes.apply),
                        child: const Text('Re-apply'),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  IconData _icon(ApplicationStatus s) {
    switch (s) {
      case ApplicationStatus.pending:
        return Icons.hourglass_top_rounded;
      case ApplicationStatus.approved:
        return Icons.check_circle_outline;
      case ApplicationStatus.rejected:
        return Icons.cancel_outlined;
    }
  }

  Color _color(ThemeData t, ApplicationStatus s) {
    switch (s) {
      case ApplicationStatus.pending:
        return t.colorScheme.primary;
      case ApplicationStatus.approved:
        return Colors.green;
      case ApplicationStatus.rejected:
        return t.colorScheme.error;
    }
  }

  String _title(ApplicationStatus s) {
    switch (s) {
      case ApplicationStatus.pending:
        return 'Application under review';
      case ApplicationStatus.approved:
        return 'You\'re approved!';
      case ApplicationStatus.rejected:
        return 'Application not approved';
    }
  }

  String _subtitle(ApplicationStatus s, String? reason) {
    switch (s) {
      case ApplicationStatus.pending:
        return 'Hang tight — an admin will review your application. '
            'This page updates automatically when there is a decision.';
      case ApplicationStatus.approved:
        return 'Redirecting to the dashboard…';
      case ApplicationStatus.rejected:
        return reason?.isNotEmpty == true
            ? 'Reason: $reason'
            : 'You can update your application and submit again.';
    }
  }
}
