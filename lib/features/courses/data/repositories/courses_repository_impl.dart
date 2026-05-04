import 'package:dartz/dartz.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/entities/course_section_entity.dart';
import '../../domain/entities/instrument_category.dart';
import '../../domain/repositories/courses_repository.dart';
import '../datasources/courses_remote_datasource.dart';

class CoursesRepositoryImpl implements CoursesRepository {
  CoursesRepositoryImpl({
    required CoursesRemoteDataSource remote,
    required NetworkInfo network,
  })  : _remote = remote,
        _network = network;

  final CoursesRemoteDataSource _remote;
  final NetworkInfo _network;

  @override
  ResultFuture<CoursesPage> fetchCourses({
    InstrumentCategory? category,
    CourseLevel? level,
    String? cursor,
    int limit = 20,
  }) async {
    if (!await _network.isConnected) {
      return const Left(Failure.network());
    }
    try {
      final dto = await _remote.fetchCourses(
        category: category,
        level: level,
        cursor: cursor,
        limit: limit,
      );
      return Right(
        CoursesPage(
          items: dto.items.map((m) => m.toEntity()).toList(),
          nextCursor: dto.nextCursor,
          hasMore: dto.hasMore,
        ),
      );
    } catch (e, st) {
      return Left(mapToFailure(e, st));
    }
  }

  @override
  ResultFuture<CourseEntity> fetchCourseById(String id) async {
    if (!await _network.isConnected) {
      return const Left(Failure.network());
    }
    try {
      final model = await _remote.fetchCourseById(id);
      return Right(model.toEntity());
    } catch (e, st) {
      return Left(mapToFailure(e, st));
    }
  }

  @override
  ResultFuture<List<CourseEntity>> fetchFeatured({int limit = 5}) async {
    if (!await _network.isConnected) {
      return const Left(Failure.network());
    }
    try {
      final list = await _remote.fetchFeatured(limit: limit);
      return Right(list.map((m) => m.toEntity()).toList());
    } catch (e, st) {
      return Left(mapToFailure(e, st));
    }
  }

  @override
  ResultFuture<List<CourseSectionEntity>> fetchSections(String courseId) async {
    if (!await _network.isConnected) {
      return const Left(Failure.network());
    }
    try {
      final list = await _remote.fetchSections(courseId);
      return Right(list.map((m) => m.toEntity()).toList());
    } catch (e, st) {
      return Left(mapToFailure(e, st));
    }
  }
}
