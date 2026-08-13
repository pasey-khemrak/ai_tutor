class QuizEntity {
  const QuizEntity({
    required this.quizId,
    required this.subjectId,
    required this.topicId,
    required this.gradeLevelId,
    required this.title,
    required this.description,
    required this.difficultyLevel,
    required this.generationSource,
    required this.totalQuestions,
    required this.questions,
  });

  factory QuizEntity.fromJson(Map<String, dynamic> json) {
    return QuizEntity(
      quizId: _string(json['quiz_id']),
      subjectId: _string(json['subject_id']),
      topicId: _string(json['topic_id']),
      gradeLevelId: _string(json['grade_level_id']),
      title: _string(json['title'], fallback: 'Practice quiz'),
      description: _string(json['description']),
      difficultyLevel: _string(json['difficulty_level'], fallback: 'beginner'),
      generationSource: _string(
        json['generation_source'],
        fallback: 'local_seed',
      ),
      totalQuestions: _int(json['total_questions']),
      questions: _list(
        json['questions'],
      ).map((item) => QuizQuestionEntity.fromJson(item)).toList(),
    );
  }

  final String quizId;
  final String subjectId;
  final String topicId;
  final String gradeLevelId;
  final String title;
  final String description;
  final String difficultyLevel;
  final String generationSource;
  final int totalQuestions;
  final List<QuizQuestionEntity> questions;
}

class QuizQuestionEntity {
  const QuizQuestionEntity({
    required this.questionId,
    required this.order,
    required this.questionText,
    required this.questionType,
    required this.options,
    this.visualizationData,
  });

  factory QuizQuestionEntity.fromJson(Map<String, dynamic> json) {
    return QuizQuestionEntity(
      questionId: _string(json['question_id']),
      order: _int(json['order']),
      questionText: _string(json['question_text']),
      questionType: _string(json['question_type'], fallback: 'multiple_choice'),
      options: _list(
        json['options'],
      ).map((item) => QuizOptionEntity.fromJson(item)).toList(),
      visualizationData: json['visualization_data'] is Map<String, dynamic>
          ? json['visualization_data'] as Map<String, dynamic>
          : null,
    );
  }

  final String questionId;
  final int order;
  final String questionText;
  final String questionType;
  final List<QuizOptionEntity> options;
  final Map<String, dynamic>? visualizationData;

  bool get isMultipleChoice => questionType == 'multiple_choice';
}

class QuizOptionEntity {
  const QuizOptionEntity({
    required this.optionId,
    required this.label,
    required this.text,
  });

  factory QuizOptionEntity.fromJson(Map<String, dynamic> json) {
    return QuizOptionEntity(
      optionId: _string(json['option_id']),
      label: _string(json['label']),
      text: _string(json['text']),
    );
  }

  final String optionId;
  final String label;
  final String text;
}

class QuizAnswerSubmissionEntity {
  const QuizAnswerSubmissionEntity({
    required this.questionId,
    this.selectedOptionId,
    this.answer,
  });

  final String questionId;
  final String? selectedOptionId;
  final String? answer;

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      if (selectedOptionId != null) 'selected_option_id': selectedOptionId,
      if (answer != null) 'answer': answer,
    };
  }
}

class QuizAttemptResultEntity {
  const QuizAttemptResultEntity({
    required this.quizAttemptId,
    required this.quizId,
    required this.userId,
    required this.score,
    required this.correctCount,
    required this.incorrectCount,
    required this.skippedCount,
    required this.totalQuestions,
    required this.answers,
    required this.submittedAt,
  });

  factory QuizAttemptResultEntity.fromJson(Map<String, dynamic> json) {
    return QuizAttemptResultEntity(
      quizAttemptId: _string(json['quiz_attempt_id']),
      quizId: _string(json['quiz_id']),
      userId: _string(json['user_id']),
      score: _int(json['score']),
      correctCount: _int(json['correct_count']),
      incorrectCount: _int(json['incorrect_count']),
      skippedCount: _int(json['skipped_count']),
      totalQuestions: _int(json['total_questions']),
      answers: _list(
        json['answers'],
      ).map((item) => QuizScoredAnswerEntity.fromJson(item)).toList(),
      submittedAt: _string(json['submitted_at']),
    );
  }

  final String quizAttemptId;
  final String quizId;
  final String userId;
  final int score;
  final int correctCount;
  final int incorrectCount;
  final int skippedCount;
  final int totalQuestions;
  final List<QuizScoredAnswerEntity> answers;
  final String submittedAt;
}

class QuizScoredAnswerEntity {
  const QuizScoredAnswerEntity({
    required this.questionId,
    this.selectedOptionId,
    required this.submittedAnswer,
    required this.isCorrect,
    required this.scoreAwarded,
    required this.feedback,
  });

  factory QuizScoredAnswerEntity.fromJson(Map<String, dynamic> json) {
    return QuizScoredAnswerEntity(
      questionId: _string(json['question_id']),
      selectedOptionId: json['selected_option_id'] is String
          ? json['selected_option_id'] as String
          : null,
      submittedAnswer: _string(json['submitted_answer']),
      isCorrect: json['is_correct'] == true,
      scoreAwarded: _int(json['score_awarded']),
      feedback: _string(json['feedback']),
    );
  }

  final String questionId;
  final String? selectedOptionId;
  final String submittedAnswer;
  final bool isCorrect;
  final int scoreAwarded;
  final String feedback;
}

String _string(Object? value, {String fallback = ''}) {
  return value is String && value.trim().isNotEmpty ? value : fallback;
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return fallback;
}

List<Map<String, dynamic>> _list(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().toList();
}
