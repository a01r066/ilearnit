import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/instructors/data/models/instructor_model.dart';
import '../../routing/admin_route_names.dart';
import '../../shared/providers/admin_providers.dart';

/// Single-page editor for one [InstructorModel]. Same minimal flat
/// pattern used everywhere else in the admin portal — no Form, no
/// DropdownButtonFormField, no Card.
class InstructorProfileEditorPage extends ConsumerStatefulWidget {
  const InstructorProfileEditorPage({super.key, required this.instructorId});

  final String instructorId;

  @override
  ConsumerState<InstructorProfileEditorPage> createState() =>
      _InstructorProfileEditorPageState();
}

class _InstructorProfileEditorPageState
    extends ConsumerState<InstructorProfileEditorPage> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _tagline = TextEditingController();
  final _country = TextEditingController();
  final _years = TextEditingController();
  final _photoUrl = TextEditingController();
  final _specialties = TextEditingController();
  final _website = TextEditingController();
  final _facebook = TextEditingController();
  final _twitter = TextEditingController();
  final _youtube = TextEditingController();
  final _instagram = TextEditingController();

  String? _primaryInstrument;
  bool _hydrated = false;
  bool _saving = false;

  static const _instruments = <MapEntry<String?, String>>[
    MapEntry<String?, String>(null, 'Unspecified'),
    MapEntry<String?, String>('guitar', 'Guitar'),
    MapEntry<String?, String>('piano', 'Piano'),
    MapEntry<String?, String>('violin', 'Violin'),
  ];

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _tagline.dispose();
    _country.dispose();
    _years.dispose();
    _photoUrl.dispose();
    _specialties.dispose();
    _website.dispose();
    _facebook.dispose();
    _twitter.dispose();
    _youtube.dispose();
    _instagram.dispose();
    super.dispose();
  }

  void _hydrate(InstructorModel m) {
    _name.text = m.name;
    _bio.text = m.bio;
    _tagline.text = m.tagline ?? '';
    _country.text = m.country ?? '';
    _years.text = m.yearsExperience?.toString() ?? '';
    _photoUrl.text = m.photoUrl;
    _specialties.text = m.specialties.join(', ');
    _website.text = m.websiteUrl ?? '';
    _facebook.text = m.facebookUrl ?? '';
    _twitter.text = m.twitterUrl ?? '';
    _youtube.text = m.youtubeUrl ?? '';
    _instagram.text = m.instagramUrl ?? '';
    _primaryInstrument = m.primaryInstrument;
    _hydrated = true;
  }

  Future<void> _save(InstructorModel current) async {
    setState(() => _saving = true);
    try {
      final updated = current.copyWith(
        name: _name.text.trim(),
        bio: _bio.text.trim(),
        tagline: _tagline.text.trim().isEmpty ? null : _tagline.text.trim(),
        country: _country.text.trim().isEmpty ? null : _country.text.trim(),
        yearsExperience: int.tryParse(_years.text.trim()),
        photoUrl: _photoUrl.text.trim(),
        primaryInstrument: _primaryInstrument,
        specialties: _splitCsv(_specialties.text),
        websiteUrl: _emptyToNull(_website.text),
        facebookUrl: _emptyToNull(_facebook.text),
        twitterUrl: _emptyToNull(_twitter.text),
        youtubeUrl: _emptyToNull(_youtube.text),
        instagramUrl: _emptyToNull(_instagram.text),
      );
      await ref
          .read(adminInstructorProfilesDataSourceProvider)
          .update(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String? _emptyToNull(String v) =>
      v.trim().isEmpty ? null : v.trim();

  static List<String> _splitCsv(String input) => input
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    final stream = ref
        .watch(adminInstructorProfilesDataSourceProvider)
        .watchById(widget.instructorId);

    return StreamBuilder<InstructorModel?>(
      stream: stream,
      builder: (context, snap) {
        if (!snap.hasData && !_hydrated) {
          return const Center(child: CircularProgressIndicator());
        }
        final m = snap.data;
        if (m == null) {
          return const Center(child: Text('Instructor not found.'));
        }
        if (!_hydrated) _hydrate(m);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  title: _name.text.isEmpty ? '(unnamed)' : _name.text,
                  saving: _saving,
                  onSave: () => _save(m),
                  onBack: () =>
                      context.goNamed(AdminRoutes.instructorProfiles),
                ),
                const SizedBox(height: 24),
                _Panel(
                  title: 'Identity',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _photoPreview(context),
                      const SizedBox(height: 12),
                      _Field(
                          label: 'Photo URL',
                          controller: _photoUrl,
                          hint:
                              'https://i.pravatar.cc/320?u=… or Firebase Storage URL'),
                      _Field(label: 'Name', controller: _name),
                      _Field(
                          label: 'Tagline',
                          controller: _tagline,
                          hint:
                              'One-line subtitle shown under the name'),
                      _Field(
                          label: 'Bio',
                          controller: _bio,
                          maxLines: 4),
                      const SizedBox(height: 4),
                      Text('Primary instrument',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final e in _instruments)
                            ChoiceChip(
                              label: Text(e.value),
                              selected: _primaryInstrument == e.key,
                              onSelected: (s) {
                                if (s) {
                                  setState(() =>
                                      _primaryInstrument = e.key);
                                }
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _Field(
                                label: 'Country',
                                controller: _country),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _Field(
                                label: 'Years experience',
                                controller: _years,
                                keyboard: TextInputType.number),
                          ),
                        ],
                      ),
                      _Field(
                        label: 'Specialties (comma-separated)',
                        controller: _specialties,
                        hint: 'spanish-classical, fingerstyle, sor',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _Panel(
                  title: 'Social',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Field(label: 'Website', controller: _website),
                      _Field(label: 'Facebook', controller: _facebook),
                      _Field(label: 'Twitter / X', controller: _twitter),
                      _Field(label: 'YouTube', controller: _youtube),
                      _Field(label: 'Instagram', controller: _instagram),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 200,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : () => _save(m),
                    icon: _saving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save changes'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _photoPreview(BuildContext context) {
    final theme = Theme.of(context);
    final url = _photoUrl.text.trim();
    return Center(
      child: SizedBox(
        width: 120,
        height: 120,
        child: ClipOval(
          child: url.isEmpty
              ? Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.person_outline, size: 48),
                )
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined,
                        size: 48),
                  ),
                ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.saving,
    required this.onSave,
    required this.onBack,
  });
  final String title;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: onBack,
        ),
        Expanded(
          child: Text(title, style: theme.textTheme.headlineSmall),
        ),
        SizedBox(
          width: 160,
          child: FilledButton.icon(
            icon: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Save'),
            onPressed: saving ? null : onSave,
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.keyboard,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}
