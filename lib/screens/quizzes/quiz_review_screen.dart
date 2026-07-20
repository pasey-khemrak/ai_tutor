import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class QuizReviewScreen extends StatelessWidget {
  const QuizReviewScreen({super.key, required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              children: [
                const ReviewFilterBar(),
                const SizedBox(height: 18),
                const ReviewAnswerCard(
                  number: '4',
                  status: 'ត្រឹមត្រូវ',
                  question: 'តើដែនកំណត់នៃអនុគមន៍ខាងក្រោមគឺមួយណា?',
                  formula: 'f(x) = √(x - 2)',
                  userAnswer: 'B. x ≥ 2',
                  correctAnswer: 'B. x ≥ 2',
                  correct: true,
                  explanation:
                      'ការស្ថិតនៅក្នុងឫសការ៉េត្រូវតែធំជាងឬស្មើសូន្យ ដូច្នេះ x - 2 ≥ 0 នាំឱ្យ x ≥ 2។',
                ),
                const ReviewAnswerCard(
                  number: '5',
                  status: 'ខុស',
                  question: 'ប្រសិនបើ f(x) = x³ តើតម្លៃ f(2) ?',
                  formula: '',
                  userAnswer: 'C. 6',
                  correctAnswer: 'A. 8',
                  correct: false,
                  explanation:
                      'ជំនួស x ដោយ 2 ក្នុងអនុគមន៍ x³ នោះយើងបាន (2 × 2 × 2) = 8។ ដូច្នេះ f(2) = 8។',
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.workspace_premium, color: AppColors.cyan),
                      SizedBox(height: 8),
                      Text(
                        '80%',
                        style: TextStyle(
                          color: AppColors.cyan,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('សរុបពិន្ទុ', style: TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: OutlinedButton.icon(
            onPressed: onRestart,
            icon: const Icon(Icons.home_outlined),
            label: const Text('ត្រឡប់ទៅចាប់ផ្តើម'),
            style: OutlinedButton.styleFrom(
              fixedSize: const Size.fromHeight(48),
              foregroundColor: AppColors.text,
              side: BorderSide(color: AppColors.line),
            ),
          ),
        ),
      ],
    );
  }
}

class ReviewFilterBar extends StatelessWidget {
  const ReviewFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: ReviewChip(label: 'ទាំងអស់ (20)', selected: true)),
        SizedBox(width: 8),
        Expanded(child: ReviewChip(label: 'ត្រឹមត្រូវ (16)')),
        SizedBox(width: 8),
        Expanded(child: ReviewChip(label: 'ខុស (3)')),
      ],
    );
  }
}

class ReviewChip extends StatelessWidget {
  const ReviewChip({super.key, required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.blue : AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? AppColors.blue : AppColors.line),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class ReviewAnswerCard extends StatelessWidget {
  const ReviewAnswerCard({
    super.key,
    required this.number,
    required this.status,
    required this.question,
    required this.formula,
    required this.userAnswer,
    required this.correctAnswer,
    required this.correct,
    required this.explanation,
  });

  final String number;
  final String status;
  final String question;
  final String formula;
  final String userAnswer;
  final String correctAnswer;
  final bool correct;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1C55),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'សំណួរ $number',
                  style: const TextStyle(
                    color: Color(0xFFC9A8FF),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                correct ? Icons.check_circle : Icons.cancel,
                color: correct ? Colors.greenAccent : AppColors.peach,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: TextStyle(
                  color: correct ? Colors.greenAccent : AppColors.peach,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              const Icon(Icons.bookmark_border, color: AppColors.muted, size: 20),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            question,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          if (formula.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              formula,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 19,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 18),
          ReviewAnswerBox(label: 'ចម្លើយរបស់អ្នក', value: userAnswer, ok: correct),
          const SizedBox(height: 10),
          ReviewAnswerBox(label: 'ចម្លើយត្រឹមត្រូវ', value: correctAnswer, ok: true),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2144),
              borderRadius: BorderRadius.circular(8),
              border: const Border(left: BorderSide(color: AppColors.cyan, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.cyan, size: 15),
                    SizedBox(width: 8),
                    Text(
                      'ការពន្យល់',
                      style: TextStyle(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  explanation,
                  style: const TextStyle(
                    color: AppColors.subtle,
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'ជំនួយពី AI →',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewAnswerBox extends StatelessWidget {
  const ReviewAnswerBox({
    super.key,
    required this.label,
    required this.value,
    required this.ok,
  });

  final String label;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ok
              ? Colors.greenAccent.withValues(alpha: .35)
              : AppColors.peach.withValues(alpha: .35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: ok ? Colors.greenAccent : AppColors.peach,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
