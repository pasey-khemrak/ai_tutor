import 'package:flutter/material.dart';

import '../../core/adaptive_colors.dart';
import '../../core/localization/app_localizations.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String? title;
  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AdaptiveColors.muted(context), size: 36),
            const SizedBox(height: 12),
            Text(
              title ?? localizations.emptyStateTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AdaptiveColors.text(context),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AdaptiveColors.muted(context),
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
