import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions.dart';
import '../providers/review_form_state.dart';
import '../providers/reviews_providers.dart';

/// Modal bottom sheet for writing or editing the user's own review.
///
/// The form is hydrated from the existing review (if any) by the family
/// notifier — see [reviewFormNotifierProvider].
class WriteReviewSheet extends ConsumerStatefulWidget {
  const WriteReviewSheet._({required this.courseId});
  final String courseId;

  static Future<void> show(BuildContext context, {required String courseId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => WriteReviewSheet._(courseId: courseId),
    );
  }

  @override
  ConsumerState<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<WriteReviewSheet> {
  late final TextEditingController _body;

  @override
  void initState() {
    super.initState();
    _body = TextEditingController(
      text: ref
          .read(reviewFormNotifierProvider(widget.courseId))
          .body,
    );
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewFormNotifierProvider(widget.courseId));
    final notifier =
        ref.read(reviewFormNotifierProvider(widget.courseId).notifier);

    // Auto-close on successful submit.
    ref.listen<ReviewFormState>(
      reviewFormNotifierProvider(widget.courseId),
      (_, next) {
        if (next.justSubmitted) Navigator.of(context).maybePop();
        if (next.lastFailure != null) {
          context.showSnack(next.lastFailure!.displayMessage);
        }
      },
    );

    final hasExisting = ref
            .watch(myReviewProvider(widget.courseId))
            .value !=
        null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasExisting ? 'Edit your review' : 'Write a review',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _StarPicker(
                rating: state.rating,
                onChanged: notifier.setRating,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _body,
                minLines: 3,
                maxLines: 8,
                maxLength: 600,
                decoration: const InputDecoration(
                  labelText: 'Your review (optional)',
                  hintText: 'What did you think of the course?',
                ),
                onChanged: notifier.setBody,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: state.canSubmit ? notifier.submit : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: state.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
              if (hasExisting) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete your review?'),
                              content: const Text(
                                  'This will remove your rating and review '
                                  'from this course.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) await notifier.deleteMine();
                        },
                  child: const Text('Delete my review',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StarPicker extends StatelessWidget {
  const _StarPicker({required this.rating, required this.onChanged});
  final int rating;
  final ValueChanged<int> onChanged;
  static const Color _gold = Color(0xFFE59819);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final filled = i < rating;
        return IconButton(
          iconSize: 40,
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            color: _gold,
          ),
          onPressed: () => onChanged(i + 1),
        );
      }),
    );
  }
}
