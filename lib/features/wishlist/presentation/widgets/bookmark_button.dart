import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../providers/wishlist_providers.dart';

/// Heart-icon toggle that adds / removes a course from the user's
/// wishlist. Reusable across `CourseCard`, `CourseDetailPage`, and the
/// search result tile.
///
/// The icon state is driven by [effectiveWishlistedProvider], which
/// blends server-truth ids with the optimistic overlay so the heart
/// flips instantly on tap.
///
/// Variants are controlled by [style]:
///   • `card` — small filled-circle button overlaid on a thumbnail
///   • `appBar` — transparent IconButton sized for `AppBar.actions`
///   • `plain` — no background, just the icon (use in dense lists)
enum BookmarkButtonStyle { card, appBar, plain }

class BookmarkButton extends ConsumerWidget {
  const BookmarkButton({
    super.key,
    required this.course,
    this.style = BookmarkButtonStyle.card,
    this.size = 22,
  });

  final CourseEntity course;
  final BookmarkButtonStyle style;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final saved = ref.watch(effectiveWishlistedProvider(course.id));
    final user = ref.watch(currentUserProvider);

    // Guest viewer — render the icon but route to login on tap so we
    // don't silently swallow the gesture.
    final isGuest = user == null;

    ref.listen(wishlistToggleNotifierProvider, (_, next) {
      if (next.lastErrorCourseId == course.id) {
        context.showSnack(t.wishlistError);
      }
    });

    final icon = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: anim,
        child: FadeTransition(opacity: anim, child: child),
      ),
      // Keying on the boolean lets AnimatedSwitcher detect the swap.
      child: Icon(
        saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        key: ValueKey(saved),
        size: size,
        color: saved
            ? AppColors.error
            : (style == BookmarkButtonStyle.card
                ? Colors.white
                : context.colors.onSurface),
      ),
    );

    final onTap = isGuest
        ? () => context.showSnack(t.wishlistSignInPrompt)
        : () => ref
            .read(wishlistToggleNotifierProvider.notifier)
            .toggle(course: course, wasOnWishlist: saved);

    final tooltip = saved ? t.wishlistRemoveTooltip : t.wishlistAddTooltip;

    switch (style) {
      case BookmarkButtonStyle.card:
        return Material(
          color: Colors.black.withValues(alpha: 0.40),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Tooltip(message: tooltip, child: icon),
            ),
          ),
        );
      case BookmarkButtonStyle.appBar:
        return IconButton(
          onPressed: onTap,
          tooltip: tooltip,
          icon: icon,
        );
      case BookmarkButtonStyle.plain:
        return InkResponse(
          onTap: onTap,
          radius: size + 6,
          child: Tooltip(message: tooltip, child: icon),
        );
    }
  }
}
