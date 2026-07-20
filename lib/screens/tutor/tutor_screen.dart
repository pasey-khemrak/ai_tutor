import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class TutorScreen extends StatelessWidget {
  const TutorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                UserBubble(),
                SizedBox(height: 22),
                TutorAnswer(),
              ],
            ),
          ),
        ),
        const ChatInput(),
      ],
    );
  }
}

class UserBubble extends StatelessWidget {
  const UserBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 306,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: const BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(2),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: const Text(
              'Find the equation line where\nd(0,1) and e(1,3)',
              style: TextStyle(color: Colors.white, fontSize: 20, height: 1.38),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You  •  10:43 AM',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: .8,
            ),
          ),
        ],
      ),
    );
  }
}

class TutorAnswer extends StatelessWidget {
  const TutorAnswer({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cyan.withValues(alpha: .15),
            border: Border.all(color: AppColors.cyan.withValues(alpha: .55)),
          ),
          child: const Icon(Icons.smart_toy_outlined, size: 17, color: AppColors.cyan),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.answer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.cyan,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 18, 22),
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 18,
                            height: 1.48,
                          ),
                          children: [
                            const TextSpan(text: 'y = ax+b\n'),
                            const TextSpan(text: ' • Here is the equation line which:\n'),
                            const TextSpan(text: '     • a is a slope\n'),
                            const TextSpan(text: '     • b is the intercept\n'),
                            const TextSpan(text: '     • any point c(x,y)\n'),
                            const TextSpan(text: 'note: a = (y2-y1)/(x2-x1)\n'),
                            _bold('Slope: '),
                            const TextSpan(text: 'It tell the trend of the line.\n'),
                            const TextSpan(text: 'does it go downward or upward.\n'),
                            const TextSpan(text: 'For your problem:\n'),
                            const TextSpan(text: ' • d(0,1) and e (1,3)\n'),
                            _bold('+ Find the slope\n'),
                            const TextSpan(text: '=> a = (1-3)/(0-1) = 2\n'),
                            _bold('+ Substitute a point into the\nequation\n'),
                            const TextSpan(text: 'y = ax + b\n'),
                            const TextSpan(text: 'Where: a = 2, e(1,3) => x = 1, y= 3\n'),
                            const TextSpan(text: ' • x is the horizontal axis\n'),
                            const TextSpan(text: ' • y is the vertical axis\n'),
                            const TextSpan(text: '=> y = 2x+3\n'),
                            const TextSpan(text: 'so: y= 2x + 3'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static TextSpan _bold(String text) {
    return TextSpan(
      text: text,
      style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.text),
    );
  }
}

class ChatInput extends StatelessWidget {
  const ChatInput({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: .05)),
        ),
        child: Row(
          children: [
            const Icon(Icons.attach_file_rounded, color: AppColors.muted, size: 21),
            const SizedBox(width: 18),
            const Expanded(
              child: Text(
                'Ask Rean any question!',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Color(0xFF777C91), fontSize: 18),
              ),
            ),
            const Icon(Icons.mic_none_rounded, color: AppColors.muted, size: 21),
            const SizedBox(width: 10),
            SizedBox.square(
              dimension: 44,
              child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: AppColors.blue,
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.send_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
