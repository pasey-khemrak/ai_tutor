import 'package:ai_tutor/features/quizzes/quiz_models.dart';
import 'package:ai_tutor/features/quizzes/quiz_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('targeted practice uses an injected repository and preserves tutor context', () async {
    final repository = _FakeQuizRepository();

    final quiz = await repository.loadTopicQuiz(
      subjectId: 'math',
      topicId: 'linear-equations',
      gradeLevelId: 'grade-10',
      tutorSessionId: 'session-1',
      skillTags: const ['inverse_operations'],
      verificationResults: const ['invalid'],
      hintCount: 2,
    );

    expect(quiz.quizId, 'practice-session-1');
    expect(repository.requestedSessionId, 'session-1');
    expect(repository.requestedVerificationResults, ['invalid']);
  });

  test('practice answers are submitted through the injected repository', () async {
    final repository = _FakeQuizRepository();
    final result = await repository.submitAnswers(
      quizId: 'practice-session-1',
      answers: const [
        QuizAnswerSubmissionEntity(
          questionId: 'practice-q1',
          selectedOptionId: 'a',
          answer: 'Subtract 5 from both sides',
        ),
      ],
    );

    expect(repository.submittedQuizId, 'practice-session-1');
    expect(result.correctCount, 1);
    expect(result.answers.single.feedback, 'Correct.');
  });
}

class _FakeQuizRepository implements QuizRepository {
  String? requestedSessionId;
  List<String> requestedVerificationResults = const [];
  String? submittedQuizId;

  @override
  Future<QuizEntity> loadTopicQuiz({
    required String topicId,
    required String subjectId,
    required String gradeLevelId,
    String? tutorSessionId,
    List<String> skillTags = const [],
    List<String> learningGoals = const [],
    List<String> misconceptions = const [],
    int hintCount = 0,
    int stuckCount = 0,
    List<String> verificationResults = const [],
    List<Map<String, dynamic>> verificationEvidence = const [],
    double? priorMastery,
    int? priorQuizScore,
  }) async {
    requestedSessionId = tutorSessionId;
    requestedVerificationResults = verificationResults;
    return QuizEntity.fromJson({
      'quiz_id': 'practice-${tutorSessionId ?? 'new'}',
      'subject_id': subjectId,
      'topic_id': topicId,
      'grade_level_id': gradeLevelId,
      'title': 'Targeted practice',
      'description': 'Practice the next small skill.',
      'difficulty_level': 'beginner',
      'generation_source': 'validated_ai',
      'total_questions': 1,
      'questions': [
        {
          'question_id': 'practice-q1',
          'order': 1,
          'question_text': 'What operation removes +5?',
          'question_type': 'multiple_choice',
          'options': [
            {'option_id': 'a', 'label': 'A', 'text': 'Subtract 5 from both sides'},
          ],
        },
      ],
    });
  }

  @override
  Future<QuizAttemptResultEntity> submitAnswers({
    required String quizId,
    required List<QuizAnswerSubmissionEntity> answers,
  }) async {
    submittedQuizId = quizId;
    return QuizAttemptResultEntity(
      quizAttemptId: 'attempt-1',
      quizId: quizId,
      userId: 'student-1',
      score: 100,
      correctCount: 1,
      incorrectCount: 0,
      skippedCount: 0,
      totalQuestions: 1,
      answers: const [
        QuizScoredAnswerEntity(
          questionId: 'practice-q1',
          selectedOptionId: 'a',
          submittedAnswer: 'Subtract 5 from both sides',
          isCorrect: true,
          scoreAwarded: 1,
          feedback: 'Correct.',
        ),
      ],
      submittedAt: '2026-08-11T00:00:00.000Z',
    );
  }
}
