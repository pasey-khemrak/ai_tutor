import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class ReanAvatar extends StatelessWidget {
  const ReanAvatar({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF0B1732), Color(0xFF071128), Color(0xFF050A1D)],
          stops: [0, .62, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: .2),
            blurRadius: 14,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * .08),
        child: Image.asset(
          'assets/images/ai_tutor_logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
