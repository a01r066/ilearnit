import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions.dart';
import '../providers/purchases_providers.dart';
import '../../../../l10n/l10n.dart';

/// Drop-in ListTile for the Profile / Settings screen.
///
/// Calls [PurchasesNotifier.restorePurchases]; ownership state will flow
/// back through Firestore + the `ownedCourseIdsProvider` stream.
class RestorePurchasesTile extends ConsumerStatefulWidget {
  const RestorePurchasesTile({super.key});

  @override
  ConsumerState<RestorePurchasesTile> createState() =>
      _RestorePurchasesTileState();
}

class _RestorePurchasesTileState
    extends ConsumerState<RestorePurchasesTile> {
  bool _busy = false;

  Future<void> _restore() async {
    setState(() => _busy = true);
    await ref.read(purchasesNotifierProvider.notifier).restorePurchases();
    if (!mounted) return;
    setState(() => _busy = false);
    context.showSnack(context.l10n.purchaseRestoreDone);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.restore_rounded),
      title: Text(context.l10n.purchaseRestore),
      subtitle: Text(context.l10n.purchaseRestoreSubtitle),
      trailing: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: _busy ? null : _restore,
    );
  }
}
