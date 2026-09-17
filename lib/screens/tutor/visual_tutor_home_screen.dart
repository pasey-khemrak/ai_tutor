import 'package:flutter/material.dart';

import '../../features/visual_tutor/presentation/visual_tutor_design.dart';
import '../../features/visual_tutor/presentation/providers/step_board_provider.dart';
import '../../features/visual_tutor/presentation/widgets/rich_media_canvas.dart';
import '../../features/visual_tutor/presentation/widgets/step_interaction_widget.dart';
import '../../features/visual_tutor/presentation/widgets/step_progress_indicator.dart';
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
    this.onOpenLessons,
    this.stepBoard,
  });

  final VoidCallback onBack;
  final VoidCallback onTypeQuestion;
  final VoidCallback onVoiceInput;
  final VoidCallback onStuck;
  final ValueChanged<LearningContext> onContinueLearning;
  final VoidCallback onScanProblem;
  final VoidCallback? onOpenLessons;

  /// When a confirmed expert lesson is active, this replaces the landing menu.
  final StepBoardProvider? stepBoard;

  @override
  Widget build(BuildContext context) {
    if (stepBoard != null) return _StepTeachingHome(provider: stepBoard!);
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
                    _ContinueLearningHeader(onSeeAll: onOpenLessons ?? onBack),
                    const SizedBox(height: VisualTutorSpacing.md),
                    _PublishedLessonsPrompt(onTap: onOpenLessons ?? onBack),
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

class _StepTeachingHome extends StatelessWidget {
  const _StepTeachingHome({required this.provider});
  final StepBoardProvider provider;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: provider,
    builder: (context, _) {
      final step = provider.currentStep;
      if (step == null) return const Center(child: CircularProgressIndicator());
      final objective =
          step.content['learning_objective'] as String? ??
          step.visualizationType.replaceAll('_', ' ');
      final feedback =
          provider.response?.evaluation?['feedback_message'] as String?;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StepProgressIndicator(
                currentStep: provider.currentStepNumber,
                totalSteps: provider.totalSteps,
                learningObjective: objective,
              ),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: SizedBox(
                  key: ValueKey(step.stepId),
                  height: 350,
                  child: RichMediaCanvas(
                    mediaChildren: [
                      Center(
                        child: _VisualizationCaption(
                          stepType: step.visualizationType,
                          content: step.content,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              StepInteractionWidget(
                responseType: step.expectedResponseType,
                question:
                    '${step.studentQuestion}\n${step.studentQuestionKhmer}',
                choices: _choices(step.content),
                isLoading: provider.isLoading,
                feedback: feedback ?? provider.error,
                onSubmit: provider.submit,
                onHint: provider.requestHint,
                onSkip: provider.skip,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _VisualizationCaption extends StatelessWidget {
  const _VisualizationCaption({required this.stepType, required this.content});
  final String stepType;
  final Map<String, dynamic> content;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_iconFor(stepType), size: 56, color: VisualTutorColors.cyan),
        const SizedBox(height: 12),
        Text(
          stepType.replaceAll('_', ' '),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (content['equation'] is String) Text(content['equation'] as String),
      ],
    ),
  );
}

IconData _iconFor(String type) => switch (type) {
  'free_body_diagram' || 'vector_analysis' => Icons.arrow_outward_rounded,
  'motion_graphs' || 'graph' => Icons.show_chart_rounded,
  'molecule' || 'molecular_structure' => Icons.hub_rounded,
  'geometry' => Icons.change_history_rounded,
  _ => Icons.auto_awesome_rounded,
};

List<String> _choices(Map<String, dynamic> content) =>
    (content['choices'] as List? ?? const []).whereType<String>().toList(
      growable: false,
    );

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

class _PublishedLessonsPrompt extends StatelessWidget {
  const _PublishedLessonsPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VisualTutorRadius.lg),
        child: Container(
          key: const Key('tutor-open-lessons-prompt'),
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
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: VisualTutorColors.cyan,
                  size: 28,
                ),
              ),
              const SizedBox(width: VisualTutorSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Browse published lessons',
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
                    const Text(
                      'Choose a lesson from the Lessons tab, then continue here.',
                      style: VisualTutorTypography.khmerSubtitle,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: VisualTutorColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
