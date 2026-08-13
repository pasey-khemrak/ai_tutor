import 'package:flutter/material.dart';

import '../../features/visual_tutor/presentation/visual_tutor_design.dart';
import '../../shared/rean_avatar.dart';
import '../learning_selection/learning_selection_repository.dart';

class VisualTutorHomeScreen extends StatelessWidget {
  const VisualTutorHomeScreen({
    super.key,
    required this.onBack,
    required this.onTypeQuestion,
    required this.onVoiceInput,
    required this.onStuck,
    required this.onContinueLearning,
    required this.onScanProblem,
  });

  final VoidCallback onBack;
  final VoidCallback onTypeQuestion;
  final VoidCallback onVoiceInput;
  final VoidCallback onStuck;
  final ValueChanged<LearningContext> onContinueLearning;
  final VoidCallback onScanProblem;

  static const _recentLessons = [
    _RecentTutorLesson(
      title: 'Quadratic Equations',
      subject: 'Mathematics',
      grade: 11,
      progress: 98,
      icon: Icons.science_outlined,
      accent: VisualTutorColors.success,
    ),
    _RecentTutorLesson(
      title: 'Organic Chemistry',
      subject: 'Chemistry',
      grade: 11,
      progress: 45,
      icon: Icons.bubble_chart_outlined,
      accent: VisualTutorColors.orange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('visual-tutor-home-screen'),
      color: VisualTutorColors.shell,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 430;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                VisualTutorSpacing.xl,
                compact ? VisualTutorSpacing.md : VisualTutorSpacing.xl,
                VisualTutorSpacing.xl,
                VisualTutorSpacing.xl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _VisualTutorHomeHeader(onBack: onBack),
                    const SizedBox(height: VisualTutorSpacing.xl),
                    const _WelcomePanel(),
                    const SizedBox(height: VisualTutorSpacing.xl),
                    VisualTutorActionCard(
                      key: const Key('scan-problem-card'),
                      icon: Icons.camera_alt_rounded,
                      iconBackground: VisualTutorColors.scanIconBackground,
                      title: 'Scan a Problem',
                      subtitle: 'ថតរូបលំហាត់គណិតវិទ្យា',
                      onTap: onScanProblem,
                    ),
                    const SizedBox(height: VisualTutorSpacing.md),
                    VisualTutorActionCard(
                      key: const Key('type-question-card'),
                      icon: Icons.keyboard_rounded,
                      iconBackground: VisualTutorColors.typeIconBackground,
                      title: 'Type a Question',
                      subtitle: 'សរសេរសំណួររបស់អ្នក',
                      onTap: onTypeQuestion,
                    ),
                    const SizedBox(height: VisualTutorSpacing.md),
                    VisualTutorActionCard(
                      key: const Key('voice-input-card'),
                      icon: Icons.mic_rounded,
                      iconBackground: VisualTutorColors.voiceIconBackground,
                      title: 'Voice Input',
                      subtitle: 'ប្រើសំឡេងដើម្បីសួរ',
                      onTap: onVoiceInput,
                    ),
                    const SizedBox(height: VisualTutorSpacing.xxl),
                    _StuckCard(onStart: onStuck),
                    const SizedBox(height: VisualTutorSpacing.xxl),
                    _ContinueLearningHeader(onSeeAll: onTypeQuestion),
                    const SizedBox(height: VisualTutorSpacing.md),
                    for (final lesson in _recentLessons) ...[
                      _RecentLessonCard(
                        lesson: lesson,
                        onTap: () => onContinueLearning(
                          LearningContext(
                            grade: lesson.grade,
                            subject: lesson.subject,
                            topic: lesson.title,
                          ),
                        ),
                      ),
                      const SizedBox(height: VisualTutorSpacing.md),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VisualTutorHomeHeader extends StatelessWidget {
  const _VisualTutorHomeHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox.square(
          dimension: 44,
          child: IconButton.filled(
            key: const Key('visual-tutor-home-back-button'),
            onPressed: onBack,
            style: IconButton.styleFrom(
              backgroundColor: VisualTutorColors.panel,
              foregroundColor: VisualTutorColors.text,
              side: BorderSide(
                color: VisualTutorColors.cyan.withValues(alpha: .18),
              ),
            ),
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
          ),
        ),
        const SizedBox(width: VisualTutorSpacing.md),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rean AI Visual Tutor', style: VisualTutorTypography.header),
              SizedBox(height: 3),
              Text(
                'រៀនជាមួយគ្រូ AI',
                style: VisualTutorTypography.khmerSubtitle,
              ),
            ],
          ),
        ),
        const ReanAvatar(size: 52),
      ],
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('visual-tutor-welcome-panel'),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: VisualTutorDecorations.welcomePanel(),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: VisualTutorColors.cyanDark.withValues(alpha: .5),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.sentiment_satisfied_alt_rounded,
              color: VisualTutorColors.orange.withValues(alpha: .65),
              size: 24,
            ),
          ),
          const SizedBox(height: VisualTutorSpacing.xl),
          const Text(
            'How can I help you\ntoday?',
            textAlign: TextAlign.center,
            style: VisualTutorTypography.welcomeTitle,
          ),
          const SizedBox(height: VisualTutorSpacing.md),
          const Text(
            'តើខ្ញុំអាចជួយអ្នកបានយ៉ាងដូចម្តេច?',
            textAlign: TextAlign.center,
            style: VisualTutorTypography.khmerSubtitle,
          ),
        ],
      ),
    );
  }
}

class _StuckCard extends StatelessWidget {
  const _StuckCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('visual-tutor-stuck-card'),
      padding: const EdgeInsets.all(VisualTutorSpacing.xl),
      decoration: VisualTutorDecorations.stuckCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  "I'm Stuck!",
                  style: TextStyle(
                    color: VisualTutorColors.shell,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    fontFamilyFallback: VisualTutorTypography.fontFallback,
                  ),
                ),
              ),
              Icon(Icons.menu_book_rounded, color: VisualTutorColors.shell),
            ],
          ),
          const SizedBox(height: VisualTutorSpacing.md),
          const Text(
            'Get immediate step-by-step guidance on\nyour current lesson.',
            style: TextStyle(
              color: VisualTutorColors.shell,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w700,
              fontFamilyFallback: VisualTutorTypography.fontFallback,
            ),
          ),
          const SizedBox(height: VisualTutorSpacing.lg),
          FilledButton(
            key: const Key('start-live-help-button'),
            onPressed: onStart,
            style: VisualTutorButtonStyles.stuckCardCta(),
            child: const Text('Start Live Help'),
          ),
        ],
      ),
    );
  }
}

class _ContinueLearningHeader extends StatelessWidget {
  const _ContinueLearningHeader({required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Continue Learning',
            style: VisualTutorTypography.sectionTitle,
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Text(
            'See All',
            style: TextStyle(
              color: VisualTutorColors.cyan,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentLessonCard extends StatelessWidget {
  const _RecentLessonCard({required this.lesson, required this.onTap});

  final _RecentTutorLesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VisualTutorRadius.lg),
        child: Container(
          key: Key(
            'continue-${lesson.title.toLowerCase().replaceAll(' ', '-')}',
          ),
          padding: const EdgeInsets.all(VisualTutorSpacing.md),
          decoration: VisualTutorDecorations.raisedPanel(
            radius: VisualTutorRadius.lg,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: VisualTutorColors.shellElevated,
                  borderRadius: BorderRadius.circular(VisualTutorRadius.md),
                ),
                child: Icon(lesson.icon, color: lesson.accent, size: 28),
              ),
              const SizedBox(width: VisualTutorSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: VisualTutorColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        fontFamilyFallback: VisualTutorTypography.fontFallback,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lesson.subject} • Grade ${lesson.grade}',
                      style: VisualTutorTypography.khmerSubtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: VisualTutorSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${lesson.progress}%',
                    style: TextStyle(
                      color: lesson.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    width: 42,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        VisualTutorRadius.pill,
                      ),
                      child: LinearProgressIndicator(
                        value: lesson.progress / 100,
                        minHeight: 4,
                        backgroundColor: VisualTutorColors.border,
                        color: lesson.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTutorLesson {
  const _RecentTutorLesson({
    required this.title,
    required this.subject,
    required this.grade,
    required this.progress,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subject;
  final int grade;
  final int progress;
  final IconData icon;
  final Color accent;
}
