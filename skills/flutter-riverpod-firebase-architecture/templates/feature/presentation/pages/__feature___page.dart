import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/l10n.dart';
import '../providers/__feature___providers.dart';

class __Feature__Page extends ConsumerWidget {
  const __Feature__Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final items = ref.watch(__entityCamel__ListProvider);

    // One-shot side effects belong in ref.listen, not build.
    ref.listen(__entityCamel__NotifierProvider.select((s) => s.errorMessage), (_, msg) {
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.__entityCamel__Title)),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errGeneric)),
        data: (list) => list.isEmpty
            ? Center(child: Text(l10n.__entityCamel__Empty))
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(list[i].title),
                  trailing: IconButton(
                    tooltip: l10n.actionDelete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref
                        .read(__entityCamel__NotifierProvider.notifier)
                        .delete(list[i].id),
                  ),
                ),
              ),
      ),
    );
  }
}
