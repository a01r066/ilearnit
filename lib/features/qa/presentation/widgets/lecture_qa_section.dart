import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/course_question_model.dart';
import '../providers/qa_keys.dart';
import '../providers/qa_providers.dart';
import 'verified_instructor_badge.dart';
import 'write_question_sheet.dart';

/// Compact Q&A section embedded inside the lecture body. Shows the
/// most recent questions + "Ask a question" CTA + "See all" link to
/// the full questions page.
class LectureQASection extends ConsumerWidget {
  const LectureQASection({
    super.key,
    required this.courseId,
    required this.sectionId,
    required this.lectureId,
    this.maxPreview = 3,
  });

  final String courseId;
  final String sectionId;
  final String lectureId;
  final int maxPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final key = LectureQAKey(
      courseId: courseId,
      sectionId: sectionId,
      lectureId: lectureId,
    );
    final async = ref.watch(lectureQuestionsProvider(key));
    final user = ref.watch(currentUserProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.qaSectionHeader,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Always render the Ask button — guests get redirected to
            // /login on tap (instead of silently hiding the
            // affordance, which makes the section look empty + dead
            // for unauthenticated users).
            TextButton.icon(
              icon: const Icon(Icons.add_comment_outlined, size: 18),
              label: Text(t.qaAsk),
              onPressed: () async {
                if (user == null) {
                  context.showSnack('Sign in to ask a question.');
                  context.goNamed(RouteNames.login);
                  return;
                }
                final id =
                    await WriteQuestionSheet.show(context, qaKey: key);
                if (id != null && context.mounted) {
                  context.pushNamed(
                    RouteNames.questionThread,
                    pathParameters: {
                      'id': courseId,
                      'lectureId': lectureId,
                      'questionId': id,
                    },
                    queryParameters: {'sectionId': sectionId},
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '$e',
              style: TextStyle(color: context.colors.error),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  user == null
                      ? t.qaEmptyAnonymous
                      : t.qaEmptyAuthenticated,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              );
            }
            final preview = items.take(maxPreview).toList();
            return Column(
              children: [
                for (var i = 0; i < preview.length; i++) ...[
                  _QuestionRow(
                    question: preview[i],
                    onTap: () => context.pushNamed(
                      RouteNames.questionThread,
                      pathParameters: {
                        'id': courseId,
                        'lectureId': lectureId,
                        'questionId': preview[i].id,
                      },
                      queryParameters: {'sectionId': sectionId},
                    ),
                  ),
                  if (i != preview.length - 1)
                    const Divider(height: 16),
                ],
                if (items.length > maxPreview) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {/* future: full list page */},
                    child: Text(t.qaSeeAll(items.length)),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// One question row in the compact section. Routes to the thread page
/// on tap.
class _QuestionRow extends StatelessWidget {
  const _QuestionRow({required this.question, required this.onTap});

  final CourseQuestionModel question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(url: question.userPhotoUrl, name: question.userName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          question.userName.isEmpty
                              ? t.qaAnonymous
                              : question.userName,
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (question.createdAt != null)
                        Text(
                          _relative(question.createdAt!),
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    question.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: context.colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t.qaReplyCount(question.replyCount),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      if (question.isInstructorAnswered) ...[
                        const SizedBox(width: 12),
                        const VerifiedInstructorBadge(compact: true),
                      ],
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

  static String _relative(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat.yMMMd().format(when);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name});
  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      backgroundImage: (url?.isNotEmpty ?? false)
          ? CachedNetworkImageProvider(url!)
          : null,
      child: (url?.isEmpty ?? true)
          ? Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}
