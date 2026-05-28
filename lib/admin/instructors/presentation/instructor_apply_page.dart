import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/presentation/providers/auth_providers.dart';
import '../../routing/admin_route_names.dart';
import '../../shared/providers/admin_providers.dart';
import '../domain/entities/application_status.dart';
import '../domain/entities/instructor_application.dart';

/// Form for a signed-in student to apply to become an instructor.
///
/// If the user already has a pending or approved application we redirect
/// them — the actual redirect logic lives in `admin_router.dart`, but
/// we also short-circuit the UI here for resilience.
class InstructorApplyPage extends ConsumerStatefulWidget {
  const InstructorApplyPage({super.key});

  @override
  ConsumerState<InstructorApplyPage> createState() =>
      _InstructorApplyPageState();
}

class _InstructorApplyPageState extends ConsumerState<InstructorApplyPage> {
  final _formKey = GlobalKey<FormState>();
  final _bio = TextEditingController();
  final _years = TextEditingController();
  final _portfolio = TextEditingController();
  final _instruments = <String>{'guitar'};
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _bio.dispose();
    _years.dispose();
    _portfolio.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_instruments.isEmpty) {
      setState(() => _error = 'Pick at least one instrument.');
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref
          .read(instructorApplicationDataSourceProvider)
          .submit(InstructorApplication(
            id: user.id,
            userId: user.id,
            displayName: user.displayName ?? user.email,
            email: user.email,
            bio: _bio.text.trim(),
            instruments: _instruments.toList(),
            years: int.tryParse(_years.text.trim()),
            portfolioUrl:
                _portfolio.text.trim().isEmpty ? null : _portfolio.text.trim(),
            status: ApplicationStatus.pending,
          ));
      if (mounted) context.goNamed(AdminRoutes.pending);
    } catch (e) {
      setState(() => _error = 'Could not submit: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Become an instructor')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Tell us about you',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    'An admin reviews each application. You will get '
                    'instructor access on approval.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _bio,
                    decoration: const InputDecoration(
                      labelText: 'Short bio',
                      hintText:
                          'Your teaching background, performance history…',
                    ),
                    minLines: 4,
                    maxLines: 8,
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.length < 30) {
                        return 'At least 30 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _years,
                          decoration: const InputDecoration(
                            labelText: 'Years teaching',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _portfolio,
                          decoration: const InputDecoration(
                            labelText: 'Portfolio URL (optional)',
                          ),
                          keyboardType: TextInputType.url,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Which instruments do you teach?',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final inst in const ['guitar', 'piano', 'violin'])
                        FilterChip(
                          label: Text(inst[0].toUpperCase() + inst.substring(1)),
                          selected: _instruments.contains(inst),
                          onSelected: (sel) {
                            setState(() {
                              if (sel) {
                                _instruments.add(inst);
                              } else {
                                _instruments.remove(inst);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!,
                        style: TextStyle(color: theme.colorScheme.error)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit application'),
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
