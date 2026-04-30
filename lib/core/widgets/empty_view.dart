import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_rounded,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).hintColor),
          const SizedBox(height: 12),
          Text(message, style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }
}
