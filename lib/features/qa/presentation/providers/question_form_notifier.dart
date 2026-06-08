import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/error/failure.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../data/datasources/course_qa_datasource.dart';
import 'qa_form_state.dart';

/// Drives the "Write a question" sheet. Lives per-lecture so a draft
/// doesn't leak between lectures.
class QuestionFormNotifier extends StateNotifier<QAFormState> {
  QuestionFormNotifier({
    required CourseQADataSource datasource,
    required this.courseId,
    required this.sectionId,
    required this.lectureId,
    required UserEntity? user,
  })  : _datasource = datasource,
        _user = user,
        super(const QAFormState());

  final CourseQADataSource _datasource;
  final String courseId;
  final String sectionId;
  final String lectureId;
  final UserEntity? _user;

  void setBody(String value) =>
      state = state.copyWith(body: value, lastFailure: null);

  Future<String?> submit() async {
    final user = _user;
    if (user == null) return null;
    if (!state.canSubmit) return null;

    state = state.copyWith(
      isSubmitting: true,
      lastFailure: null,
      justSubmitted: false,
    );
    try {
      final id = await _datasource.submitQuestion(
        courseId: courseId,
        sectionId: sectionId,
        lectureId: lectureId,
        user: user,
        body: state.body,
      );
      state = const QAFormState(justSubmitted: true);
      return id;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        lastFailure: Failure.unexpected(
          message: 'Could not post your question.',
          error: e,
        ),
      );
      return null;
    }
  }

  /// Pre-fill the body when opened from the "edit" overflow action.
  void seed(String body) => state = state.copyWith(body: body);
}
