import 'package:dartz/dartz.dart';

import '../../../../core/error/failure_mapper.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../../domain/entities/__entity__.dart';
import '../../domain/repositories/__feature___repository.dart';
import '../datasources/__feature___remote_datasource.dart';

class __Feature__RepositoryImpl implements __Feature__Repository {
  __Feature__RepositoryImpl(this._remote);

  final __Feature__RemoteDataSource _remote;

  @override
  Stream<List<__Entity__>> watchAll(String uid) =>
      _remote.watchAll(uid).map((l) => l.map((m) => m.toEntity()).toList());

  @override
  ResultVoid create(String uid, String title) async {
    try {
      await _remote.create(uid, title);
      return const Right(null);
    } catch (e, st) {
      return Left(mapToFailure(e, st));
    }
  }

  @override
  ResultVoid delete(String uid, String id) async {
    try {
      await _remote.delete(uid, id);
      return const Right(null);
    } catch (e, st) {
      return Left(mapToFailure(e, st));
    }
  }
}
