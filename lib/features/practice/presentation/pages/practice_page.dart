import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../widgets/metronome_view.dart';
import '../widgets/tuner_view.dart';

/// Practice tools page — two tabs, Metronome and Tuner.
///
/// Reached from `Profile → Practice tools`. Lives outside the bottom
/// nav by design — adding a 6th tab would crowd the existing 5.
class PracticePage extends StatelessWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.practiceTitle),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.timer_outlined),
                text: t.practiceMetronome,
              ),
              Tab(
                icon: const Icon(Icons.tune_rounded),
                text: t.practiceTuner,
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MetronomeView(),
            TunerView(),
          ],
        ),
      ),
    );
  }
}
