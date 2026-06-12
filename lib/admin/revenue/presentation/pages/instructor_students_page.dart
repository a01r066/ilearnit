import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/instructor_revenue_datasource.dart';
import '../providers/revenue_providers.dart';
import '../utils/csv_export.dart';

/// /my-students — list of enrollments grouped by the instructor's own
/// courses. Per course: a list of students + a Broadcast button that
/// fans out a message via the `instructorBroadcast` Cloud Function.
class InstructorStudentsPage extends ConsumerWidget {
  const InstructorStudentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Center(child: Text('Sign in required.'));
    }
    final theme = Theme.of(context);
    final coursesAsync =
        ref.watch(instructorOwnCoursesStreamProvider(user.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('My students', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Students enrolled in your courses, grouped by course. '
            'You only see students of YOUR OWN courses — other '
            'instructors\' rosters are not accessible.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          coursesAsync.when(
            data: (courses) => courses.isEmpty
                ? const _Empty(
                    text:
                        'You have no published courses yet. Once a student '
                        'enrolls in one of your courses they will appear here.',
                  )
                : Column(
                    children: [
                      for (final c in courses) ...[
                        _CourseStudentsBlock(course: c),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}

class _CourseStudentsBlock extends ConsumerWidget {
  const _CourseStudentsBlock({required this.course});
  final MyCourseRow course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final studentsAsync =
        ref.watch(courseStudentsStreamProvider(course.id));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header row ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      '${course.enrollmentCount} enrolled',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 160,
                child: OutlinedButton(
                  onPressed: () => _exportCsv(studentsAsync.value,
                      course.title),
                  child: const Text('Export CSV'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 200,
                child: FilledButton(
                  onPressed: () =>
                      _openBroadcastDialog(context, ref, course),
                  child: const Text('Message students'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          studentsAsync.when(
            data: (rows) => rows.isEmpty
                ? const _Empty(
                    text: 'No students enrolled in this course yet.',
                  )
                : Column(
                    children: [
                      for (var i = 0; i < rows.length; i++) ...[
                        _StudentRow(row: rows[i]),
                        if (i < rows.length - 1)
                          const Divider(height: 16),
                      ],
                    ],
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  void _exportCsv(List<EnrolledStudentRow>? rows, String courseTitle) {
    if (rows == null || rows.isEmpty) return;
    final csv = buildCsv(
      header: const ['Name', 'Email', 'Enrolled', 'Status', 'User ID'],
      rows: rows
          .map((r) => [
                r.studentName,
                r.studentEmail,
                r.enrolledAt.toIso8601String(),
                r.status,
                r.userId,
              ])
          .toList(),
    );
    final safeTitle =
        courseTitle.replaceAll(RegExp(r'[^A-Za-z0-9_]+'), '_');
    final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
    triggerCsvDownload(
      csv: csv,
      filename: 'students_${safeTitle}_$stamp.csv',
    );
  }

  Future<void> _openBroadcastDialog(
      BuildContext context, WidgetRef ref, MyCourseRow course) async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Message students in ${course.title}'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'New lecture published',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                maxLength: 800,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Lecture 5 is now live — happy practicing!',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sent as a push notification AND an inbox row to every '
                'student enrolled in this course. Students cannot reply.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (result != true) return;
    final title = titleCtrl.text.trim();
    final body = bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) return;

    try {
      final res = await FirebaseFunctions.instance
          .httpsCallable('instructorBroadcast')
          .call<Map<String, dynamic>>({
        'courseId': course.id,
        'title': title,
        'body': body,
      });
      final recipients = (res.data['recipientCount'] as num?)?.toInt() ?? 0;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sent to $recipients students.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Broadcast failed: $e')),
        );
      }
    }
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.row});
  final EnrolledStudentRow row;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat.yMMMd();
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            row.studentName.isEmpty
                ? '?'
                : row.studentName[0].toUpperCase(),
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(row.studentName,
                  style: theme.textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(row.studentEmail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Enrolled ${df.format(row.enrolledAt)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
