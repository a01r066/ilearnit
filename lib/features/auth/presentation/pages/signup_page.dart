import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_text_field.dart';

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
    await ref.read(authNotifierProvider.notifier).signup(
          email: _email.text,
          password: _password.text,
          displayName: _name.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      final failure = next.failureOrNull;
      if (failure != null) context.showSnack(failure.displayMessage);
    });

    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
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
                    label: 'Email',
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
                    label: 'Confirm password',
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
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create account'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => context.goNamed(RouteNames.login),
                        child: const Text('Sign in'),
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
}
