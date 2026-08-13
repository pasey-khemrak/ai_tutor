import 'package:flutter/material.dart';

import '../../features/quizzes/quiz_catalog.dart';
import '../../features/quizzes/quiz_models.dart';
import '../../features/quizzes/quiz_repository.dart';
import '../../shared/state_widgets/app_error_state.dart';
import 'legacy_quizzes_screen.dart';
import 'quiz_intro_screen.dart';
import 'quiz_question_screen.dart';
import 'quiz_review_screen.dart';
import 'quiz_result_screen.dart';
import 'quiz_submit_screen.dart';

class QuizzesScreen extends StatefulWidget {
  QuizzesScreen({super.key, QuizRepository? repository, this.catalogRepository})
    : repository = repository ?? buildDefaultQuizRepository();

  final QuizRepository repository;
  final QuizCatalogRepository? catalogRepository;

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  int _step = 0;
  int _questionIndex = 0;
  QuizCatalogItem? _selectedQuiz;
  QuizEntity? _activeQuiz;
  QuizAttemptResultEntity? _result;
  bool _isLoadingQuiz = false;
  bool _isSubmitting = false;
  String? _loadError;
  String? _submitError;
  final Map<String, QuizAnswerSubmissionEntity> _answers = {};

  void _goTo(int step) => setState(() => _step = step);

  void _selectQuiz(QuizCatalogItem quiz) {
    setState(() {
      _selectedQuiz = quiz;
      _step = 1;
      _questionIndex = 0;
      _activeQuiz = null;
      _result = null;
      _answers.clear();
      _loadError = null;
      _submitError = null;
    });
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    final selectedQuiz = _selectedQuiz;
    if (selectedQuiz == null ||
        selectedQuiz.backendTopicId.isEmpty ||
        selectedQuiz.backendSubjectId.isEmpty ||
        selectedQuiz.backendGradeLevelId.isEmpty) {
      setState(
        () => _loadError = 'This quiz is not configured for practice yet.',
      );
      return;
    }
    setState(() {
      _isLoadingQuiz = true;
      _loadError = null;
    });
    try {
      final loaded = await widget.repository.loadTopicQuiz(
        topicId: selectedQuiz.backendTopicId,
        subjectId: selectedQuiz.backendSubjectId,
        gradeLevelId: selectedQuiz.backendGradeLevelId,
      );
      if (!mounted) return;
      setState(() => _activeQuiz = loaded);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = 'Could not load quiz. $error');
    } finally {
      if (mounted) {
        setState(() => _isLoadingQuiz = false);
      }
    }
  }

  void _setAnswer(QuizAnswerSubmissionEntity answer) {
    setState(() => _answers[answer.questionId] = answer);
  }

  void _nextQuestionOrSubmit() {
    final quiz = _activeQuiz;
    if (quiz == null) return;
    if (_questionIndex < quiz.questions.length - 1) {
      setState(() => _questionIndex += 1);
    } else {
      setState(() => _step = 3);
    }
  }

  void _previousQuestionOrIntro() {
    if (_questionIndex > 0) {
      setState(() => _questionIndex -= 1);
    } else {
      setState(() => _step = 1);
    }
  }

  Future<void> _submitQuiz() async {
    final quiz = _activeQuiz;
    if (quiz == null) return;
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    try {
      final result = await widget.repository.submitAnswers(
        quizId: quiz.quizId,
        answers: _answers.values.toList(),
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _step = 4;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitError = 'Could not submit quiz. $error');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = _activeQuiz;
    return switch (_step) {
      0 => LegacyQuizzesScreen(
        onSelectQuiz: _selectQuiz,
        repository: widget.catalogRepository ?? const QuizCatalogRepository(),
      ),
      1 => QuizIntroScreen(
        quiz: _selectedQuiz!,
        loadedQuiz: quiz,
        isLoading: _isLoadingQuiz,
        errorMessage: _loadError,
        onStart: () => _goTo(2),
        onBack: () => _goTo(0),
        onRetry: _loadQuiz,
      ),
      2 =>
        quiz == null
            ? AppErrorState(
                message: _loadError ?? 'Quiz is not ready.',
                onRetry: _loadQuiz,
              )
            : QuizQuestionScreen(
                quiz: quiz,
                questionIndex: _questionIndex,
                selectedAnswer:
                    _answers[quiz.questions[_questionIndex].questionId],
                onAnswerChanged: _setAnswer,
                onNext: _nextQuestionOrSubmit,
                onResults: () => _goTo(3),
                onBack: _previousQuestionOrIntro,
              ),
      3 => QuizSubmitScreen(
        answeredCount: _answers.length,
        totalQuestions: quiz?.questions.length ?? 0,
        isSubmitting: _isSubmitting,
        errorMessage: _submitError,
        onSubmit: _submitQuiz,
        onBack: () => _goTo(2),
      ),
      4 =>
        _result == null
            ? AppErrorState(
                message: _submitError ?? 'Quiz result is not ready.',
              )
            : QuizResultScreen(
                result: _result!,
                onReview: () => _goTo(5),
                onRetry: () {
                  setState(() {
                    _questionIndex = 0;
                    _result = null;
                    _answers.clear();
                    _step = 2;
                  });
                },
              ),
      _ => QuizReviewScreen(onRestart: () => _goTo(0)),
    };
  }
}
