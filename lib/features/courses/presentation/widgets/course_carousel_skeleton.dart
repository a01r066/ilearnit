import 'package:flutter/material.dart';

import '../../../../core/widgets/skeleton.dart';

/// Horizontal skeleton row that matches the Home tab's 320×280 course-card
/// carousels. Drop into any horizontal `ListView` slot during loading.
class CourseCarouselSkeleton extends StatelessWidget {
  const CourseCarouselSkeleton({
    super.key,
    this.itemCount = 3,
    this.cardWidth = 280,
    this.height = 320,
  });

  final int itemCount;
  final double cardWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) =>
              SizedBox(width: cardWidth, child: const _SkeletonCard()),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: SkeletonBox(borderRadius: 0),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SkeletonBox(width: 52, height: 18, borderRadius: 9),
                    SizedBox(width: 6),
                    SkeletonBox(width: 64, height: 18, borderRadius: 9),
                  ],
                ),
                SizedBox(height: 10),
                SkeletonText(height: 14),
                SizedBox(height: 6),
                SkeletonText(width: 160, height: 14),
                SizedBox(height: 12),
                SkeletonText(width: 110, height: 11),
                SizedBox(height: 12),
                Row(
                  children: [
                    SkeletonText(width: 40, height: 11),
                    SizedBox(width: 12),
                    SkeletonText(width: 60, height: 11),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
