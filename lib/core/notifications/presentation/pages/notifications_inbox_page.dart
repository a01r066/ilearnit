import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/extensions.dart';
import '../../data/models/notification_item_model.dart';
import '../../domain/notification_payload.dart';
import '../inbox_providers.dart';

/// In-app inbox at `/notifications`.
///
/// Pulls live from `users/{uid}/notifications/{id}` so the badge + list
/// stay in sync regardless of OS notification permission. Tap routes via
/// the same `data.route` payload field the FCM tap handler uses.
class NotificationsInboxPage extends ConsumerWidget {
  const NotificationsInboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final asyncItems = ref.watch(notificationsInboxProvider);
    final datasource = ref.read(notificationsInboxDataSourceProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.notificationsInboxTitle),
        actions: [
          PopupMenuButton<_MenuAction>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) async {
              if (user == null) return;
              switch (action) {
                case _MenuAction.markAllRead:
                  await datasource.markAllRead(userId: user.id);
                  break;
                case _MenuAction.clearAll:
                  final confirmed = await _confirmClear(context, t);
                  if (confirmed) {
                    await datasource.clearAll(userId: user.id);
                  }
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _MenuAction.markAllRead,
                child: Text(t.notificationsMarkAllRead),
              ),
              PopupMenuItem(
                value: _MenuAction.clearAll,
                child: Text(t.notificationsClearAll),
              ),
            ],
          ),
        ],
      ),
      body: asyncItems.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$e',
            style: TextStyle(color: context.colors.error),
          ),
        ),
        data: (items) {
          if (items.isEmpty) return _EmptyState(label: t.notificationsEmpty);
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _InboxTile(
              item: items[i],
              onTap: () => _handleTap(context, ref, items[i]),
              onDismiss: () =>
                  user == null
                      ? Future<void>.value()
                      : datasource.delete(
                          userId: user.id,
                          notificationId: items[i].id,
                        ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    NotificationItemModel item,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user != null && item.readAt == null) {
      await ref
          .read(notificationsInboxDataSourceProvider)
          .markRead(userId: user.id, notificationId: item.id);
    }
    if (!context.mounted) return;

    final route = item.payload['route'];
    if (route != null && route.isNotEmpty && route != '/') {
      // Use `go` rather than `push` so popping the inbox doesn't put the
      // user back into a stale state — the deep-linked screen is the new
      // current location.
      context.go(route);
    } else {
      context.pop();
    }
  }

  Future<bool> _confirmClear(
    BuildContext context,
    AppLocalizations t,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.notificationsClearAllConfirmTitle),
        content: Text(t.notificationsClearAllConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.notificationsClearAll),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}

enum _MenuAction { markAllRead, clearAll }

// ---------- Subwidgets ----------------------------------------------------

class _InboxTile extends StatelessWidget {
  const _InboxTile({
    required this.item,
    required this.onTap,
    required this.onDismiss,
  });

  final NotificationItemModel item;
  final VoidCallback onTap;
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    final unread = item.readAt == null;
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
      onDismissed: (_) => onDismiss(),
      child: Container(
        color: unread
            ? AppColors.primary.withValues(alpha: 0.05)
            : Colors.transparent,
        child: ListTile(
          leading: _LeadingIcon(
              type: NotificationType.fromId(item.type), unread: unread),
          title: Text(
            item.title.isEmpty ? '—' : item.title,
            style: TextStyle(
              fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.body.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                _formatRelative(item.createdAt),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  String _formatRelative(DateTime? when) {
    if (when == null) return '';
    final now = DateTime.now();
    final diff = now.difference(when);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.yMMMd().format(when);
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.type, required this.unread});
  final NotificationType type;
  final bool unread;

  IconData get _icon {
    switch (type) {
      case NotificationType.applicationApproved:
        return Icons.verified_rounded;
      case NotificationType.applicationRejected:
        return Icons.cancel_outlined;
      case NotificationType.enrollmentCreated:
        return Icons.school_rounded;
      case NotificationType.broadcast:
        return Icons.campaign_rounded;
      case NotificationType.unknown:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(_icon, color: AppColors.primary, size: 22),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: context.colors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
