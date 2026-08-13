import 'package:flutter/material.dart';

import 'rean_logo_mark.dart';

class BrandIntroPage extends StatelessWidget {
  const BrandIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 520;
        final logoSize = (constraints.biggest.shortestSide * .54)
            .clamp(compact ? 132.0 : 190.0, compact ? 170.0 : 230.0);

        return Padding(
          padding: EdgeInsets.fromLTRB(28, compact ? 18 : 30, 28, 94),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(flex: compact ? 1 : 3),
              ReanLogoMark(size: logoSize),
              SizedBox(height: compact ? 8 : 10),
              const ReanBrandName(),
              SizedBox(height: compact ? 8 : 12),
              Text(
                'Your intelligent learning companion',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF94A1D6).withValues(alpha: .78),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Spacer(flex: compact ? 1 : 4),
            ],
          ),
        );
      },
    );
  }
}
