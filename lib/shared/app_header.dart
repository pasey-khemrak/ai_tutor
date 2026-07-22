import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'rean_avatar.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: .72),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: .03)),
        ),
      ),
      child: Row(
        children: [
          const ReanAvatar(),
          const SizedBox(width: 12),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
              children: [
                TextSpan(text: 'Rean-'),
                TextSpan(
                  text: '\u179A\u17C0\u1793',
                  style: TextStyle(color: AppColors.blue),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Settings',
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
