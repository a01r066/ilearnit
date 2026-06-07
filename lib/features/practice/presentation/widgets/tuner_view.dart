import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/services/pitch_math.dart';
import '../providers/practice_providers.dart';

/// Tuner: large note name + cents readout + color-coded gauge that
/// swings left (flat) or right (sharp). Auto-stops capture when the
/// page is left.
class TunerView extends ConsumerStatefulWidget {
  const TunerView({super.key});

  @override
  ConsumerState<TunerView> createState() => _TunerViewState();
}

class _TunerViewState extends ConsumerState<TunerView> {
  @override
  void dispose() {
    // TabBarView keeps children alive across swipes, but if the user
    // pops the Practice page we want to surrender the mic.
    Future.microtask(() {
      ref.read(tunerNotifierProvider.notifier).stop();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(tunerNotifierProvider);
    final notifier = ref.read(tunerNotifierProvider.notifier);
    final reading = state.reading;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Center(
          child: Text(
            reading.isSilent ? '—' : reading.displayLabel,
            style: context.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 96,
              color: _colorFor(reading),
            ),
          ),
        ),
        Center(
          child: Text(
            reading.isSilent
                ? t.tunerListening
                : '${reading.cents.toStringAsFixed(0)} ¢',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 32),
        _CentsGauge(reading: reading),
        const SizedBox(height: 24),
        Center(
          child: Text(
            _hintFor(reading, t),
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 32),
        if (state.permissionDenied)
          _PermissionDeniedBanner(label: t.tunerPermissionDenied)
        else
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              icon: Icon(state.isListening
                  ? Icons.mic_off_rounded
                  : Icons.mic_rounded),
              label: Text(state.isListening ? t.tunerStop : t.tunerStart),
              style: FilledButton.styleFrom(
                backgroundColor: state.isListening
                    ? AppColors.error
                    : AppColors.primary,
              ),
              onPressed: () => state.isListening
                  ? notifier.stop()
                  : notifier.start(),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          t.tunerHint,
          textAlign: TextAlign.center,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _hintFor(PitchReading r, AppLocalizations t) {
    if (r.isSilent) return t.tunerHintSilent;
    if (r.isInTune) return t.tunerHintInTune;
    if (r.isFlat) return t.tunerHintFlat;
    return t.tunerHintSharp;
  }

  Color _colorFor(PitchReading r) {
    if (r.isSilent) return AppColors.primary;
    if (r.isInTune) return AppColors.success;
    if (r.isClose) return AppColors.warning;
    return AppColors.error;
  }
}

// ---------- Gauge ---------------------------------------------------------

class _CentsGauge extends StatelessWidget {
  const _CentsGauge({required this.reading});
  final PitchReading reading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: CustomPaint(
        painter: _GaugePainter(
          cents: reading.cents,
          active: !reading.isSilent,
          colorScheme: Theme.of(context).colorScheme,
        ),
        size: const Size(double.infinity, 140),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.cents,
    required this.active,
    required this.colorScheme,
  });

  /// −50..50 — the gauge spans 100 cents.
  final double cents;
  final bool active;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.height * 0.95;

    // Background arc (180° upward fan).
    final bgPaint = Paint()
      ..color = colorScheme.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = math.pi;
    const sweep = math.pi;
    canvas.drawArc(rect, startAngle, sweep, false, bgPaint);

    // Green "in tune" zone — middle ~12° of the sweep (≈ ±5 cents).
    final zonePaint = Paint()
      ..color = AppColors.success.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      startAngle + sweep / 2 - 0.20,
      0.40,
      false,
      zonePaint,
    );

    if (!active) return;

    // Needle: −50¢ → angle = startAngle (left), +50¢ → angle = startAngle+sweep
    final t = (cents / 50).clamp(-1.0, 1.0);
    final angle = startAngle + (1 + t) * (sweep / 2);
    final needleEnd = Offset(
      center.dx + radius * 0.85 * math.cos(angle),
      center.dy + radius * 0.85 * math.sin(angle),
    );
    final needleColor = cents.abs() < 5
        ? AppColors.success
        : cents.abs() < 15
            ? AppColors.warning
            : AppColors.error;
    final needlePaint = Paint()
      ..color = needleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 8, Paint()..color = needleColor);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.cents != cents || old.active != active;
}

// ---------- Permission denied banner --------------------------------------

class _PermissionDeniedBanner extends StatelessWidget {
  const _PermissionDeniedBanner({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic_off_outlined, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
