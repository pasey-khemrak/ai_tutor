import 'package:flutter/material.dart';
import '../../core/adaptive_colors.dart';
import '../../core/app_colors.dart';

class QuizSubmitScreen extends StatelessWidget {
  const QuizSubmitScreen({
    super.key,
    required this.answeredCount,
    required this.totalQuestions,
    this.isSubmitting = false,
    this.errorMessage,
    required this.onSubmit,
    required this.onBack,
  });

  final int answeredCount;
  final int totalQuestions;
  final bool isSubmitting;
  final String? errorMessage;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final panelColor = AdaptiveColors.panel(context);
    final lineColor = AdaptiveColors.line(context);
    final textColor = AdaptiveColors.text(context);
    final mutedColor = AdaptiveColors.muted(context);
    final warningBackground = AdaptiveColors.isLight(context)
        ? const Color(0xFFFFF1E8)
        : const Color(0xFF3A2322);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 42, 22, 28),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cyan.withValues(alpha: .3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan.withValues(alpha: .12),
              blurRadius: 34,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.blue,
              child: Icon(Icons.quiz_outlined, color: Colors.white),
            ),
            const SizedBox(height: 22),
            Text(
              'ដាក់បញ្ចប់?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'អ្នកបានឆ្លើយសំណួរចំនួន $answeredCount ក្នុងចំណោម $totalQuestions សំណួរ។',
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedColor, height: 1.4),
            ),
            const SizedBox(height: 24),
            SubmitStatRow(label: 'បានឆ្លើយ', value: '$answeredCount'),
            SubmitStatRow(
              label: 'មិនទាន់ឆ្លើយ',
              value: '${totalQuestions - answeredCount}',
            ),
            const SubmitStatRow(
              label: 'កំណត់សម្គាល់សម្រាប់ពិនិត្យ',
              value: '2',
              warning: true,
            ),
            const SizedBox(height: 12),
            if (errorMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: warningBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.deepOrange.withValues(alpha: .45),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.orangeAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: warningBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.deepOrange.withValues(alpha: .45),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'សូមពិនិត្យចម្លើយមុនដាក់បញ្ចប់ ព្រោះអ្នកនៅមានសំណួរមិនទាន់ឆ្លើយ។',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: FilledButton.styleFrom(
                fixedSize: const Size.fromHeight(56),
                backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'ដាក់បញ្ចប់',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                fixedSize: const Size.fromHeight(48),
                foregroundColor: textColor,
                side: BorderSide(color: lineColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('ត្រឡប់ទៅកែ'),
            ),
          ],
        ),
      ),
    );
  }
}

class SubmitStatRow extends StatelessWidget {
  const SubmitStatRow({
    super.key,
    required this.label,
    required this.value,
    this.warning = false,
  });

  final String label;
  final String value;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final cardColor = AdaptiveColors.card(context);
    final lineColor = AdaptiveColors.line(context);
    final textColor = AdaptiveColors.text(context);
    final mutedColor = AdaptiveColors.muted(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: lineColor),
      ),
      child: Row(
        children: [
          Icon(
            warning ? Icons.flag_rounded : Icons.circle,
            color: warning ? Colors.deepOrangeAccent : mutedColor,
            size: 14,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(color: textColor)),
          ),
          Text(
            value,
            style: TextStyle(
              color: warning ? Colors.deepOrangeAccent : textColor,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
