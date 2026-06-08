import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/error/failure.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../data/datasources/course_qa_datasource.dart';
import 'qa_form_state.dart';

/// Drives the "Reply" composer at the bottom of [QuestionThreadPage].
///
/// `isInstructor` is resolved at the call site by the caller comparing
/// the current user id to the course's `instructorId`. Captured here at
/// construction time so the reply is stamped correctly regardless of
/// later state churn.
class ReplyFormNotifier extends StateNotifier<QAFormState> {
  ReplyFormNotifier({
    required CourseQADataSource datasource,
    required this.courseId,
    required this.sectionId,
    required this.lectureId,
    required this.questionId,
    required UserEntity? user,
    required this.isInstructor,
  })  : _datasource = datasource,
        _user = user,
        super(const QAFormState());

  final CourseQADataSource _datasource;
  final String courseId;
  final String sectionId;
  final String lectureId;
  final String questionId;
  final UserEntity? _user;
  final bool isInstructor;

  void setBody(String value) =>
      state = state.copyWith(body: value, lastFailure: null);

  Future<bool> submit() async {
    final user = _user;
    if (user == null) return false;
    if (!state.canSubmit) return false;

    state = state.copyWith(
      isSubmitting: true,
      lastFailure: null,
      justSubmitted: false,
    );
    try {
      await _datasource.submitReply(
        courseId: courseId,
        sectionId: sectionId,
        lectureId: lectureId,
        questionId: questionId,
        user: user,
        isInstructor: isInstructor,
        body: state.body,
      );
      state = const QAFormState(justSubmitted: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        lastFailure: Failure.unexpected(
          message: 'Could not post your reply.',
          error: e,
        ),
      );
      return false;
    }
  }
}
