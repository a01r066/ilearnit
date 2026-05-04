import 'package:flutter/material.dart';

import '../../domain/entities/course_section_entity.dart';
import '../../domain/entities/lecture_entity.dart';
import 'lecture_tile.dart';

/// Expandable curriculum section. Sections collapse by default; only the
/// first one expands (handled by parent via [initiallyExpanded]).
class SectionTile extends StatelessWidget {
  const SectionTile({
    super.key,
    required this.index,
    required this.section,
    required this.isEnrolled,
    required this.onLectureTap,
    this.initiallyExpanded = false,
  });

  final int index;
  final CourseSectionEntity section;
  final bool isEnrolled;
  final bool initiallyExpanded;
  final void Function(LectureEntity) onLectureTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = theme.hintColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          shape: const RoundedRectangleBorder(),
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Section ${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  section.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${section.lectureCount} lectures • ${section.formattedTotalDuration}',
              style: theme.textTheme.bodySmall?.copyWith(color: hint),
            ),
          ),
          children: [
            const Divider(height: 1),
            for (var i = 0; i < section.lectures.length; i++) ...[
              LectureTile(
                index: i,
                lecture: section.lectures[i],
                isAccessible:
                    isEnrolled || section.lectures[i].isPreview,
                onTap: () => onLectureTap(section.lectures[i]),
              ),
              if (i < section.lectures.length - 1)
                const Divider(height: 1, indent: 64),
            ],
          ],
        ),
      ),
    );
  }
}
