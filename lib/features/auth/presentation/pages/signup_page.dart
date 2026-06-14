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

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  // Apple App Review 1.2 + Google Play UGC require explicit
  // affirmative consent before account creation. Submit is disabled
  // until the user checks the box; the agreed version is stamped on
  // the user doc during signup via `kCurrentEulaVersion`.
  bool _agreed = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      // Defensive — button is also disabled when _agreed is false. This
      // branch fires when an autofill-driven enter-key press skips the
      // gate.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please accept the Terms and Community Guidelines to continue.',
          ),
        ),
      );
      return;
    }
    await ref.read(authNotifierProvider.notifier).signup(
          email: _email.text,
          password: _password.text,
          displayName: _name.text.trim(),
        );
  }

  Future<void> _signInWithGoogle() =>
      ref.read(authNotifierProvider.notifier).signInWithGoogle();

  Future<void> _signInWithApple() =>
      ref.read(authNotifierProvider.notifier).signInWithApple();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      final failure = next.failureOrNull;
      if (failure != null) context.showSnack(failure.displayMessage);
    });

    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final showAppleButton = !kIsWeb && Platform.isIOS;

    return Scaffold(
      // Close icon dismisses sign-up and drops the user into /home as
      // a guest — matches the LoginPage skip behaviour so the two
      // entry points feel symmetric.
      appBar: AppBar(
        title: const Text('Create account'),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 8),
                  Text('Welcome to iLearnIt',
                      style: context.textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Pick up your instrument — guitar, piano or violin.',
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AuthTextField(
                    controller: _name,
                    label: 'Display name',
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.person_outline_rounded,
                    autofillHints: const [AutofillHints.name],
                    validator: (v) =>
                        Validators.required(v, label: 'Display name'),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _email,
                    label: t.authEmail,
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
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.lock_outline_rounded,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: Validators.password,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _confirm,
                    label: t.authConfirmPassword,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.lock_outline_rounded,
                    onSubmitted: (_) => _submit(),
                    validator: (v) => Validators.matches(
                      v,
                      _password.text,
                      label: 'Confirmation',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // EULA / Community Guidelines acceptance — required
                  // for App Store review (UGC apps must collect
                  // affirmative consent before account creation).
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreed,
                        onChanged: isLoading
                            ? null
                            : (v) => setState(() => _agreed = v ?? false),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text('I agree to the '),
                              GestureDetector(
                                onTap: () => context.pushNamed(
                                  RouteNames.legal,
                                  pathParameters: {'slug': 'terms'},
                                ),
                                child: Text(
                                  'Terms',
                                  style: TextStyle(
                                    color: context.colors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const Text(' and '),
                              GestureDetector(
                                onTap: () => context.pushNamed(
                                  RouteNames.legal,
                                  pathParameters: {'slug': 'community'},
                                ),
                                child: Text(
                                  'Community Guidelines',
                                  style: TextStyle(
                                    color: context.colors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const Text(
                                '. I will not post abusive, illegal, '
                                'or objectionable content.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: (isLoading || !_agreed) ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create account'),
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t.authHaveAccount),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => context.goNamed(RouteNames.login),
                        child: Text(t.authSignIn),
                      ),
                    ],
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
}

/// Horizontal divider with a centered label — same as the one on Login.
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
