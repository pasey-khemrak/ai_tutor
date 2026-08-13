import 'package:flutter/material.dart';

import '../learning_selection/learning_selection_repository.dart';
import '../tutor/tutor_screen.dart';

/// Compatibility entry point for old routes. Voice is a TutorScreen mode, not
/// a standalone simulation: it records, transcribes, and submits a real tutor
/// turn through the same authenticated Visual Tutor flow.
class VoiceScreen extends StatelessWidget {
  const VoiceScreen({super.key});

  @override
  Widget build(BuildContext context) => const TutorScreen(
    context: LearningContext(
      grade: 10,
      subject: 'Mathematics',
      topic: 'Linear Equations',
    ),
    initialSubmission: VisualTutorStudentSubmission(
      message: '',
      intent: 'voice_ready',
      action: 'start_voice',
      inputType: 'voice',
      metadata: {'entry_point': 'legacy_voice_route'},
    ),
  );
}
