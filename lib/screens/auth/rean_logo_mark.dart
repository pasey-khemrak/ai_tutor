import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class ReanLogoMark extends StatelessWidget {
  const ReanLogoMark({super.key, this.size = 118, this.showGlow = true});

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFF0B1732), Color(0xFF071128), Color(0xFF050A1D)],
            stops: [0, .62, 1],
          ),
          boxShadow: showGlow
              ? [
                  BoxShadow(
                    color: const Color(0xFF4F8EFF).withValues(alpha: .32),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .46),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(size * .04),
          child: Image.asset(
            'assets/images/ai_tutor_logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class ReanBrandName extends StatelessWidget {
  const ReanBrandName({super.key, this.prefix, this.fontSize = 29});

  final String? prefix;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
        children: [
          if (prefix != null)
            TextSpan(
              text: prefix,
              style: const TextStyle(color: AppColors.blue),
            ),
          const TextSpan(text: 'Rean-'),
          const TextSpan(
            text: '\u179A\u17C0\u1793',
            style: TextStyle(color: AppColors.blue),
          ),
        ],
      ),
    );
  }
}
