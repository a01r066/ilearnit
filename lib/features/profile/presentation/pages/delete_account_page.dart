import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/social_sign_in_button.dart';
import '../providers/delete_account_notifier.dart';
import '../providers/delete_account_providers.dart';
import '../providers/delete_account_state.dart';

/// Apple §5.1.1(v) — in-app account deletion.
///
/// Three-section layout:
///   1. Warning card (red-tinted) explaining what is deleted.
///   2. Re-authentication form, branched on sign-in method:
///        - email/password account → password field + button
///        - Google account → Google re-sign-in button
///        - Apple account → Apple re-sign-in button
///   3. Destructive confirm — a checkbox plus a type-to-confirm dialog
///      gating the final "Delete my account" button. Calls the
///      `deleteAccount` Cloud Function via the AuthRepository.
class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  final _passwordCtrl = TextEditingController();
  bool _acknowledged = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Inspects `FirebaseAuth.currentUser.providerData` to determine which
  /// re-auth flow to render. Falls back to password if the provider list
  /// is empty (shouldn't happen but defensively handled).
  _SignInMethod _signInMethod() {
    final providers = fb_auth.FirebaseAuth.instance.currentUser?.providerData
            .map((p) => p.providerId)
            .toSet() ??
        const <String>{};
    if (providers.contains('google.com')) return _SignInMethod.google;
    if (providers.contains('apple.com')) return _SignInMethod.apple;
    return _SignInMethod.password;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(deleteAccountNotifierProvider);
    final notifier = ref.read(deleteAccountNotifierProvider.notifier);
    final method = _signInMethod();

    // Side-effects: snackbars + post-success routing.
    ref.listen<DeleteAccountState>(deleteAccountNotifierProvider, (_, next) {
      if (next.lastFailure != null) {
        context.showSnack(next.lastFailure!.displayMessage);
      }
      if (next.isCompleted) {
        // The remote already deleted the auth user; logout is a defensive
        // belt-and-braces so any subscribed listeners see `null` immediately.
        ref.read(authNotifierProvider.notifier).logout();
        context.showSnack(t.deleteAccountSuccess);
        // Use `go` not `push` so the user can't swipe back into the now-
        // dead session.
        context.go(RoutePaths.login);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(t.deleteAccountTitle)),
      body: AbsorbPointer(
        absorbing: state.isDeleting,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            _WarningCard(
              header: t.deleteAccountWarningHeader,
              body: t.deleteAccountWarningBody,
            ),
            const SizedBox(height: 16),
            _SubscriptionNote(text: t.deleteAccountSubscriptionNote),
            const SizedBox(height: 24),
            _ReauthSection(
              method: method,
              passwordCtrl: _passwordCtrl,
              state: state,
              onPasswordSubmit: () => notifier
                  .reauthenticateWithPassword(_passwordCtrl.text),
              onGoogle: () => notifier.reauthenticateWithGoogle(),
              onApple: () => notifier.reauthenticateWithApple(),
            ),
            const SizedBox(height: 24),
            CheckboxListTile(
              value: _acknowledged,
              onChanged: state.isReauthenticated
                  ? (v) => setState(() => _acknowledged = v ?? false)
                  : null,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(t.deleteAccountConfirmCheckbox),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: state.isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.delete_forever_rounded),
              label: Text(state.isDeleting
                  ? t.deleteAccountInProgress
                  : t.deleteAccountSubmit),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: (state.isReauthenticated &&
                      _acknowledged &&
                      !state.isBusy)
                  ? () => _confirmAndDelete(notifier)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Final type-to-confirm dialog. Returning `true` from the dialog kicks
  /// off the Cloud Function call.
  Future<void> _confirmAndDelete(DeleteAccountNotifier notifier) async {
    final t = AppLocalizations.of(context);
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final isValid = controller.text.trim().toUpperCase() == 'DELETE';
          return AlertDialog(
            title: Text(t.deleteAccountConfirmTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.deleteAccountConfirmBody),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: t.deleteAccountConfirmHint,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setLocal(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(t.commonCancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                onPressed: isValid
                    ? () => Navigator.of(ctx).pop(true)
                    : null,
                child: Text(t.deleteAccountSubmit),
              ),
            ],
          );
        },
      ),
    );

    controller.dispose();
    if (confirmed != true || !mounted) return;
    await notifier.confirmDelete();
  }
}

enum _SignInMethod { password, google, apple }

// ---------- widgets -------------------------------------------------------

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.header, required this.body});
  final String header;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  header,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 6),
                Text(body, style: context.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionNote extends StatelessWidget {
  const _SubscriptionNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReauthSection extends StatelessWidget {
  const _ReauthSection({
    required this.method,
    required this.passwordCtrl,
    required this.state,
    required this.onPasswordSubmit,
    required this.onGoogle,
    required this.onApple,
  });

  final _SignInMethod method;
  final TextEditingController passwordCtrl;
  final DeleteAccountState state;
  final VoidCallback onPasswordSubmit;
  final VoidCallback onGoogle;
  final VoidCallback onApple;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final reauthed = state.isReauthenticated;

    if (reauthed) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                method == _SignInMethod.password
                    ? t.deleteAccountReauthIntro
                    : t.deleteAccountReauthIntroSocial,
                style: context.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    switch (method) {
      case _SignInMethod.password:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.deleteAccountReauthIntro,
                style: context.textTheme.bodyMedium),
            const SizedBox(height: 12),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: t.authPassword,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => onPasswordSubmit(),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: state.isBusy ? null : onPasswordSubmit,
              child: state.isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.authSignIn),
            ),
          ],
        );
      case _SignInMethod.google:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.deleteAccountReauthIntroSocial,
                style: context.textTheme.bodyMedium),
            const SizedBox(height: 12),
            SocialSignInButton.google(
              onPressed: state.isBusy ? null : onGoogle,
              label: t.deleteAccountReauthGoogle,
            ),
          ],
        );
      case _SignInMethod.apple:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.deleteAccountReauthIntroSocial,
                style: context.textTheme.bodyMedium),
            const SizedBox(height: 12),
            SocialSignInButton.apple(
              onPressed: state.isBusy ? null : onApple,
              label: t.deleteAccountReauthApple,
            ),
          ],
        );
    }
  }
}
