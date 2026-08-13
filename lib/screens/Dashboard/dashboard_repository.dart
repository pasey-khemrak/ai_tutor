import '../../core/config/app_config.dart';
import '../../core/auth/auth_service.dart';
import '../../core/network/api_client.dart';

class StudentDashboardData {
  const StudentDashboardData({
    required this.studentName,
    required this.gradeLabel,
    required this.subjects,
    required this.learningStreakDays,
    this.learningGoal,
    required this.recentActivity,
    required this.subjectProgress,
    required this.weakTopic,
    this.practiceRecommendations = const [],
    this.completedPractice = 0,
    required this.resumeTitle,
    required this.resumeSubtitle,
    this.resumeGrade,
    this.resumeSubject = '',
    this.resumeTopic = '',
    this.resumeSessionId,
  });

  final String studentName;
  final String gradeLabel;
  final List<String> subjects;
  final int learningStreakDays;
  final String? learningGoal;
  final List<DashboardActivity> recentActivity;
  final List<SubjectProgress> subjectProgress;
  final WeakTopic? weakTopic;
  final List<PracticeRecommendation> practiceRecommendations;
  final int completedPractice;
  final String resumeTitle;
  final String resumeSubtitle;
  final int? resumeGrade;
  final String resumeSubject;
  final String resumeTopic;
  final String? resumeSessionId;

  bool get isEmpty {
    return subjects.isEmpty &&
        recentActivity.isEmpty &&
        subjectProgress.isEmpty &&
        weakTopic == null &&
        studentName.isEmpty &&
        gradeLabel.isEmpty;
  }
}

class DashboardActivity {
  const DashboardActivity({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    this.topicId,
    this.tutorSessionId,
  });

  final String title;
  final String subtitle;
  final String timeLabel;
  final String? topicId;
  final String? tutorSessionId;
}

class SubjectProgress {
  const SubjectProgress({
    required this.subject,
    required this.topic,
    required this.progress,
  }) : assert(progress >= 0 && progress <= 1);

  final String subject;
  final String topic;
  final double progress;
}

class WeakTopic {
  const WeakTopic({
    required this.title,
    required this.reason,
    required this.actionLabel,
    this.topicId,
  });

  final String title;
  final String reason;
  final String actionLabel;
  final String? topicId;
}

class PracticeRecommendation {
  const PracticeRecommendation({required this.topic, required this.reason});
  final String topic;
  final String reason;
}

abstract class DashboardRepository {
  Future<StudentDashboardData?> loadDashboard();
}

class BackendDashboardRepository implements DashboardRepository {
  BackendDashboardRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<StudentDashboardData?> loadDashboard() async {
    final response = await _apiClient.get('/progress/dashboard');
    final data = _unwrapData(response);

    final learner = _map(data['learner']);
    final recentActivity = _activityList(data['recent_activity']);
    final weakTopic = _weakTopic(data['weak_topic']);
    final resume = _map(data['resume_lesson']);
    final latestTopicId = _string(resume['topic_id']).isNotEmpty
        ? _string(resume['topic_id'])
        : (recentActivity.isNotEmpty
              ? recentActivity.first.topicId
              : weakTopic?.topicId);
    final resumeTopic = _topicLabel(latestTopicId);
    final resumeSessionId = _nullableString(resume['tutor_session_id']);
    final backendSubjectProgress = _subjectProgressList(
      data['subject_progress'],
    );
    final correct = _int(data['correct_answers']);
    final incorrect = _int(data['incorrect_answers']);
    final totalAnswers = correct + incorrect;
    final averageQuizScore = _nullableInt(data['average_quiz_score']);
    final progress = totalAnswers > 0
        ? correct / totalAnswers
        : (averageQuizScore ?? 0) / 100;

    return StudentDashboardData(
      studentName: _string(learner['display_name'], fallback: 'Learner'),
      gradeLabel: _string(learner['grade_label'], fallback: 'Not selected'),
      subjects: _subjects(learner['subjects']),
      learningStreakDays: _int(data['current_streak']),
      learningGoal: _nullableString(learner['learning_goal']),
      recentActivity: recentActivity,
      subjectProgress: backendSubjectProgress.isNotEmpty
          ? backendSubjectProgress
          : (latestTopicId == null || latestTopicId.isEmpty
                ? const []
                : [
                    SubjectProgress(
                      subject: _subjectLabel(_string(resume['subject_id'])),
                      topic: resumeTopic,
                      progress: progress.clamp(0, 1).toDouble(),
                    ),
                  ]),
      weakTopic: weakTopic,
      practiceRecommendations: _practiceRecommendations(
        data['practice_recommendations'],
      ),
      completedPractice: _int(data['completed_practice']),
      resumeTitle: resumeSessionId == null ? 'Start learning' : resumeTopic,
      resumeSubtitle: resumeSessionId != null
          ? 'Resume your latest tutor activity'
          : (_nullableString(learner['learning_goal']) ??
                'Choose a learning goal to begin.'),
      resumeGrade: _gradeNumber(_string(learner['grade_label'])),
      resumeSubject: _subjectLabel(_string(resume['subject_id'])),
      resumeTopic: resumeTopic,
      resumeSessionId: resumeSessionId,
    );
  }

  Map<String, dynamic> _unwrapData(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map<String, dynamic> ? data : response;
  }

  List<SubjectProgress> _subjectProgressList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => SubjectProgress(
            subject: _subjectLabel(item['subject_id']?.toString()),
            topic: _topicLabel(item['topic_id']?.toString()),
            progress: (_int(item['progress_percent']) / 100)
                .clamp(0, 1)
                .toDouble(),
          ),
        )
        .toList();
  }

  String _subjectLabel(String? subjectId) {
    final normalized = (subjectId ?? '').trim().toLowerCase();
    if (normalized == 'math' || normalized == 'mathematics') {
      return 'Mathematics';
    }
    if (normalized.isEmpty) return 'Subject';
    return normalized
        .split('-')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}

class FallbackDashboardRepository implements DashboardRepository {
  const FallbackDashboardRepository({
    required this.remote,
    required this.fallback,
    required this.allowFallback,
  });

  final DashboardRepository remote;
  final DashboardRepository fallback;
  final bool allowFallback;

  @override
  Future<StudentDashboardData?> loadDashboard() async {
    try {
      return await remote.loadDashboard();
    } catch (_) {
      if (!allowFallback) rethrow;
      return fallback.loadDashboard();
    }
  }
}

DashboardRepository buildDefaultDashboardRepository({ApiClient? apiClient}) {
  final client =
      apiClient ??
      ApiClient(
        config: AppConfig.current,
        tokenProvider: appAuthService.getAccessToken,
      );
  // The dashboard is derived from persisted tutor and practice data. Do not
  // mask a backend failure with a hard-coded learner profile.
  return BackendDashboardRepository(apiClient: client);
}

class ErrorDashboardRepository implements DashboardRepository {
  const ErrorDashboardRepository();

  @override
  Future<StudentDashboardData?> loadDashboard() async {
    throw StateError('Dashboard unavailable');
  }
}

List<DashboardActivity> _activityList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().map((item) {
    final topicId = _string(item['topic_id']);
    final tutorSessionId = _string(item['tutor_session_id']);
    return DashboardActivity(
      title: _string(item['title'], fallback: 'Learning activity'),
      subtitle: _topicLabel(topicId),
      timeLabel: _timeLabel(_string(item['created_at'])),
      topicId: topicId.isEmpty ? null : topicId,
      tutorSessionId: tutorSessionId.isEmpty ? null : tutorSessionId,
    );
  }).toList();
}

WeakTopic? _weakTopic(Object? value) {
  if (value is! Map<String, dynamic>) return null;
  final topicId = _string(value['topic_id']);
  final confidence = _string(value['confidence']);
  if (topicId.isEmpty && confidence == 'none') return null;
  return WeakTopic(
    title: topicId.isEmpty ? 'Needs more history' : _topicLabel(topicId),
    reason: _string(
      value['reason'],
      fallback: 'Not enough answer history yet.',
    ),
    actionLabel: 'Practice now',
    topicId: topicId.isEmpty ? null : topicId,
  );
}

List<PracticeRecommendation> _practiceRecommendations(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(
        (item) => PracticeRecommendation(
          topic: _topicLabel(item['topic_id']?.toString()),
          reason: _string(
            item['reason'],
            fallback: 'Practice this skill next.',
          ),
        ),
      )
      .toList();
}

String _topicLabel(String? value) {
  return switch ((value ?? '').trim()) {
    'linear-equations' => 'Linear Equations',
    'coordinate-plane' => 'Coordinate Plane',
    'slope' => 'Slope',
    'equation-of-a-line' => 'Equation of a Line',
    'functions' => 'Functions',
    'quadratic-functions' => 'Quadratic Functions',
    '' => 'Learning activity',
    final other =>
      other
          .split(RegExp(r'[-_]'))
          .where((part) => part.isNotEmpty)
          .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
          .join(' '),
  };
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const {};

List<String> _subjects(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map((item) => _string(item['subject_name']))
      .where((name) => name.isNotEmpty)
      .toList();
}

int? _gradeNumber(String gradeLabel) {
  final match = RegExp(r'\\d+').firstMatch(gradeLabel);
  return match == null ? null : int.tryParse(match.group(0)!);
}

String _timeLabel(String value) {
  if (value.isEmpty) return 'Recent';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return 'Recent';
  final diff = DateTime.now().difference(parsed);
  if (diff.inDays <= 0) return 'Today';
  if (diff.inDays == 1) return 'Yesterday';
  return '${diff.inDays} days ago';
}

String _string(Object? value, {String fallback = ''}) {
  return value is String && value.trim().isNotEmpty ? value : fallback;
}

String? _nullableString(Object? value) {
  final result = _string(value);
  return result.isEmpty ? null : result;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return 0;
}

int? _nullableInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return null;
}
