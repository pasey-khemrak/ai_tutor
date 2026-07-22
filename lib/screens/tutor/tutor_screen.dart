import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../core/app_colors.dart';

class TutorScreen extends StatefulWidget {
  const TutorScreen({super.key});

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  int _step = 0;
  bool _showExtraHelp = false;

  static const _steps = [
    LessonStep(
      title: 'Step 1: Find the Slope',
      progress: '1 of 3 Progress',
      graphMode: GraphMode.slope,
      prompt: 'The slope m is the change in y over the change in x:',
      work: 'm = (y2 - y1) / (x2 - x1) = (3 - 1) / (1 - 0) = 2',
      takeaway: 'So the line rises 2 units for every 1 unit it moves right.',
    ),
    LessonStep(
      title: 'Step 2: Solve for Y-Intercept',
      progress: '2 of 3 Progress',
      graphMode: GraphMode.intercept,
      prompt: 'Substitute point D(0,1) into the slope-intercept form y = mx + b:',
      work: '1 = 2(0) + b\n1 = 0 + b\nb = 1',
      takeaway: 'The y-intercept is 1 because the line crosses the y-axis at D(0,1).',
    ),
    LessonStep(
      title: 'Step 3: Final Equation',
      progress: '3 of 3 Progress',
      graphMode: GraphMode.finalEquation,
      prompt: 'Combine the slope m = 2 and the y-intercept b = 1 into y = mx + b.',
      work: 'y = (2)x + (1)\ny = 2x + 1',
      takeaway: 'Final answer: y = 2x + 1.',
    ),
  ];

  bool get _isPractice => _step >= _steps.length;

  void _next() {
    setState(() {
      _step = (_step + 1).clamp(0, _steps.length);
      _showExtraHelp = false;
    });
  }

  void _back() {
    setState(() {
      _step = (_step - 1).clamp(0, _steps.length);
      _showExtraHelp = false;
    });
  }

  void _explainAgain() {
    setState(() => _showExtraHelp = !_showExtraHelp);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const UserBubble(),
                const SizedBox(height: 26),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _isPractice
                      ? PracticeCard(
                          key: const ValueKey('practice'),
                          onBack: _back,
                          onExplainAgain: _explainAgain,
                          showExtraHelp: _showExtraHelp,
                        )
                      : LessonCard(
                          key: ValueKey(_step),
                          step: _steps[_step],
                          isFirst: _step == 0,
                          isLast: _step == _steps.length - 1,
                          onBack: _back,
                          onNext: _next,
                          onExplainAgain: _explainAgain,
                          showExtraHelp: _showExtraHelp,
                        ),
                ),
              ],
            ),
          ),
        ),
        ChatInput(onNeedHelp: _explainAgain),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: const BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(2),
              ),
            ),
            child: const Text(
              'Find the equation of the line\nthrough D(0,1) and E(1,3)',
              style: TextStyle(color: Colors.white, fontSize: 18, height: 1.45),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You • 10:43 AM',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.step,
    required this.isFirst,
    required this.isLast,
    required this.onBack,
    required this.onNext,
    required this.onExplainAgain,
    required this.showExtraHelp,
  });

  final LessonStep step;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onExplainAgain;
  final bool showExtraHelp;

  @override
  Widget build(BuildContext context) {
    return TutorPanel(
      title: step.title,
      subtitle: step.progress,
      onExplainAgain: onExplainAgain,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EquationGraph(mode: step.graphMode),
          const SizedBox(height: 16),
          ExplanationBox(step: step),
          if (showExtraHelp) ...[
            const SizedBox(height: 12),
            const ExtraHelpBox(),
          ],
          const SizedBox(height: 20),
          TutorActionRow(
            backLabel: isFirst ? 'Back' : 'Back',
            nextLabel: isLast ? 'Finish' : 'Next Step',
            onBack: onBack,
            onNext: onNext,
          ),
        ],
      ),
    );
  }
}

class PracticeCard extends StatelessWidget {
  const PracticeCard({
    super.key,
    required this.onBack,
    required this.onExplainAgain,
    required this.showExtraHelp,
  });

  final VoidCallback onBack;
  final VoidCallback onExplainAgain;
  final bool showExtraHelp;

  @override
  Widget build(BuildContext context) {
    return TutorPanel(
      title: 'Practice: Your Turn',
      subtitle: 'Try the same idea with a new pair of points',
      onExplainAgain: onExplainAgain,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Find the equation of the line passing through P(1,2) and Q(3,6).',
            style: TextStyle(color: AppColors.muted, fontSize: 16, height: 1.45),
          ),
          const SizedBox(height: 16),
          const PracticeIllustration(),
          const SizedBox(height: 18),
          const PracticeAnswerField(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cyan.withValues(alpha: .7)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.cyan, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Correct! The slope is 2 and the intercept is 0.',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontSize: 16,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showExtraHelp) ...[
            const SizedBox(height: 12),
            const ExtraHelpBox(),
          ],
          const SizedBox(height: 20),
          TutorActionRow(
            backLabel: 'Back',
            nextLabel: 'Next Challenge',
            onBack: onBack,
            onNext: onExplainAgain,
          ),
        ],
      ),
    );
  }
}

class TutorPanel extends StatelessWidget {
  const TutorPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onExplainAgain,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onExplainAgain;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.answer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cyan.withValues(alpha: .22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cyan.withValues(alpha: .14),
                    border: Border.all(
                      color: AppColors.cyan.withValues(alpha: .55),
                    ),
                  ),
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: AppColors.cyan,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.cyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Explain another way',
                  onPressed: onExplainAgain,
                  icon: const Icon(
                    Icons.help_outline_rounded,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            color: AppColors.answer.withValues(alpha: .7),
            child: child,
          ),
        ],
      ),
    );
  }
}

class EquationGraph extends StatelessWidget {
  const EquationGraph({super.key, required this.mode});

  final GraphMode mode;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.08,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF101422),
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomPaint(painter: EquationGraphPainter(mode)),
      ),
    );
  }
}

class ExplanationBox extends StatelessWidget {
  const ExplanationBox({super.key, required this.step});

  final LessonStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            step.prompt,
            style: const TextStyle(
              color: AppColors.subtle,
              fontSize: 16,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            step.work,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 19,
              height: 1.55,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            step.takeaway,
            style: const TextStyle(
              color: AppColors.cyan,
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class ExtraHelpBox extends StatelessWidget {
  const ExtraHelpBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2144),
        borderRadius: BorderRadius.circular(10),
        border: const Border(left: BorderSide(color: AppColors.cyan, width: 4)),
      ),
      child: const Text(
        'Think of the line like stairs: slope tells how high each step rises, and the intercept tells where the stairs start on the y-axis.',
        style: TextStyle(color: AppColors.subtle, height: 1.45),
      ),
    );
  }
}

class TutorActionRow extends StatelessWidget {
  const TutorActionRow({
    super.key,
    required this.backLabel,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
  });

  final String backLabel;
  final String nextLabel;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              fixedSize: const Size.fromHeight(54),
              foregroundColor: AppColors.blue,
              side: const BorderSide(color: AppColors.blue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              backLabel,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              fixedSize: const Size.fromHeight(54),
              backgroundColor: AppColors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              nextLabel,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}

class PracticeIllustration extends StatelessWidget {
  const PracticeIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.68,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF101422),
          borderRadius: BorderRadius.circular(14),
        ),
        child: CustomPaint(painter: PracticeIllustrationPainter()),
      ),
    );
  }
}

class PracticeAnswerField extends StatelessWidget {
  const PracticeAnswerField({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111523),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cyan, width: 2),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              'y = 2x',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Icon(Icons.sentiment_satisfied_alt, color: AppColors.muted),
        ],
      ),
    );
  }
}

class ChatInput extends StatelessWidget {
  const ChatInput({super.key, required this.onNeedHelp});

  final VoidCallback onNeedHelp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: .05)),
        ),
        child: Row(
          children: [
            const Icon(Icons.attach_file_rounded, color: AppColors.muted, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: InkWell(
                onTap: onNeedHelp,
                child: const Text(
                  'Ask Rean any question!',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Color(0xFF777C91), fontSize: 16),
                ),
              ),
            ),
            const Icon(Icons.mic_none_rounded, color: AppColors.muted, size: 20),
            const SizedBox(width: 10),
            SizedBox.square(
              dimension: 40,
              child: FilledButton(
                onPressed: onNeedHelp,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: AppColors.blue,
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.send_rounded, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LessonStep {
  const LessonStep({
    required this.title,
    required this.progress,
    required this.graphMode,
    required this.prompt,
    required this.work,
    required this.takeaway,
  });

  final String title;
  final String progress;
  final GraphMode graphMode;
  final String prompt;
  final String work;
  final String takeaway;
}

enum GraphMode { slope, intercept, finalEquation }

class EquationGraphPainter extends CustomPainter {
  const EquationGraphPainter(this.mode);

  final GraphMode mode;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1.4;
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: .045)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = AppColors.cyan
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final guidePaint = Paint()
      ..color = AppColors.muted.withValues(alpha: .55)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    final pointPaint = Paint()..color = AppColors.blue;

    const xMin = -1.0;
    const xMax = 3.0;
    const yMin = -1.0;
    const yMax = 5.0;
    final unit = math.min(size.width * .84 / (xMax - xMin), size.height * .8 / (yMax - yMin));
    final planeWidth = (xMax - xMin) * unit;
    final planeHeight = (yMax - yMin) * unit;
    final left = (size.width - planeWidth) / 2;
    final top = (size.height - planeHeight) / 2;
    final right = left + planeWidth;
    final bottom = top + planeHeight;

    Offset map(double x, double y) {
      return Offset(
        left + (x - xMin) * unit,
        top + (yMax - y) * unit,
      );
    }

    for (var x = xMin; x <= xMax; x += 1) {
      final point = map(x, yMin);
      canvas.drawLine(Offset(point.dx, top), Offset(point.dx, bottom), gridPaint);
    }
    for (var y = yMin; y <= yMax; y += 1) {
      final point = map(xMin, y);
      canvas.drawLine(Offset(left, point.dy), Offset(right, point.dy), gridPaint);
    }

    canvas.drawLine(map(-1, 0), map(3, 0), axisPaint);
    canvas.drawLine(map(0, -1), map(0, 5), axisPaint);
    canvas.drawLine(map(-1, -1), map(2, 5), linePaint);

    final d = map(0, 1);
    final e = map(1, 3);
    canvas.drawCircle(d, 5, pointPaint);
    canvas.drawCircle(e, 5, pointPaint);

    if (mode == GraphMode.slope) {
      canvas.drawLine(d, Offset(e.dx, d.dy), guidePaint);
      canvas.drawLine(Offset(e.dx, d.dy), e, guidePaint);
      _label(canvas, 'D(0,1)', d + const Offset(8, -16));
      _label(canvas, 'E(1,3)', e + const Offset(8, -16));
    } else if (mode == GraphMode.intercept) {
      _label(canvas, 'D(0,1)', d + const Offset(-18, 12));
      _label(canvas, 'E(1,3)', e + const Offset(8, 0));
    } else {
      final labelOrigin = map(1.5, 3.2);
      final labelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(labelOrigin.dx, labelOrigin.dy, 82, 38),
        const Radius.circular(6),
      );
      canvas.drawRRect(labelRect, Paint()..color = AppColors.card);
      _label(canvas, 'y = 2x + 1', labelOrigin + const Offset(9, 12), cyan: true);
      _label(canvas, 'D(0,1)', d + const Offset(-18, 12));
      _label(canvas, 'E(1,3)', e + const Offset(-10, 18));
    }
  }

  void _label(Canvas canvas, String text, Offset offset, {bool cyan = false}) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: cyan ? AppColors.cyan : AppColors.text,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant EquationGraphPainter oldDelegate) {
    return oldDelegate.mode != mode;
  }
}

class PracticeIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bookPaint = Paint()..color = const Color(0xFFFFC928);
    final coverPaint = Paint()..color = const Color(0xFFFF4D5A);
    final accentPaint = Paint()..color = const Color(0xFFE80E67);
    final pencilPaint = Paint()..color = const Color(0xFF2D69E8);
    final circlePaint = Paint()..color = const Color(0xFFFF8A00);

    canvas.drawCircle(Offset(size.width * .78, size.height * .48), size.height * .42, coverPaint);
    canvas.drawCircle(Offset(size.width * .18, size.height * .48), size.height * .43, accentPaint);
    canvas.save();
    canvas.translate(size.width * .16, size.height * .12);
    canvas.rotate(.2);
    final book = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width * .5, size.height * .7),
      const Radius.circular(6),
    );
    canvas.drawRRect(book, bookPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .32, 0, size.width * .18, size.height * .7),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white,
    );
    _drawText(canvas, 'MATH', Offset(size.width * .22, size.height * .12), Colors.white, 20);
    canvas.restore();

    canvas.drawLine(
      Offset(size.width * .4, size.height * .64),
      Offset(size.width * .9, size.height * .72),
      pencilPaint..strokeWidth = 14,
    );
    canvas.drawCircle(Offset(size.width * .73, size.height * .72), 22, circlePaint);
    canvas.drawCircle(Offset(size.width * .73, size.height * .72), 10, bookPaint);
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color, double size) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
