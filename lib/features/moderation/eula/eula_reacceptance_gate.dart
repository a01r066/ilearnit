import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_names.dart';
import '../../../shared/providers/firebase_providers.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import 'eula_acceptance_service.dart';
import 'eula_version.dart';

/// One-shot re-acceptance prompt for users whose stored
/// `eulaAcceptedVersion` is older than [kCurrentEulaVersion].
///
/// Mount once at the top of the shell scaffold (one prompt per app
/// session). The widget renders no UI on its own — it observes the
/// signed-in user and pushes a non-dismissible modal sheet when a
/// re-prompt is needed.
///
/// Why a non-dismissible sheet (not a route): the user is already
/// inside the app, has already accepted *some* version, and we only
/// need a quick reconfirm. A full route push would feel
/// disproportionate, and a swipe-down dismissal would let users sneak
/// past the gate.
class EulaReacceptanceGate extends ConsumerStatefulWidget {
  const EulaReacceptanceGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<EulaReacceptanceGate> createState() =>
      _EulaReacceptanceGateState();
}

class _EulaReacceptanceGateState extends ConsumerState<EulaReacceptanceGate> {
  /// True once we've shown a prompt for the current sign-in session.
  /// Cleared when the user signs out so the next sign-in can re-trigger.
  bool _shownThisSession = false;
  String? _lastUid;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    // Reset the per-session flag if the signed-in user changes (sign
    // out → sign in as someone else).
    if (user?.id != _lastUid) {
      _shownThisSession = false;
      _lastUid = user?.id;
    }

    if (user != null &&
        !_shownThisSession &&
        user.eulaAcceptedVersion < kCurrentEulaVersion) {
      _shownThisSession = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _show(context, user.id);
      });
    }

    return widget.child;
  }

  Future<void> _show(BuildContext context, String uid) async {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (sheetCtx) => _EulaSheet(uid: uid),
    );
  }
}

class _EulaSheet extends ConsumerStatefulWidget {
  const _EulaSheet({required this.uid});
  final String uid;

  @override
  ConsumerState<_EulaSheet> createState() => _EulaSheetState();
}

class _EulaSheetState extends ConsumerState<_EulaSheet> {
  bool _accepting = false;

  Future<void> _accept() async {
    if (_accepting) return;
    setState(() => _accepting = true);
    try {
      await EulaAcceptanceService(ref.read(firestoreProvider)).accept(
        uid: widget.uid,
        version: kCurrentEulaVersion,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _accepting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not accept: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      // Disable the system back button — the user must accept or sign
      // out. (Signing out is reachable via Profile if they wish.)
      canPop: false,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.handshake_outlined,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Updated agreement',
                      style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ve updated our Terms and Community Guidelines '
                '($kCurrentEulaPublishedLabel). Please review and accept '
                'to continue using iLearnIt.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _accepting
                          ? null
                          : () => context.pushNamed(
                                RouteNames.legal,
                                pathParameters: {'slug': 'terms'},
                              ),
                      child: const Text('Read terms'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _accepting
                          ? null
                          : () => context.pushNamed(
                                RouteNames.legal,
                                pathParameters: {'slug': 'community'},
                              ),
                      child: const Text('Read guidelines'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _accepting ? null : _accept,
                  child: _accepting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('I accept'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
