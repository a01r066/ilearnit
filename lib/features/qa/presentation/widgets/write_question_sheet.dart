import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/qa_form_state.dart';
import '../providers/qa_keys.dart';
import '../providers/qa_providers.dart';

/// Modal bottom sheet for posting a new question against a lecture.
/// Returns the new question's id (or null) so the caller can route to
/// the thread page.
class WriteQuestionSheet extends ConsumerStatefulWidget {
  const WriteQuestionSheet._({required this.qaKey});
  final LectureQAKey qaKey;

  static Future<String?> show(
    BuildContext context, {
    required LectureQAKey qaKey,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => WriteQuestionSheet._(qaKey: qaKey),
    );
  }

  @override
  ConsumerState<WriteQuestionSheet> createState() =>
      _WriteQuestionSheetState();
}

class _WriteQuestionSheetState extends ConsumerState<WriteQuestionSheet> {
  late final TextEditingController _body;

  @override
  void initState() {
    super.initState();
    _body = TextEditingController(
      text:
          ref.read(questionFormNotifierProvider(widget.qaKey)).body,
    );
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(questionFormNotifierProvider(widget.qaKey));
    final notifier =
        ref.read(questionFormNotifierProvider(widget.qaKey).notifier);

    ref.listen<QAFormState>(
      questionFormNotifierProvider(widget.qaKey),
      (_, next) {
        if (next.lastFailure != null) {
          context.showSnack(next.lastFailure!.displayMessage);
        }
      },
    );

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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.qaAskTitle,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _body,
                autofocus: true,
                minLines: 4,
                maxLines: 10,
                maxLength: 1000,
                decoration: InputDecoration(
                  labelText: t.qaQuestionLabel,
                  hintText: t.qaQuestionHint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: notifier.setBody,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: state.canSubmit
                    ? () async {
                        final id = await notifier.submit();
                        if (id != null && context.mounted) {
                          Navigator.of(context).pop(id);
                        }
                      }
                    : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.qaPostQuestion),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
