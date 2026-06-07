import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/wishlist_item_model.dart';
import '../providers/wishlist_providers.dart';

/// "Saved courses" — the user's personal wishlist.
///
/// Routes from `Profile → Saved courses`. Renders the denormalized
/// fields written by [WishlistDataSource.add], so we don't need to
/// re-fetch the source `courses/{id}` doc for the list view.
class WishlistPage extends ConsumerWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final asyncList = ref.watch(wishlistStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.wishlistTitle)),
      body: RefreshIndicator(
        // The stream provider re-emits on every Firestore snapshot;
        // invalidate forces a teardown + resubscribe in case the user
        // pulled to recover from a sticky offline error.
        onRefresh: () async => ref.invalidate(wishlistStreamProvider),
        child: asyncList.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 80),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('$e',
                      style: TextStyle(color: context.colors.error)),
                ),
              ),
            ],
          ),
          data: (items) {
            if (items.isEmpty) return _EmptyState(t: t);
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _WishlistRow(item: items[i]),
            );
          },
        ),
      ),
    );
  }
}

// ---------- Row ----------------------------------------------------------

class _WishlistRow extends ConsumerWidget {
  const _WishlistRow({required this.item});
  final WishlistItemModel item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white),
      ),
      onDismissed: (_) async {
        // Direct datasource remove — we don't need the optimistic
        // overlay here because the stream snapshot will drop the row
        // before the user can notice.
        final user = ref.read(currentUserOrThrowProvider);
        await ref.read(wishlistDataSourceProvider).remove(
              userId: user.id,
              courseId: item.courseId,
            );
      },
      child: ListTile(
        onTap: () => context.pushNamed(
          RouteNames.courseDetail,
          pathParameters: {'id': item.courseId},
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 80,
            height: 56,
            child: (item.thumbnailUrl?.isEmpty ?? true)
                ? Container(color: AppColors.primary.withValues(alpha: 0.20))
                : CachedNetworkImage(
                    imageUrl: item.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                        color: AppColors.primary.withValues(alpha: 0.20)),
                  ),
          ),
        ),
        title: Text(
          item.title.isEmpty ? t.wishlistUntitled : item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          item.instructorName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

// ---------- Empty state --------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.t});
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return ListView(
      // Wrap in ListView so RefreshIndicator works on empty.
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bookmark_outline_rounded,
                  size: 64,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  t.wishlistEmptyTitle,
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.wishlistEmptyBody,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.explore_rounded),
                  label: Text(t.wishlistBrowseCta),
                  onPressed: () =>
                      context.goNamed(RouteNames.courses),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------- Helper: throws if signed out --------------------------------

/// Only used by the Dismissible. The page itself is gated behind auth
/// at the router level, so reaching here without a user is a bug.
final currentUserOrThrowProvider = Provider((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw StateError('WishlistPage opened without an authenticated user');
  }
  return user;
});
