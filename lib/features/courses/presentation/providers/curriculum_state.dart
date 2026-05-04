import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/course_section_entity.dart';

part 'curriculum_state.freezed.dart';

@freezed
abstract class CurriculumState with _$CurriculumState {
  const CurriculumState._();

  const factory CurriculumState.loading() = _Loading;
  const factory CurriculumState.error(Failure failure) = _Error;
  const factory CurriculumState.loaded(List<CourseSectionEntity> sections) =
      _Loaded;

  bool get isLoading => this is _Loading;
}
