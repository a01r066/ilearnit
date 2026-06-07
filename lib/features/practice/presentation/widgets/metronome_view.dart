import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/time_signature.dart';
import '../providers/metronome_notifier.dart';
import '../providers/metronome_state.dart';
import '../providers/practice_providers.dart';

/// Metronome controls: BPM display + slider + ± buttons, time-signature
/// segmented selector, tap-tempo button, start/stop FAB.
class MetronomeView extends ConsumerWidget {
  const MetronomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(metronomeNotifierProvider);
    final notifier = ref.read(metronomeNotifierProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        const _AnimatedBeatRing(),
        const SizedBox(height: 24),
        _BpmReadout(bpm: state.bpm),
        const SizedBox(height: 16),
        _BpmControls(notifier: notifier, state: state),
        const SizedBox(height: 32),
        _SectionLabel(t.metronomeTimeSignature),
        const SizedBox(height: 8),
        _SignatureRow(state: state, notifier: notifier),
        const SizedBox(height: 32),
        _SectionLabel(t.metronomeTapTempo),
        const SizedBox(height: 8),
        _TapTempoButton(onTap: notifier.tap, label: t.metronomeTapHere),
        const SizedBox(height: 32),
        _PlayButton(
          isRunning: state.isRunning,
          onPressed: notifier.toggle,
          startLabel: t.metronomeStart,
          stopLabel: t.metronomeStop,
        ),
      ],
    );
  }
}

// ---------- Beat ring (visual heartbeat) ---------------------------------

class _AnimatedBeatRing extends ConsumerStatefulWidget {
  const _AnimatedBeatRing();

  @override
  ConsumerState<_AnimatedBeatRing> createState() => _AnimatedBeatRingState();
}

class _AnimatedBeatRingState extends ConsumerState<_AnimatedBeatRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pulse on every state tick — bpm changes nudge the controller.
    ref.listen(metronomeNotifierProvider, (_, next) {
      if (next.isRunning) {
        _ctrl.duration = Duration(
          milliseconds: (60000 / next.bpm).round(),
        );
        _ctrl.repeat();
      } else {
        _ctrl.stop();
        _ctrl.value = 0;
      }
    });

    return Center(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final scale = 0.92 + (1 - _ctrl.value) * 0.12;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppColors.primary
                      .withValues(alpha: 0.40 + _ctrl.value * 0.40),
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.music_note_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------- BPM ------------------------------------------------------------

class _BpmReadout extends StatelessWidget {
  const _BpmReadout({required this.bpm});
  final int bpm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$bpm',
          style: context.textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
        Text(
          'BPM',
          style: context.textTheme.titleMedium?.copyWith(
            letterSpacing: 2,
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BpmControls extends StatelessWidget {
  const _BpmControls({required this.notifier, required this.state});
  final MetronomeNotifier notifier;
  final MetronomeState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Round(
          icon: Icons.remove_rounded,
          onTap: () => notifier.setBpm(state.bpm - 1),
        ),
        Expanded(
          child: Slider(
            value: state.bpm.toDouble(),
            min: PracticeConstants.minBpm.toDouble(),
            max: PracticeConstants.maxBpm.toDouble(),
            onChanged: (v) => notifier.setBpm(v.round()),
          ),
        ),
        _Round(
          icon: Icons.add_rounded,
          onTap: () => notifier.setBpm(state.bpm + 1),
        ),
      ],
    );
  }
}

class _Round extends StatelessWidget {
  const _Round({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: 0.10),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.30),
          ),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}

// ---------- Time signature -----------------------------------------------

class _SignatureRow extends StatelessWidget {
  const _SignatureRow({required this.state, required this.notifier});

  final MetronomeState state;
  final MetronomeNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: TimeSignature.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final sig = TimeSignature.values[i];
          final selected = sig == state.signature;
          return InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => notifier.setSignature(sig),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.primary
                      .withValues(alpha: selected ? 1 : 0.30),
                ),
              ),
              child: Text(
                sig.label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------- Tap tempo -----------------------------------------------------

class _TapTempoButton extends StatelessWidget {
  const _TapTempoButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 80,
          alignment: Alignment.center,
          child: Text(
            label,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Section label -------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: context.textTheme.labelSmall?.copyWith(
        letterSpacing: 1.4,
        fontWeight: FontWeight.w800,
        color: context.colors.onSurfaceVariant,
      ),
    );
  }
}

// ---------- Play / Stop ---------------------------------------------------

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isRunning,
    required this.onPressed,
    required this.startLabel,
    required this.stopLabel,
  });

  final bool isRunning;
  final VoidCallback onPressed;
  final String startLabel;
  final String stopLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        icon: Icon(isRunning
            ? Icons.stop_rounded
            : Icons.play_arrow_rounded),
        label: Text(isRunning ? stopLabel : startLabel),
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor:
              isRunning ? AppColors.error : AppColors.primary,
        ),
      ),
    );
  }
}
