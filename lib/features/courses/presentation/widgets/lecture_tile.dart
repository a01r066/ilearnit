import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/lecture_entity.dart';
import '../../domain/entities/lecture_type.dart';

/// One row inside a [SectionTile]'s expanded body.
///
/// `isAccessible` controls the lock indicator: previews are always accessible,
/// other lectures are gated behind enrollment.
class LectureTile extends StatelessWidget {
  const LectureTile({
    super.key,
    required this.lecture,
    required this.isAccessible,
    required this.index,
    this.onTap,
  });

  final LectureEntity lecture;
  final bool isAccessible;
  final int index;
  final VoidCallback? onTap;

  Color _typeColor(BuildContext context) {
    switch (lecture.type) {
      case LectureType.video:
        return AppColors.primary;
      case LectureType.audio:
        return AppColors.info;
      case LectureType.pdf:
        return AppColors.error;
      case LectureType.doc:
        return Theme.of(context).colorScheme.tertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(context);
    final hint = Theme.of(context).hintColor;

    return InkWell(
      onTap: isAccessible ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '${index + 1}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: hint,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(lecture.type.icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecture.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        lecture.type.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(' • ', style: TextStyle(color: hint)),
                      Text(
                        lecture.formattedDuration,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: hint,
                            ),
                      ),
                      if (lecture.hasResources) ...[
                        Text(' • ', style: TextStyle(color: hint)),
                        Icon(Icons.attach_file_rounded,
                            size: 12, color: hint),
                        Text(
                          ' ${lecture.resources.length}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: hint,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (lecture.isPreview)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              )
            else if (!isAccessible)
              Icon(Icons.lock_outline_rounded, size: 18, color: hint),
          ],
        ),
      ),
    );
  }
}
