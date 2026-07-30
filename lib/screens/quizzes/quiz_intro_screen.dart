import 'package:flutter/material.dart';
import '../../core/adaptive_colors.dart';
import '../../core/app_colors.dart';
import '../../features/quizzes/quiz_catalog.dart';

class QuizIntroScreen extends StatelessWidget {
  const QuizIntroScreen({
    super.key,
    required this.quiz,
    required this.onStart,
    required this.onBack,
  });

  final QuizCatalogItem quiz;
  final VoidCallback onStart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textColor = AdaptiveColors.text(context);
    final mutedColor = AdaptiveColors.muted(context);
    final lineColor = AdaptiveColors.line(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('quiz-intro-back-button'),
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('ត្រឡប់ទៅជម្រើស'),
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor,
                side: BorderSide(color: lineColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: AppColors.answer,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cyan.withValues(alpha: .35)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: .26),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: const Center(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'f',
                        style: TextStyle(
                          color: Color(0xFFB9B4FF),
                          fontSize: 36,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(
                        text: 'x',
                        style: TextStyle(
                          color: AppColors.cyan,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            quiz.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            quiz.subtitle.replaceAll('\n', ' • '),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 36),
          Row(
            children: [
              Expanded(
                child: QuizInfoTile(
                  icon: Icons.assignment_outlined,
                  label: 'សំណួរ',
                  value: '${quiz.questionCount}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QuizInfoTile(
                  icon: Icons.timer_outlined,
                  label: 'រយៈពេល',
                  value: quiz.durationLabel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QuizInfoTile(
                  icon: Icons.auto_awesome_outlined,
                  label: 'កម្រិត',
                  value: quiz.level,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const QuizGuidelinesCard(),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              fixedSize: const Size.fromHeight(58),
              backgroundColor: AppColors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'ចាប់ផ្តើមការប្រឡង  ▶',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'By starting, you agree to the academic integrity policy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedColor,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class QuizInfoTile extends StatelessWidget {
  const QuizInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final panelColor = AdaptiveColors.panel(context);
    final labelColor = AdaptiveColors.muted(context);
    final valueColor = AdaptiveColors.text(context);

    return Container(
      height: 104,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cyan.withValues(alpha: .18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.cyan, size: 19),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: labelColor, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class QuizGuidelinesCard extends StatelessWidget {
  const QuizGuidelinesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final panelColor = AdaptiveColors.panel(context);
    final lineColor = AdaptiveColors.line(context);
    final textColor = AdaptiveColors.text(context);
    final subtleColor = AdaptiveColors.subtle(context);

    const rules = [
      'គ្រប់សំណួរទាំងអស់មានចម្លើយត្រឹមត្រូវតែ១ប៉ុណ្ណោះ',
      'ការផ្លាស់ប្ដូរចុះឡើងរវាងសំណួរនានាត្រូវបានអនុញ្ញាតក្នុងអំឡុងពេលប្រឡង/អនុវត្ត។',
      'ត្រូវប្រាកដថាអ្នកបានដាក់បញ្ជូនចម្លើយមុនពេលកំណត់',
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'សេចក្ដីណែនាំក្នុងការប្រលង',
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final rule in rules)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, color: AppColors.cyan, size: 7),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rule,
                      style: TextStyle(
                        color: subtleColor,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
