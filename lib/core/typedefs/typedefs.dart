import 'package:dartz/dartz.dart';

import '../error/failure.dart';

/// `Either<Failure, T>` shorthand used by repositories and use cases.
typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultStream<T> = Stream<Either<Failure, T>>;
typedef ResultVoid = ResultFuture<void>;
typedef DataMap = Map<String, dynamic>;
