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
        border: Border.all(color: AppColors.cyan.withValues(alpha: .55)),
        gradient: const LinearGradient(
          colors: [Color(0xFF12384A), Color(0xFF0E1425), Color(0xFF1A4856)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: .16),
            blurRadius: 18,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.school_rounded,
            color: Colors.white.withValues(alpha: .8),
            size: size * .45,
          ),
          Positioned(
            right: size * .18,
            bottom: size * .18,
            child: Container(
              width: size * .22,
              height: size * .22,
              decoration: const BoxDecoration(
                color: AppColors.cyan,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
