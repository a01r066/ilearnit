import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/validators.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/auth/presentation/widgets/social_sign_in_button.dart';

/// Email/password + Google + Apple sign-in for the admin portal.
///
/// Reuses [AuthNotifier] — the role-based redirect in `admin_router.dart`
/// decides where the user lands after a successful sign-in:
///   • student → /apply
///   • instructor or admin → /
///   • suspended → /unauthorized
///
/// All three flows go through the same notifier, so the failure-snackbar
/// listener handles every error path uniformly.
class AdminLoginPage extends ConsumerStatefulWidget {
  const AdminLoginPage({super.key});

  @override
  ConsumerState<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends ConsumerState<AdminLoginPage> {
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

  Future<void> _google() =>
      ref.read(authNotifierProvider.notifier).signInWithGoogle();

  Future<void> _apple() =>
      ref.read(authNotifierProvider.notifier).signInWithApple();

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      final failure = next.failureOrNull;
      if (failure != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.displayMessage)),
        );
      }
    });

    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.music_note_rounded,
                          color: theme.colorScheme.primary, size: 28),
                      const SizedBox(width: 8),
                      Text('iLearnIt Admin',
                          style: theme.textTheme.headlineSmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to manage courses and instructors.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign in'),
                  ),

                  // --- Social sign-in -----------------------------------
                  const SizedBox(height: 24),
                  const _OrDivider(label: 'or continue with'),
                  const SizedBox(height: 16),
                  SocialSignInButton.google(
                    label: 'Continue with Google',
                    onPressed: isLoading ? null : _google,
                  ),
                  const SizedBox(height: 12),
                  // Apple via signInWithPopup works in any browser — admins
                  // on macOS/iPadOS will get the smoother native sheet, but
                  // the same code path serves everyone.
                  SocialSignInButton.apple(
                    label: 'Continue with Apple',
                    onPressed: isLoading ? null : _apple,
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'New here? Use the mobile app to create an account, '
                    'then come back to apply as an instructor.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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

/// Inline copy of the divider widget used by the consumer login — kept here
/// rather than imported so the admin module stays self-contained.
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
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: Divider(color: color, height: 1)),
      ],
    );
  }
}
