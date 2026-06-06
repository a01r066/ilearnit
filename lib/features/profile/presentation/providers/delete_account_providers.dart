import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import 'delete_account_notifier.dart';
import 'delete_account_state.dart';

/// Scoped to the lifetime of [DeleteAccountPage]. AutoDispose ensures the
/// state is reset whenever the user backs out and re-enters the flow.
final deleteAccountNotifierProvider = StateNotifierProvider.autoDispose<
    DeleteAccountNotifier, DeleteAccountState>(
  (ref) => DeleteAccountNotifier(ref.watch(authRepositoryProvider)),
);
