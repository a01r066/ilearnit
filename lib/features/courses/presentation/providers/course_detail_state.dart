import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/course_entity.dart';

part 'course_detail_state.freezed.dart';

@freezed
class CourseDetailState with _$CourseDetailState {
  const factory CourseDetailState.loading() = _Loading;
  const factory CourseDetailState.error(Failure failure) = _Error;
  const factory CourseDetailState.loaded(CourseEntity course) = _Loaded;
}
