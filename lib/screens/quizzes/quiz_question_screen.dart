import 'package:flutter/material.dart';
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
                    foregroundColor: AppColors.text,
                    side: BorderSide(color: AppColors.muted.withValues(alpha: .7)),
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
    return Column(
      children: [
        const Row(
          children: [
            Text(
              'សំណួរ ',
              style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800),
            ),
            Text(
              '5',
              style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w900),
            ),
            Text(
              ' នៃ 20',
              style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800),
            ),
            Spacer(),
            Text(
              '25% Complete',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: const LinearProgressIndicator(
            value: .25,
            minHeight: 6,
            backgroundColor: AppColors.line,
            valueColor: AlwaysStoppedAnimation(AppColors.blue),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Text(
            '5. តើដែនកំណត់នៃអនុគមន៍ខាងក្រោមគឺមួយណា?',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 17,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'f(x) = √(x - 2)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.cyan,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 24),
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
    final borderColor = correct
        ? Colors.greenAccent.withValues(alpha: .45)
        : wrong
            ? AppColors.peach.withValues(alpha: .45)
            : selected
                ? AppColors.blue
                : AppColors.line;
    final textColor = correct
        ? Colors.greenAccent
        : wrong
            ? AppColors.peach
            : AppColors.text;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: selected ? AppColors.blue.withValues(alpha: .14) : AppColors.card,
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
              color: selected ? AppColors.blue : Colors.white.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              letter,
              style: const TextStyle(
                color: AppColors.text,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: .95),
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('មុន'),
            style: TextButton.styleFrom(foregroundColor: AppColors.muted),
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
