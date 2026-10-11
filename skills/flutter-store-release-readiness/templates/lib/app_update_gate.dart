import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import 'app_update_service.dart';

/// Wraps the app (from `MaterialApp.builder`) and enforces the Remote
/// Config update policy:
///   • required    → full-screen blocking page, no way past it
///   • recommended → dismissible banner on top of the app
///   • none / still loading / error → the app as-is (fails open)
class AppUpdateGate extends ConsumerStatefulWidget {
  const AppUpdateGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends ConsumerState<AppUpdateGate> {
  bool _dismissed = false;

  Future<void> _openStore(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(appUpdateStatusProvider).value;
    if (status == null || status.level == AppUpdateLevel.none) {
      return widget.child;
    }
    final t = context.l10n;
    final theme = Theme.of(context);

    if (status.level == AppUpdateLevel.required) {
      return Material(
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.system_update_rounded,
                    size: 72, color: theme.colorScheme.primary),
                const SizedBox(height: 24),
                Text(
                  t.updateRequiredTitle,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  t.updateRequiredBody,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (status.storeUrl != null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _openStore(status.storeUrl!),
                      child: Text(t.updateNow),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Recommended — banner over the running app.
    if (_dismissed) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: SafeArea(
            bottom: false,
            child: Material(
              elevation: 4,
              color: theme.colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    Icon(Icons.system_update_rounded,
                        color: theme.colorScheme.onSecondaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.updateAvailableBody,
                        style: TextStyle(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    if (status.storeUrl != null)
                      TextButton(
                        onPressed: () => _openStore(status.storeUrl!),
                        child: Text(t.updateNow),
                      ),
                    // No `tooltip:` — this sits above the Navigator (in
                    // MaterialApp.builder) where there is no Overlay for
                    // tooltips; label it via Semantics instead.
                    Semantics(
                      button: true,
                      label: t.updateLater,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _dismissed = true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
