import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/data/models/user_model.dart';
import '../../../features/auth/domain/entities/user_role.dart';
import '../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../shared/providers/firebase_providers.dart';
import '../../courses/data/admin_courses_datasource.dart';
import '../../courses/data/admin_storage_service.dart';
import '../../instructors/data/admin_instructor_profiles_datasource.dart';
import '../../instructors/data/instructor_application_datasource.dart';
import '../../learning_paths/data/admin_learning_paths_datasource.dart';
import '../../songbooks/data/admin_songbooks_datasource.dart';
import '../../subscriptions/data/admin_subscriptions_datasource.dart';

// ---------- Datasources / services ----------------------------------------

final adminCoursesDataSourceProvider = Provider<AdminCoursesDataSource>(
  (ref) => AdminCoursesDataSource(firestore: ref.watch(firestoreProvider)),
);

final adminStorageServiceProvider = Provider<AdminStorageService>(
  (ref) => AdminStorageService(storage: ref.watch(firebaseStorageProvider)),
);

final instructorApplicationDataSourceProvider =
    Provider<InstructorApplicationDataSource>(
  (ref) => InstructorApplicationDataSource(
    firestore: ref.watch(firestoreProvider),
  ),
);

final adminSongbooksDataSourceProvider = Provider<AdminSongbooksDataSource>(
  (ref) => AdminSongbooksDataSource(firestore: ref.watch(firestoreProvider)),
);

final adminInstructorProfilesDataSourceProvider =
    Provider<AdminInstructorProfilesDataSource>(
  (ref) => AdminInstructorProfilesDataSource(
    firestore: ref.watch(firestoreProvider),
  ),
);

final adminLearningPathsDataSourceProvider =
    Provider<AdminLearningPathsDataSource>(
  (ref) => AdminLearningPathsDataSource(ref.watch(firestoreProvider)),
);

final adminSubscriptionsDataSourceProvider =
    Provider<AdminSubscriptionsDataSource>(
  (ref) => AdminSubscriptionsDataSource(
    firestore: ref.watch(firestoreProvider),
  ),
);

// ---------- Current admin user / role -------------------------------------

/// Streams the signed-in user's full Firestore profile (with role +
/// suspension flag) — null when signed out.
///
/// Reads from `users/{uid}` so role changes (e.g. an admin approving an
/// application) propagate to the UI in real time without a re-login.
final currentAdminUserProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref.watch(adminCoursesDataSourceProvider).watchUser(user.id);
});

/// Resolves the active [UserRole] from the currentAdminUserProvider.
///
/// Convenience selector: returns `null` while loading/signed out, otherwise
/// the parsed role. Use this for fast role-based UI gating; for stricter
/// guards prefer the redirect logic in `admin_router.dart`.
final currentRoleProvider = Provider<UserRole?>((ref) {
  final user = ref.watch(currentAdminUserProvider).value;
  if (user == null) return null;
  return UserRole.fromId(user.role);
});
