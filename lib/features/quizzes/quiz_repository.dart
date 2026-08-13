import 'dart:async';

import '../../core/config/app_config.dart';
import '../../core/auth/auth_service.dart';
import '../../core/network/api_client.dart';
import 'quiz_models.dart';

abstract class QuizRepository {
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
  });

  Future<QuizAttemptResultEntity> submitAnswers({
    required String quizId,
    required List<QuizAnswerSubmissionEntity> answers,
  });
}

class QuizRemoteRepository implements QuizRepository {
  QuizRemoteRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;
  final Map<String, String> _topicByQuizId = {};
  final Map<String, String> _subjectByQuizId = {};
  final Map<String, Map<String, dynamic>> _pendingProgressSyncs = {};
  Timer? _progressRetryTimer;

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
    unawaited(_flushPendingProgress());
    try {
      if (tutorSessionId != null) {
        throw const ApiException(
          message: 'Targeted practice must be generated',
          statusCode: 404,
        );
      }
      final response = await _apiClient.get(
        '/quizzes/topic/$topicId',
        queryParameters: {
          'subject_id': subjectId,
          'grade_level_id': gradeLevelId,
        },
      );
      final quiz = QuizEntity.fromJson(_unwrapData(response));
      _topicByQuizId[quiz.quizId] = topicId;
      _subjectByQuizId[quiz.quizId] = subjectId;
      return quiz;
    } on ApiException catch (error) {
      if (error.statusCode != 404 && error.statusCode != 503) rethrow;
      final generated = await _apiClient.post(
        '/quizzes/generate',
        body: {
          'subject_id': subjectId,
          'topic_id': topicId,
          'grade_level_id': gradeLevelId,
          'difficulty_level': 'beginner',
          'tutor_session_id': ?tutorSessionId,
          'skill_tags': skillTags,
          'learning_goals': learningGoals,
          'misconceptions': misconceptions,
          'hint_count': hintCount,
          'stuck_count': stuckCount,
          'verification_results': verificationResults,
          'verification_evidence': verificationEvidence,
          'prior_mastery': ?priorMastery,
          'prior_quiz_score': ?priorQuizScore,
        },
      );
      final quiz = QuizEntity.fromJson(_unwrapData(generated));
      _topicByQuizId[quiz.quizId] = topicId;
      _subjectByQuizId[quiz.quizId] = subjectId;
      return quiz;
    }
  }

  @override
  Future<QuizAttemptResultEntity> submitAnswers({
    required String quizId,
    required List<QuizAnswerSubmissionEntity> answers,
  }) async {
    unawaited(_flushPendingProgress());
    final response = await _apiClient.post(
      '/quizzes/$quizId/submit',
      body: {'answers': answers.map((answer) => answer.toJson()).toList()},
    );
    final result = QuizAttemptResultEntity.fromJson(_unwrapData(response));
    unawaited(_recordProgressSafely(result));
    return result;
  }

  Future<void> _recordProgressSafely(QuizAttemptResultEntity result) async {
    final payload = <String, dynamic>{
      'quiz_attempt_id': result.quizAttemptId,
      'quiz_id': result.quizId,
      'topic_id': _topicByQuizId[result.quizId],
      'subject_id': _subjectByQuizId[result.quizId],
      'score': result.score,
      'correct_count': result.correctCount,
      'incorrect_count': result.incorrectCount,
      'skipped_count': result.skippedCount,
      'metadata': {
        'submitted_at': result.submittedAt,
        'total_questions': result.totalQuestions,
      },
    };
    _pendingProgressSyncs[result.quizAttemptId] = payload;
    await _flushPendingProgress();
  }

  Future<void> _flushPendingProgress() async {
    if (_pendingProgressSyncs.isEmpty) return;
    final pending = Map<String, Map<String, dynamic>>.from(
      _pendingProgressSyncs,
    );
    try {
      for (final entry in pending.entries) {
        await _apiClient.post('/progress/quiz-attempts', body: entry.value);
        _pendingProgressSyncs.remove(entry.key);
      }
    } catch (_) {
      // The scored result is already durable. Retain its progress event and
      // retry in the background and on the student's next quiz action; never
      // discard it or block the tutoring flow during an outage/restart.
      _scheduleProgressRetry();
    }
  }

  void _scheduleProgressRetry() {
    if (_progressRetryTimer?.isActive ?? false) return;
    _progressRetryTimer = Timer(const Duration(seconds: 2), () {
      unawaited(_flushPendingProgress());
    });
  }

  Map<String, dynamic> _unwrapData(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map<String, dynamic> ? data : response;
  }
}

QuizRepository buildDefaultQuizRepository({ApiClient? apiClient}) {
  final client =
      apiClient ??
      ApiClient(
        config: AppConfig.current,
        tokenProvider: appAuthService.getAccessToken,
      );
  // Targeted practice is generated and graded by the authenticated backend.
  // Never substitute a seeded answer key when the service is unavailable.
  return QuizRemoteRepository(apiClient: client);
}
