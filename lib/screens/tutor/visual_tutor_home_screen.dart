import 'package:flutter/material.dart';

import '../../features/quizzes/quiz_repository.dart';
import '../../features/visual_tutor/presentation/providers/step_board_provider.dart';
import '../learning_selection/learning_selection_repository.dart';
import '../lessons/student_lessons_repository.dart';
import 'tutor_screen.dart';

/// The Tutor tab: dedicated, frictionless "Homework & Problem Solver" where
/// a student brings any math, physics, or chemistry problem to solve.
///
/// Directly presents the Whiteboard in [LearningContext.askQuestion] mode
/// (`is_curriculum_scoped: false`, topic unconstrained).
class VisualTutorHomeScreen extends StatelessWidget {
  const VisualTutorHomeScreen({
    super.key,
    this.context,
    this.initialSessionId,
    this.initialSubmission,
    this.initialPrefill,
    this.voiceMode = false,
    this.onOpenTargetedPractice,
    this.onOpenLesson,
    this.onAskQuestion,
    this.repository,
    this.stepBoard,
  });

  /// The active learning context. Defaults to [LearningContext.askQuestion]
  /// so that the Whiteboard opens directly in unconstrained problem-solving mode.
  final LearningContext? context;

  final String? initialSessionId;
  final VisualTutorStudentSubmission? initialSubmission;
  final String? initialPrefill;
  final bool voiceMode;
  final ValueChanged<TargetedPracticeContext>? onOpenTargetedPractice;
  final ValueChanged<StudentLesson>? onOpenLesson;
  final ValueChanged<String?>? onAskQuestion;
  final StudentLessonsRepository? repository;
  final StepBoardProvider? stepBoard;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const Key('visual-tutor-home-screen'),
      child: TutorScreen(
        context: this.context ?? const LearningContext.askQuestion(),
        initialSessionId: initialSessionId,
        initialSubmission: initialSubmission,
        initialPrefill: initialPrefill,
        voiceMode: voiceMode,
        onOpenTargetedPractice: onOpenTargetedPractice,
      ),
    );
  }
}
