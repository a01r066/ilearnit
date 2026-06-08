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
        const SizedBox(height: 32),
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
          leading: const Icon(Icons.sticky_note_2_outlined),
          title: Text(AppLocalizations.of(context).notesPageTitle),
          subtitle:
              Text(AppLocalizations.of(context).notesProfileSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushNamed(RouteNames.notes),
        ),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Settings'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.goNamed(RouteNames.setting);
          },
        ),
        const RestorePurchasesTile(),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.error),
          title: const Text(
            'Sign out',
            style: TextStyle(color: AppColors.error),
          ),
          onTap: isLoading
              ? null
              : () => ref.read(authNotifierProvider.notifier).logout(),
        ),
      ],
    );
  }
}
