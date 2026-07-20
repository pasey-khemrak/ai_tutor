import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class LegacyQuizzesScreen extends StatelessWidget {
  const LegacyQuizzesScreen({super.key, required this.onStartQuiz});

  final VoidCallback onStartQuiz;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'គណិតវិទ្យា',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'ថ្នាក់ទី១២\n​វិញ្ញាសារត្រៀមប្រលងបាក់ឌុប',
            style: TextStyle(color: AppColors.muted, fontSize: 18, height: 1.35),
          ),
          const SizedBox(height: 48),
          const SectionTitle(),
          const SizedBox(height: 18),
          QuizCard(
            key: const Key('bac-dup-quiz-card'),
            icon: Icons.edit_note_rounded,
            iconColor: const Color(0xFFFFD267),
            title: 'បាក់ឌុប',
            subtitle: 'វិញ្ញាសាត្រៀមពីឆ្នាំ\n២០១៤-២០២៦',
            progress: 1,
            progressColor: AppColors.cyan,
            onTap: onStartQuiz,
          ),
          const QuizCard(
            icon: Icons.calculate_rounded,
            iconColor: Color(0xFFFFBC55),
            title: 'ប្រចាំឆមាស',
            subtitle: 'Vectors,\nMatrices, and\nEigenspaces',
            progress: .82,
            progressColor: Color(0xFFB9B4FF),
          ),
          const QuizCard(
            icon: Icons.hub_rounded,
            iconColor: Color(0xFF3EF2A1),
            title: 'ប្រចាំខែ',
            subtitle: 'Probability,\nDistributions,\nand Hypothesis',
            progress: .45,
            progressColor: Color(0xFFC9A8FF),
          ),
          const QuizCard(
            icon: Icons.menu_book_rounded,
            iconColor: Color(0xFFFF4D8D),
            title: 'វិញ្ញាសារតាមមេរៀន',
            subtitle: 'មេរៀនថ្នាក់ទី១២\nតាមទីសៀវភៅពុម្ព',
            progress: .45,
            progressColor: Color(0xFFC9A8FF),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Text(
          'វិញ្ញាសា',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        Spacer(),
        Text(
          'View Roadmap',
          style: TextStyle(
            color: AppColors.cyan,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}

class QuizCard extends StatelessWidget {
  const QuizCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.progressColor,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final double progress;
  final Color progressColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: AppColors.card.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 14, 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .08),
                    ),
                  ),
                  child: Icon(icon, color: iconColor, size: 32),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 16,
                          height: 1.28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 112,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: Colors.white.withValues(alpha: .12),
                          valueColor: AlwaysStoppedAnimation(progressColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
