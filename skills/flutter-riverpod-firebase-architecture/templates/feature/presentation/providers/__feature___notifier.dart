import 'package:flutter_riverpod/legacy.dart';

import '../../domain/repositories/__feature___repository.dart';
import '__feature___state.dart';

class __Feature__Notifier extends StateNotifier<__Feature__State> {
  __Feature__Notifier({required this.uid, required this.repo})
      : super(const __Feature__State());

  /// Empty for guests — mutations become no-ops.
  final String uid;
  final __Feature__Repository repo;

  Future<bool> create(String title) async {
    if (uid.isEmpty || state.isSaving) return false;
    state = state.copyWith(isSaving: true, errorMessage: null);
    final result = await repo.create(uid, title.trim());
    if (!mounted) return false;
    return result.fold(
      (f) {
        state = state.copyWith(isSaving: false, errorMessage: f.displayMessage);
        return false;
      },
      (_) {
        state = state.copyWith(isSaving: false);
        return true;
      },
    );
  }

  Future<void> delete(String id) async {
    final result = await repo.delete(uid, id);
    result.fold(
      (f) => state = state.copyWith(errorMessage: f.displayMessage),
      (_) {},
    );
  }
}
