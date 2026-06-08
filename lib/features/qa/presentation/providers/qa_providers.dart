import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/course_qa_datasource.dart';
import '../../data/models/course_question_model.dart';
import '../../data/models/course_question_reply_model.dart';
import 'qa_form_state.dart';
import 'qa_keys.dart';
import 'question_form_notifier.dart';
import 'reply_form_notifier.dart';

// ---------- Datasource ----------------------------------------------------

final courseQADataSourceProvider = Provider<CourseQADataSource>(
  (ref) => CourseQADataSource(ref.watch(firestoreProvider)),
);

// ---------- Streams -------------------------------------------------------

final lectureQuestionsProvider = StreamProvider.autoDispose
    .family<List<CourseQuestionModel>, LectureQAKey>(
  (ref, key) => ref.watch(courseQADataSourceProvider).watchQuestions(
        courseId: key.courseId,
        sectionId: key.sectionId,
        lectureId: key.lectureId,
      ),
);

final lectureQuestionsCountProvider =
    Provider.autoDispose.family<int, LectureQAKey>((ref, key) {
  final list = ref.watch(lectureQuestionsProvider(key)).value;
  return list?.length ?? 0;
});

final questionByIdProvider = StreamProvider.autoDispose
    .family<CourseQuestionModel?, QuestionRepliesKey>(
  (ref, key) => ref.watch(courseQADataSourceProvider).watchQuestion(
        courseId: key.courseId,
        sectionId: key.sectionId,
        lectureId: key.lectureId,
        questionId: key.questionId,
      ),
);

final questionRepliesProvider = StreamProvider.autoDispose
    .family<List<CourseQuestionReplyModel>, QuestionRepliesKey>(
  (ref, key) => ref.watch(courseQADataSourceProvider).watchReplies(
        courseId: key.courseId,
        sectionId: key.sectionId,
        lectureId: key.lectureId,
        questionId: key.questionId,
      ),
);

// ---------- Form notifiers ------------------------------------------------

final questionFormNotifierProvider = StateNotifierProvider.autoDispose
    .family<QuestionFormNotifier, QAFormState, LectureQAKey>(
  (ref, key) => QuestionFormNotifier(
    datasource: ref.watch(courseQADataSourceProvider),
    courseId: key.courseId,
    sectionId: key.sectionId,
    lectureId: key.lectureId,
    user: ref.watch(currentUserProvider),
  ),
);

/// Compound key for the reply notifier — bundles whether the current
/// user is the course's instructor so the badge stamp is correct.
class ReplyFormKey {
  const ReplyFormKey({
    required this.courseId,
    required this.sectionId,
    required this.lectureId,
    required this.questionId,
    required this.isInstructor,
  });

  final String courseId;
  final String sectionId;
  final String lectureId;
  final String questionId;
  final bool isInstructor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplyFormKey &&
          other.courseId == courseId &&
          other.sectionId == sectionId &&
          other.lectureId == lectureId &&
          other.questionId == questionId &&
          other.isInstructor == isInstructor);

  @override
  int get hashCode => Object.hash(
        courseId,
        sectionId,
        lectureId,
        questionId,
        isInstructor,
      );
}

final replyFormNotifierProvider = StateNotifierProvider.autoDispose
    .family<ReplyFormNotifier, QAFormState, ReplyFormKey>(
  (ref, key) => ReplyFormNotifier(
    datasource: ref.watch(courseQADataSourceProvider),
    courseId: key.courseId,
    sectionId: key.sectionId,
    lectureId: key.lectureId,
    questionId: key.questionId,
    user: ref.watch(currentUserProvider),
    isInstructor: key.isInstructor,
  ),
);
