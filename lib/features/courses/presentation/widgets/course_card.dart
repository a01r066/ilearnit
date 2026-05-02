import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/entities/instrument_category.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course, this.onTap});

  final CourseEntity course;
  final VoidCallback? onTap;

  Color get _accent {
    switch (course.category) {
      case InstrumentCategory.guitar:
        return AppColors.guitar;
      case InstrumentCategory.piano:
        return AppColors.piano;
      case InstrumentCategory.violin:
        return AppColors.violin;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          // mainAxisSize.min lets the card collapse to its natural height
          // when the parent gives it loose vertical constraints, and
          // Flexible on the content section keeps the card honest when
          // the parent forces a tighter height (e.g. a carousel SizedBox).
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: course.thumbnailUrl.isEmpty
                      ? Container(color: _accent.withValues(alpha: 0.15))
                      : CachedNetworkImage(
                          imageUrl: course.thumbnailUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: Colors.black12),
                          errorWidget: (_, __, ___) =>
                              Container(color: _accent.withValues(alpha: 0.15)),
                        ),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Chip(label: course.category.label, color: _accent),
                          const SizedBox(width: 6),
                          _Chip(
                            label: course.level.label,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Flexible+ellipsis prevents long titles from forcing a
                      // taller card than the parent allows.
                      Flexible(
                        child: Text(
                          course.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'by ${course.instructorName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      _StatsRow(course: course),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.course});
  final CourseEntity course;

  @override
  Widget build(BuildContext context) {
    final hint = Theme.of(context).hintColor;
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
        Text(
          ' ${course.rating.toStringAsFixed(1)}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(width: 12),
        Icon(Icons.video_library_outlined, size: 16, color: hint),
        Flexible(
          child: Text(
            ' ${course.lessonCount} lessons',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
