import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/learning_path_model.dart';

/// Horizontal card matching the Home tab's 320×280 carousel proportions
/// — same metrics as `CourseCard` so the visual rhythm stays consistent
/// when rails sit next to each other.
class LearningPathCard extends StatelessWidget {
  const LearningPathCard({
    super.key,
    required this.path,
    required this.onTap,
  });

  final LearningPathModel path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (path.coverUrl == null || path.coverUrl!.isEmpty)
                    Container(color: AppColors.primary.withValues(alpha: 0.15))
                  else
                    CachedNetworkImage(
                      imageUrl: path.coverUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.black12),
                      errorWidget: (_, __, ___) => Container(
                          color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                  // Dark gradient at the bottom so the eyebrow label
                  // stays readable on any cover.
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black54,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 10,
                    right: 12,
                    child: Text(
                      t.learningPathEyebrow,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    path.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.menu_book_outlined,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        t.learningPathCourseCount(path.courseIds.length),
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.schedule_outlined,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        t.learningPathTotalHours(
                          path.totalHours.toStringAsFixed(
                            path.totalHours.truncate() == path.totalHours
                                ? 0
                                : 1,
                          ),
                        ),
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
