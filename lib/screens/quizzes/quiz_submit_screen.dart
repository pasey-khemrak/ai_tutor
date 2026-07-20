import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class QuizSubmitScreen extends StatelessWidget {
  const QuizSubmitScreen({
    super.key,
    required this.onSubmit,
    required this.onBack,
  });

  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 42, 22, 28),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.panel,
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
            const Text(
              'ដាក់បញ្ចប់?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'អ្នកបានឆ្លើយសំណួរចំនួន 17 ក្នុងចំណោម 20 សំណួរ។',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 24),
            const SubmitStatRow(label: 'បានឆ្លើយ', value: '17'),
            const SubmitStatRow(label: 'មិនទាន់ឆ្លើយ', value: '3'),
            const SubmitStatRow(
              label: 'កំណត់សម្គាល់សម្រាប់ពិនិត្យ',
              value: '2',
              warning: true,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF3A2322),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.deepOrange.withValues(alpha: .45)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'សូមពិនិត្យចម្លើយមុនដាក់បញ្ចប់ ព្រោះអ្នកនៅមានសំណួរមិនទាន់ឆ្លើយ។',
                      style: TextStyle(color: Colors.orangeAccent, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: onSubmit,
              style: FilledButton.styleFrom(
                fixedSize: const Size.fromHeight(56),
                backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'ដាក់បញ្ចប់',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                fixedSize: const Size.fromHeight(48),
                foregroundColor: AppColors.text,
                side: BorderSide(color: AppColors.muted.withValues(alpha: .5)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(
            warning ? Icons.flag_rounded : Icons.circle,
            color: warning ? Colors.deepOrangeAccent : AppColors.muted,
            size: 14,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.text)),
          ),
          Text(
            value,
            style: TextStyle(
              color: warning ? Colors.deepOrangeAccent : AppColors.text,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
