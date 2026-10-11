import '../../../../core/typedefs/typedefs.dart';
import '../entities/__entity__.dart';

abstract interface class __Feature__Repository {
  Stream<List<__Entity__>> watchAll(String uid);
  ResultVoid create(String uid, String title);
  ResultVoid delete(String uid, String id);
}
