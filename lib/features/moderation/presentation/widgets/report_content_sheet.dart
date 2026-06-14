import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/report_content_type.dart';
import '../../domain/entities/report_reason.dart';
import '../providers/moderation_providers.dart';

/// Modal bottom sheet that collects a [ReportReason] + optional notes
/// and writes a `reports/{id}` doc via [ReportsDataSource.submit].
///
/// Show via [showReportContentSheet]. The caller supplies the snapshot
/// fields so the sheet itself doesn't need to know about the reported
/// content's data model.
class ReportContentSheet extends ConsumerStatefulWidget {
  const ReportContentSheet({
    super.key,
    required this.contentType,
    required this.contentId,
    required this.contentPath,
    required this.contentSnapshot,
    required this.authorId,
    this.authorName = '',
    this.courseId,
    this.lectureId,
  });

  final ReportContentType contentType;
  final String contentId;
  final String contentPath;
  final String contentSnapshot;
  final String authorId;
  final String authorName;
  final String? courseId;
  final String? lectureId;

  @override
  ConsumerState<ReportContentSheet> createState() =>
      _ReportContentSheetState();
}

class _ReportContentSheetState extends ConsumerState<ReportContentSheet> {
  ReportReason? _reason;
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _submitting) return;
    final user = ref.read(currentUserProvider);
    if (user == null) {
      // Defensive — the trigger should already be gated on auth.
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(reportsDataSourceProvider).submit(
            contentType: widget.contentType,
            contentId: widget.contentId,
            contentPath: widget.contentPath,
            courseId: widget.courseId,
            lectureId: widget.lectureId,
            contentSnapshot: widget.contentSnapshot,
            authorId: widget.authorId,
            authorName: widget.authorName,
            reporterId: user.id,
            reporterName: user.displayName ?? '',
            reason: reason,
            reporterNotes: _notesCtrl.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks — our team will review this shortly.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined,
                    color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text('Report ${widget.contentType.label.toLowerCase()}',
                    style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Help us keep this community safe. Reports are reviewed within 24 hours.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text('Reason', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            // Radio list — explicit reasons drive consistent admin
            // triage. Avoid a single free-text field; it makes
            // bucketed dashboards impossible.
            ...ReportReason.values.map(
              (r) => RadioListTile<ReportReason>(
                value: r,
                groupValue: _reason,
                onChanged: _submitting
                    ? null
                    : (v) => setState(() => _reason = v),
                title: Text(r.label),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              enabled: !_submitting,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Additional notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_reason == null || _submitting) ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Convenience entry point. Show from any UGC menu callback.
Future<void> showReportContentSheet(
  BuildContext context, {
  required ReportContentType contentType,
  required String contentId,
  required String contentPath,
  required String contentSnapshot,
  required String authorId,
  String authorName = '',
  String? courseId,
  String? lectureId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ReportContentSheet(
      contentType: contentType,
      contentId: contentId,
      contentPath: contentPath,
      contentSnapshot: contentSnapshot,
      authorId: authorId,
      authorName: authorName,
      courseId: courseId,
      lectureId: lectureId,
    ),
  );
}
