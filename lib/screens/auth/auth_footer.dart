import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key, required this.page, required this.onNext});

  final int page;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLastPage = page == 2;

    return Row(
      children: [
        PageDots(active: page),
        const Spacer(),
        SizedBox(
          width: isLastPage ? 180 : 86,
          height: 48,
          child: FilledButton(
            key: const Key('auth-footer-next-button'),
            onPressed: onNext,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: isLastPage
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ],
                  )
                : const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
          ),
        ),
      ],
    );
  }
}

class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.active});

  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        final isActive = active == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 35 : 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? AppColors.blue : const Color(0xFF252A40),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
