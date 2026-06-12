import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../legal/presentation/widgets/legal_agreement_footer.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_sign_in_button.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).login(
          email: _email.text,
          password: _password.text,
        );
  }

  Future<void> _signInWithGoogle() =>
      ref.read(authNotifierProvider.notifier).signInWithGoogle();

  Future<void> _signInWithApple() =>
      ref.read(authNotifierProvider.notifier).signInWithApple();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    // Show snackbar on auth failure.
    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      final failure = next.failureOrNull;
      if (failure != null) context.showSnack(failure.displayMessage);
    });

    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final showAppleButton = !kIsWeb && Platform.isIOS;

    return Scaffold(
      // Transparent AppBar carries the dismiss-to-guest close icon.
      // No title — the page's own heading already announces it; an
      // empty AppBar with just the close button keeps the layout
      // anchored at the top without visual weight.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Skip — continue as guest',
            icon: const Icon(Icons.close),
            onPressed:
                isLoading ? null : () => context.go(RoutePaths.home),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: AutofillGroup(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 8),
                  Text('Welcome back', style: context.textTheme.displayLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue your lessons.',
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AuthTextField(
                    controller: _email,
                    label: t.authEmail,
                    hint: 'you@email.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.alternate_email_rounded,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _password,
                    label: t.authPassword,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.lock_outline_rounded,
                    autofillHints: const [AutofillHints.password],
                    validator: Validators.password,
                    onSubmitted: (_) => _submit(),
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading ? null : _onForgot,
                      child: Text(t.authForgotPassword),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t.authSignIn),
                  ),
                  const SizedBox(height: 24),
                  _OrDivider(label: t.authOrContinueWith),
                  const SizedBox(height: 16),
                  SocialSignInButton.google(
                    label: t.authContinueWithGoogle,
                    onPressed: isLoading ? null : _signInWithGoogle,
                  ),
                  if (showAppleButton) ...[
                    const SizedBox(height: 12),
                    SocialSignInButton.apple(
                      label: t.authContinueWithApple,
                      onPressed: isLoading ? null : _signInWithApple,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t.authNoAccount),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => context.goNamed(RouteNames.signup),
                        child: Text(t.authSignUp),
                      ),
                    ],
                  ),
                  // "Continue as guest" — drops the user into /home
                  // without an account. Guest browse mode then applies
                  // (the per-user-route allow-list in app_router.dart's
                  // _requiresAuth helper gates only routes that need a
                  // uid: subscription, wishlist, notes, etc.).
                  Center(
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () => context.go(RoutePaths.home),
                      child: const Text('Continue as guest'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const LegalAgreementFooter(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onForgot() async {
    final email = _email.text.trim();
    if (Validators.email(email) != null) {
      context.showSnack('Enter your email above first.');
      return;
    }
    final ok = await ref.read(authNotifierProvider.notifier).sendPasswordReset(email);
    if (!mounted) return;
    context.showSnack(
      ok ? 'Password reset email sent.' : 'Could not send reset email.',
    );
  }
}

/// Horizontal divider with a centered label — "─── or continue with ───".
class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Divider(color: color, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(child: Divider(color: color, height: 1)),
      ],
    );
  }
}
