import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// Header for the search page — pill input + optional "Cancel" + filter
/// icon. Mirrors the Tonebase / Udemy style from the attached screenshots.
class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SearchAppBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.showCancel,
    required this.activeFilterCount,
    required this.onCancel,
    required this.onClear,
    required this.onChanged,
    required this.onSubmitted,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// True while the field has focus or has text — shows the "Cancel" button
  /// to the right of the pill. False on initial entry (results-only view).
  final bool showCancel;

  /// Drives the small badge on the filter icon.
  final int activeFilterCount;

  final VoidCallback onCancel;
  final VoidCallback onClear;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onFilterTap;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final pillColor = theme.colorScheme.surfaceContainerHighest;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: pillColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search,
                        size: 20, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: onChanged,
                        onSubmitted: onSubmitted,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: t.searchHint,
                          hintStyle: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    if (controller.text.isNotEmpty)
                      GestureDetector(
                        onTap: onClear,
                        child: Icon(
                          Icons.cancel,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (showCancel) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(t.searchCancel,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
            const SizedBox(width: 8),
            _FilterButton(
              activeCount: activeFilterCount,
              onTap: onFilterTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.activeCount, required this.onTap});
  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.tune, size: 22),
            if (activeCount > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$activeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
