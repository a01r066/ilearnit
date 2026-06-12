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
import '../../../courses/presentation/providers/courses_providers.dart';
import '../../data/models/course_question_model.dart';
import '../../data/models/course_question_reply_model.dart';
import '../providers/qa_form_state.dart';
import '../providers/qa_keys.dart';
import '../providers/qa_providers.dart';
import '../widgets/verified_instructor_badge.dart';

/// Full-screen thread view for a single question.
///
/// Layout: question card at the top, scrollable list of replies, then
/// a sticky composer at the bottom. The composer auto-stamps
/// `isInstructor: true` if the current user is the course's
/// instructorId.
class QuestionThreadPage extends ConsumerStatefulWidget {
  const QuestionThreadPage({
    super.key,
    required this.courseId,
    required this.sectionId,
    required this.lectureId,
    required this.questionId,
  });

  final String courseId;
  final String sectionId;
  final String lectureId;
  final String questionId;

  @override
  ConsumerState<QuestionThreadPage> createState() =>
      _QuestionThreadPageState();
}

class _QuestionThreadPageState extends ConsumerState<QuestionThreadPage> {
  final _bodyCtrl = TextEditingController();

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final qKey = QuestionRepliesKey(
      courseId: widget.courseId,
      sectionId: widget.sectionId,
      lectureId: widget.lectureId,
      questionId: widget.questionId,
    );

    final questionAsync = ref.watch(questionByIdProvider(qKey));
    final repliesAsync = ref.watch(questionRepliesProvider(qKey));

    // The current viewer's relationship to this course — drives the
    // "verified instructor" stamp on the reply.
    final user = ref.watch(currentUserProvider);
    final courseAsync =
        ref.watch(courseByIdProvider(widget.courseId));
    final isInstructorOfCourse = courseAsync.value != null &&
        user != null &&
        courseAsync.value!.instructorId == user.id;

    final replyKey = ReplyFormKey(
      courseId: widget.courseId,
      sectionId: widget.sectionId,
      lectureId: widget.lectureId,
      questionId: widget.questionId,
      isInstructor: isInstructorOfCourse,
    );
    final replyState = ref.watch(replyFormNotifierProvider(replyKey));
    final replyNotifier =
        ref.read(replyFormNotifierProvider(replyKey).notifier);

    // Snackbar on failure, clear field on success.
    ref.listen<QAFormState>(replyFormNotifierProvider(replyKey),
        (_, next) {
      if (next.lastFailure != null) {
        context.showSnack(next.lastFailure!.displayMessage);
      }
      if (next.justSubmitted) {
        _bodyCtrl.clear();
        FocusScope.of(context).unfocus();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(t.qaThreadTitle)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                questionAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Text(
                    '$e',
                    style: TextStyle(color: context.colors.error),
                  ),
                  data: (q) {
                    if (q == null) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(t.qaThreadMissing),
                      );
                    }
                    return _QuestionCard(question: q);
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  t.qaReplies,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                repliesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text(
                    '$e',
                    style: TextStyle(color: context.colors.error),
                  ),
                  data: (replies) {
                    if (replies.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          t.qaNoRepliesYet,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final r in replies) ...[
                          _ReplyTile(reply: r),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          // Guest viewers see a sign-in CTA instead of the composer.
          // Routing to /login here mirrors the Ask-a-question gate in
          // LectureQASection so the two entry points feel consistent.
          if (user == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Sign in to reply'),
                onPressed: () {
                  context.showSnack('Sign in to join the conversation.');
                  context.goNamed(RouteNames.login);
                },
              ),
            )
          else
            _Composer(
              controller: _bodyCtrl,
              state: replyState,
              isInstructor: isInstructorOfCourse,
              onChanged: replyNotifier.setBody,
              onSubmit: replyNotifier.submit,
              hint: t.qaReplyHint,
              sendLabel: t.qaSend,
            ),
        ],
      ),
    );
  }
}

// ---------- Question card -------------------------------------------------

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});
  final CourseQuestionModel question;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(
                  url: question.userPhotoUrl, name: question.userName),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.userName.isEmpty
                      ? t.qaAnonymous
                      : question.userName,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (question.createdAt != null)
                Text(
                  DateFormat.yMMMd().format(question.createdAt!),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.body,
            style: context.textTheme.bodyLarge?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ---------- Reply tile ----------------------------------------------------

class _ReplyTile extends StatelessWidget {
  const _ReplyTile({required this.reply});
  final CourseQuestionReplyModel reply;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(url: reply.userPhotoUrl, name: reply.userName),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      reply.userName.isEmpty
                          ? t.qaAnonymous
                          : reply.userName,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (reply.isInstructor) ...[
                    const SizedBox(width: 8),
                    const VerifiedInstructorBadge(),
                  ],
                  const Spacer(),
                  if (reply.createdAt != null)
                    Text(
                      DateFormat.yMMMd().format(reply.createdAt!),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(reply.body, style: context.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
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

// ---------- Composer ------------------------------------------------------

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.state,
    required this.isInstructor,
    required this.onChanged,
    required this.onSubmit,
    required this.hint,
    required this.sendLabel,
  });

  final TextEditingController controller;
  final QAFormState state;
  final bool isInstructor;
  final ValueChanged<String> onChanged;
  final Future<bool> Function() onSubmit;
  final String hint;
  final String sendLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: state.canSubmit ? onSubmit : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(80, 48),
                  backgroundColor: isInstructor
                      ? AppColors.primary
                      : AppColors.primary,
                ),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(sendLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
