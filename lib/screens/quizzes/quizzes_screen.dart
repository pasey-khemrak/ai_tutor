import 'package:flutter/material.dart';

import 'legacy_quizzes_screen.dart';
import 'quiz_intro_screen.dart';
import 'quiz_question_screen.dart';
import 'quiz_review_screen.dart';
import 'quiz_result_screen.dart';
import 'quiz_submit_screen.dart';

class QuizzesScreen extends StatefulWidget {
  const QuizzesScreen({super.key});

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  int _step = 0;

  void _goTo(int step) => setState(() => _step = step);

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      0 => LegacyQuizzesScreen(onStartQuiz: () => _goTo(1)),
      1 => QuizIntroScreen(onStart: () => _goTo(2)),
      2 => QuizQuestionScreen(
          onNext: () => _goTo(3),
          onResults: () => _goTo(4),
        ),
      3 => QuizSubmitScreen(
          onSubmit: () => _goTo(4),
          onBack: () => _goTo(2),
        ),
      4 => QuizResultScreen(
          onReview: () => _goTo(5),
          onRetry: () => _goTo(2),
        ),
      _ => QuizReviewScreen(onRestart: () => _goTo(0)),
    };
  }
}
