import 'package:flutter/material.dart';

import '../core/adaptive_colors.dart';
import '../core/app_colors.dart';
import 'rean_avatar.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, this.forceDark = false});

  final bool forceDark;

  @override
  Widget build(BuildContext context) {
    final isLight = AdaptiveColors.isLight(context) && !forceDark;
    final panelColor = isLight
        ? Colors.white.withValues(alpha: .92)
        : AppColors.panel.withValues(alpha: .72);
    final borderColor = isLight
        ? const Color(0xFFD8DEEC)
        : Colors.white.withValues(alpha: .03);
    final titleColor = isLight ? AppColors.blue : AppColors.cyan;
    final subtitleColor = AdaptiveColors.muted(context);

    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: panelColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          const ReanAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rean \u179A\u17C0\u1793',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'AI Mathematics Tutor',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'More',
            onPressed: () {},
            icon: Icon(Icons.more_horiz_rounded, color: subtitleColor),
          ),
        ],
      ),
    );
  }
}
