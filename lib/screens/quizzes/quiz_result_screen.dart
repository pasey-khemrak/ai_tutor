import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({
    super.key,
    required this.onReview,
    required this.onRetry,
  });

  final VoidCallback onReview;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'បានបញ្ចប់ការតេស្ត',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 31,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.cyan, size: 18),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ល្អណាស់! អ្នកសម្រេចបានពិន្ទុខ្ពស់ក្នុងមេរៀននេះ។',
                    style: TextStyle(color: AppColors.text, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          const ScoreRing(score: .8),
          const SizedBox(height: 44),
          const Row(
            children: [
              Expanded(
                child: ResultMetric(
                  icon: Icons.check_circle,
                  label: 'ត្រឹមត្រូវ',
                  value: '16',
                  color: AppColors.cyan,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: ResultMetric(
                  icon: Icons.cancel,
                  label: 'ខុស',
                  value: '3',
                  color: AppColors.peach,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: ResultMetric(
                  icon: Icons.help,
                  label: 'មិនទាន់ឆ្លើយ',
                  value: '1',
                  color: AppColors.muted,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: ResultMetric(
                  icon: Icons.timer,
                  label: 'រយៈពេល',
                  value: '22:14',
                  color: Color(0xFFB9B4FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onReview,
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('មើលចម្លើយលម្អិត'),
            style: FilledButton.styleFrom(
              fixedSize: const Size.fromHeight(58),
              backgroundColor: AppColors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('ប្រឡងម្តងទៀត'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReview,
                  icon: const Icon(Icons.school_outlined),
                  label: const Text('រៀនពីកំហុស'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 142,
        height: 142,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: score,
                strokeWidth: 12,
                backgroundColor: AppColors.line,
                valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  '80%',
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '16 / 20 ពិន្ទុ',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ResultMetric extends StatelessWidget {
  const ResultMetric({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
