import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ilearnit/core/routing/route_names.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import 'package:ilearnit/features/auth/domain/entities/user_entity.dart';
import '../../../purchases/presentation/widgets/restore_purchases_tile.dart';
import '../../../subscriptions/presentation/providers/subscription_providers.dart';
import '../../../wishlist/presentation/providers/wishlist_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _buildBody(user, context, isLoading, ref),
    );
  }

  ListView _buildBody(UserEntity? user, BuildContext context, bool isLoading, WidgetRef ref) {
    final hasSubscription = ref.watch(hasActiveSubscriptionProvider);
    final isGuest = user == null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              backgroundImage: (user?.photoUrl?.isNotEmpty ?? false)
                  ? CachedNetworkImageProvider(user!.photoUrl!)
                  : null,
              child: (user?.photoUrl?.isEmpty ?? true)
                  ? const Icon(Icons.person_outline, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Guest',
                    style: context.textTheme.titleLarge,
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),

        // Guest sign-in prompt — shown when no auth user. Hides every
        // user-scoped tile below so we don't tempt a tap that just
        // bounces back through /login.
        if (isGuest) ...[
          const SizedBox(height: 24),
          _GuestSignInCard(),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 32),

        // ── User-scoped tiles (hidden for guests) ─────────────────
        if (!isGuest) ...[
          // "My learning" used to be a Profile tile but it's now a
          // bottom-nav tab — see `ShellScaffold`. Removed to avoid
          // surfacing the same destination twice.
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Subscription'),
            subtitle: hasSubscription
                ? const Text('Personal Plan · active')
                : const Text('Unlock all courses with Personal Plan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.goNamed(RouteNames.subscription),
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_outline),
            title: Text(AppLocalizations.of(context).wishlistTitle),
            subtitle: Consumer(
              builder: (context, ref, _) {
                final t = AppLocalizations.of(context);
                final count =
                    ref.watch(wishlistCountProvider).value ?? 0;
                if (count == 0) return Text(t.wishlistSubtitleEmpty);
                return Text(t.wishlistSubtitleCount(count));
              },
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(RouteNames.wishlist),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Watch history'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.sticky_note_2_outlined),
            title: Text(AppLocalizations.of(context).notesPageTitle),
            subtitle:
                Text(AppLocalizations.of(context).notesProfileSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(RouteNames.notes),
          ),
          // Moderator triage queue. Only rendered if the signed-in
          // user's role is moderator or admin — gated by the deep-link
          // check inside ModeratorReportsPage as well, but hiding the
          // tile for non-moderators keeps the profile uncluttered.
          // `user!` is safe here — this block is inside `if (!isGuest)`
          // which sets `isGuest = user == null`. The local-variable
          // null-check doesn't flow-promote `user`, so we bang it.
          if (user!.role.isModerator)
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Moderation queue'),
              subtitle: const Text('Triage UGC reports'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.pushNamed(RouteNames.moderator),
            ),
        ],

        // ── Public tiles (visible to both guests + signed-in users) ─
        ListTile(
          leading: const Icon(Icons.cloud_download_outlined),
          title: Text(AppLocalizations.of(context).downloadsTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushNamed(RouteNames.downloads),
        ),
        ListTile(
          leading: const Icon(Icons.tune_rounded),
          title: Text(AppLocalizations.of(context).practiceTitle),
          subtitle:
              Text(AppLocalizations.of(context).practiceTileSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushNamed(RouteNames.practice),
        ),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Settings'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.goNamed(RouteNames.setting);
          },
        ),
        if (!isGuest) const RestorePurchasesTile(),

        // ── Sign in / Sign out ────────────────────────────────────
        if (!isGuest) ...[
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text(
              'Sign out',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: isLoading
                ? null
                : () =>
                    ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ],
    );
  }
}

/// Header card shown on the Profile tab when the user is not signed
/// in. Drives them to /login or /signup. Once they're authenticated
/// the auth-state stream triggers a rebuild and this card disappears
/// in favour of the per-user tiles.
class _GuestSignInCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Save your progress',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in to unlock courses, save bookmarks, take notes, '
            'and pick up where you left off across devices.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => context.goNamed(RouteNames.login),
                  child: const Text('Sign in'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.goNamed(RouteNames.signup),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.onPrimaryContainer,
                    side: BorderSide(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text('Create account'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
