import 'package:flutter/material.dart';

import 'rean_logo_mark.dart';

class BrandIntroPage extends StatelessWidget {
  const BrandIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final logoSize = (size.shortestSide * .42).clamp(152.0, 178.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 94),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),
          ReanLogoMark(size: logoSize),
          const SizedBox(height: 10),
          const ReanBrandName(),
          const SizedBox(height: 12),
          Text(
            'Your intelligent learning companion',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF94A1D6).withValues(alpha: .78),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(flex: 4),
        ],
      ),
    );
  }
}
