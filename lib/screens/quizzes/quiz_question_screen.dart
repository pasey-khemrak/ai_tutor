import 'package:flutter/material.dart';
import '../../core/adaptive_colors.dart';
import '../../core/app_colors.dart';

class QuizQuestionScreen extends StatelessWidget {
  const QuizQuestionScreen({
    super.key,
    required this.onNext,
    required this.onResults,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onResults;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textColor = AdaptiveColors.text(context);
    final borderColor = AdaptiveColors.line(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const QuizProgressHeader(),
                const SizedBox(height: 18),
                const QuestionCard(),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: onResults,
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: const Text('ពិនិត្យលទ្ធផលរហ័ស'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        QuizQuestionFooter(onNext: onNext, onBack: onBack),
      ],
    );
  }
}

class QuizProgressHeader extends StatelessWidget {
  const QuizProgressHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = AdaptiveColors.text(context);
    final mutedColor = AdaptiveColors.muted(context);
    final lineColor = AdaptiveColors.line(context);

    return Column(
      children: [
        Row(
          children: [
            Text(
              'សំណួរ ',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
            ),
            Text(
              '5',
              style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w900),
            ),
            Text(
              ' នៃ 20',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
            ),
            Spacer(),
            Text(
              '25% Complete',
              style: TextStyle(color: mutedColor, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: .25,
            minHeight: 6,
            backgroundColor: lineColor,
            valueColor: const AlwaysStoppedAnimation(AppColors.blue),
          ),
        ),
      ],
    );
  }
}

class QuestionCard extends StatelessWidget {
  const QuestionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final panelColor = AdaptiveColors.panel(context);
    final lineColor = AdaptiveColors.line(context);
    final textColor = AdaptiveColors.text(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '5. តើដែនកំណត់នៃអនុគមន៍ខាងក្រោមគឺមួយណា?',
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'f(x) = √(x - 2)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.cyan,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          QuizChoice(letter: 'A', text: 'x ≥ 0'),
          QuizChoice(letter: 'B', text: 'x ≥ 2', selected: true),
          QuizChoice(letter: 'C', text: 'x ≤ 2'),
          QuizChoice(letter: 'D', text: 'គ្មានចម្លើយត្រឹមត្រូវ'),
        ],
      ),
    );
  }
}

class QuizChoice extends StatelessWidget {
  const QuizChoice({
    super.key,
    required this.letter,
    required this.text,
    this.selected = false,
    this.correct = false,
    this.wrong = false,
  });

  final String letter;
  final String text;
  final bool selected;
  final bool correct;
  final bool wrong;

  @override
  Widget build(BuildContext context) {
    final lineColor = AdaptiveColors.line(context);
    final cardColor = AdaptiveColors.card(context);
    final defaultTextColor = AdaptiveColors.text(context);
    final letterBackground = AdaptiveColors.isLight(context)
        ? const Color(0xFFEAF0FF)
        : Colors.white.withValues(alpha: .07);

    final borderColor = correct
        ? Colors.greenAccent.withValues(alpha: .45)
        : wrong
            ? AppColors.peach.withValues(alpha: .45)
            : selected
                ? AppColors.blue
                : lineColor;
    final textColor = correct
        ? Colors.greenAccent
        : wrong
            ? AppColors.peach
            : defaultTextColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: selected ? AppColors.blue.withValues(alpha: .14) : cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: selected ? 2 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.blue : letterBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              letter,
              style: TextStyle(
                color: selected ? Colors.white : defaultTextColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (selected || correct)
            const Icon(Icons.check_circle, color: AppColors.cyan, size: 18),
        ],
      ),
    );
  }
}

class QuizQuestionFooter extends StatelessWidget {
  const QuizQuestionFooter({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final panelColor = AdaptiveColors.panel(context);
    final lineColor = AdaptiveColors.line(context);
    final mutedColor = AdaptiveColors.muted(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: panelColor,
        border: Border(top: BorderSide(color: lineColor)),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('មុន'),
            style: TextButton.styleFrom(foregroundColor: mutedColor),
          ),
          const Spacer(),
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              fixedSize: const Size(132, 52),
              backgroundColor: AppColors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'បន្ទាប់ ›',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
