import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/route_names.dart';
import '../../../theme/app_colors.dart';
import '../inbox_providers.dart';

/// Bell IconButton with an unread-count badge. Tap routes to the in-app
/// inbox.
///
/// Drop into any AppBar / header row — used today on Home + Songbooks.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, this.iconColor});

  /// Tints the bell glyph. Defaults to the surrounding `IconTheme` color.
  final Color? iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadNotificationsCountProvider).value ?? 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: iconColor),
          tooltip: 'Notifications',
          onPressed: () => context.pushNamed(RouteNames.notificationsInbox),
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
