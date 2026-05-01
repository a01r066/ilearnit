import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_text_field.dart';

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

  @override
  Widget build(BuildContext context) {
    // Show snackbar on auth failure.
    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      final failure = next.failureOrNull;
      if (failure != null) context.showSnack(failure.displayMessage);
    });

    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: AutofillGroup(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 24),
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
                    label: 'Email',
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
                    label: 'Password',
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
                      child: const Text('Forgot password?'),
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
                        : const Text('Sign in'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => context.goNamed(RouteNames.signup),
                        child: const Text('Sign up'),
                      ),
                    ],
                  ),
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
