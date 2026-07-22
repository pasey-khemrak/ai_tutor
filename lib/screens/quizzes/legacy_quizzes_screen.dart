import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../features/quizzes/quiz_catalog.dart';

class LegacyQuizzesScreen extends StatelessWidget {
  const LegacyQuizzesScreen({
    super.key,
    required this.onSelectQuiz,
    this.repository = const QuizCatalogRepository(),
  });

  final ValueChanged<QuizCatalogItem> onSelectQuiz;
  final QuizCatalogRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QuizCatalogItem>>(
      stream: repository.watchQuizzes(),
      initialData: demoQuizCatalog,
      builder: (context, snapshot) {
        final quizzes = snapshot.data ?? demoQuizCatalog;

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
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 18,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 48),
              const SectionTitle(),
              const SizedBox(height: 18),
              for (final quiz in quizzes)
                QuizCard(
                  key: Key('${quiz.id}-quiz-card'),
                  quiz: quiz,
                  onTap: () => onSelectQuiz(quiz),
                ),
              if (snapshot.hasError)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Cannot reach Firebase right now. Showing saved quiz options.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          'វិញ្ញាសារ',
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
    required this.quiz,
    required this.onTap,
  });

  final QuizCatalogItem quiz;
  final VoidCallback onTap;

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
                  child: Icon(quiz.icon, color: quiz.iconColor, size: 32),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
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
                        quiz.subtitle,
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
                        '${quiz.progressPercent}%',
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
                          value: quiz.progress,
                          minHeight: 5,
                          backgroundColor: Colors.white.withValues(alpha: .12),
                          valueColor: AlwaysStoppedAnimation(
                            quiz.progressColor,
                          ),
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
