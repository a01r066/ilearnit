import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../purchases/presentation/providers/purchases_providers.dart';
import '../../data/models/course_review_model.dart';
import '../providers/reviews_providers.dart';
import 'write_review_sheet.dart';

/// "Ratings & Reviews" section rendered on the course detail page.
///
/// Layout: heading + average rating block, "Write/Edit your review" CTA
/// (gated by [hasUnlockedAccessProvider]), then the list of reviews.
class CourseReviewsSection extends ConsumerWidget {
  const CourseReviewsSection({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(courseReviewsProvider(courseId));
    final mine = ref.watch(myReviewProvider(courseId)).value;
    final hasAccess = ref.watch(hasUnlockedAccessProvider(courseId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ratings & Reviews',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            )),
        const SizedBox(height: 16),
        reviews.when(
          loading: () => const _ReviewsSkeleton(),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Failed to load reviews: $e',
                style: TextStyle(color: context.colors.error)),
          ),
          data: (list) {
            final avg = _average(list);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Summary(average: avg, count: list.length),
                const SizedBox(height: 16),
                if (hasAccess)
                  _WriteReviewCta(
                    courseId: courseId,
                    hasOwn: mine != null,
                  )
                else
                  _AccessGateHint(),
                const SizedBox(height: 16),
                if (list.isEmpty)
                  Text(
                    'No reviews yet — be the first.',
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  )
                else
                  for (var i = 0; i < list.length; i++) ...[
                    _ReviewTile(review: list[i]),
                    if (i != list.length - 1) const Divider(height: 24),
                  ],
              ],
            );
          },
        ),
      ],
    );
  }

  double _average(List<CourseReviewModel> list) {
    if (list.isEmpty) return 0;
    final total =
        list.fold<int>(0, (sum, r) => sum + r.rating);
    return total / list.length;
  }
}

// ---------- Summary -------------------------------------------------------

class _Summary extends StatelessWidget {
  const _Summary({required this.average, required this.count});
  final double average;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          average.toStringAsFixed(1),
          style: context.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Stars(rating: average, size: 18),
            const SizedBox(height: 4),
            Text(
              count == 1 ? '1 review' : '$count reviews',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, this.size = 18});
  final double rating;
  final double size;
  static const Color _gold = Color(0xFFE59819);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final diff = rating - i;
        IconData icon;
        if (diff >= 1.0) {
          icon = Icons.star_rounded;
        } else if (diff >= 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }
        return Icon(icon, size: size, color: _gold);
      }),
    );
  }
}

// ---------- Write CTA / access gate --------------------------------------

class _WriteReviewCta extends ConsumerWidget {
  const _WriteReviewCta({required this.courseId, required this.hasOwn});
  final String courseId;
  final bool hasOwn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(hasOwn ? Icons.edit_outlined : Icons.rate_review_outlined),
        label: Text(
          user == null
              ? 'Sign in to write a review'
              : (hasOwn ? 'Edit your review' : 'Write a review'),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
        onPressed: () {
          if (user == null) {
            context.showSnack('Sign in to leave a review.');
            context.goNamed(RouteNames.login);
            return;
          }
          WriteReviewSheet.show(context, courseId: courseId);
        },
      ),
    );
  }
}

class _AccessGateHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Unlock this course (or subscribe) to leave a review.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Review tile ---------------------------------------------------

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final CourseReviewModel review;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd();
    final date = review.createdAt;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          backgroundImage: (review.userPhotoUrl?.isNotEmpty ?? false)
              ? CachedNetworkImageProvider(review.userPhotoUrl!)
              : null,
          child: (review.userPhotoUrl?.isEmpty ?? true)
              ? const Icon(Icons.person_outline,
                  color: AppColors.primary, size: 22)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      review.userName,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (date != null)
                    Text(
                      dateFmt.format(date),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              _Stars(rating: review.rating.toDouble(), size: 14),
              if (review.body.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(review.body, style: context.textTheme.bodyLarge),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Three-row shimmer placeholder that matches `_ReviewTile`'s layout —
/// circle avatar + name + stars + body lines. Rendered while the live
/// `courseReviewsProvider` stream is in flight.
class _ReviewsSkeleton extends StatelessWidget {
  const _ReviewsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary row mirror: big avg + stars + count line.
          Row(
            children: const [
              SkeletonBox(width: 80, height: 36),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 100, height: 18),
                  SizedBox(height: 6),
                  SkeletonText(width: 70, height: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < 3; i++) ...[
            if (i != 0) const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonAvatar(size: 40),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonText(width: 140, height: 14),
                      SizedBox(height: 6),
                      SkeletonText(width: 80, height: 11),
                      SizedBox(height: 10),
                      SkeletonText(height: 12),
                      SizedBox(height: 6),
                      SkeletonText(width: 220, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
