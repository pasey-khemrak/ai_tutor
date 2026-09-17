import '../../core/auth/auth_service.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import 'local_mvp_limits_scope.dart';

const localMvpUnsupportedRecoveryMessage =
    'មេរៀនដែលអ្នកស្នើមិនទាន់គាំទ្រសម្រាប់សាកល្បងនេះទេ។ '
    'This tutor currently supports Grade 12 Mathematics, Physics, and Chemistry.';

class StudentLesson {
  const StudentLesson({
    required this.lessonId,
    required this.curriculumVersionId,
    required this.gradeLevelId,
    required this.grade,
    required this.subjectId,
    required this.subject,
    required this.topicId,
    required this.topic,
    required this.title,
    this.englishTitle,
    this.description,
    required this.difficulty,
    this.teachingMomentId,
    this.languageMode = 'english',
    this.waitingForStudentInput = false,
    this.answerRevealed = false,
    this.practiceAvailable = true,
  });
  final String lessonId;
  final String curriculumVersionId;
  final String gradeLevelId;
  final int grade;
  final String subjectId;
  final String subject;
  final String topicId;
  final String topic;

  /// The source-language lesson title. It remains Khmer-only unless the
  /// selected lesson language mode is bilingual.
  final String title;
  final String? englishTitle;
  final String? description;
  final String difficulty;

  /// Present only for a locally authored demo lesson. This is not a backend
  /// curriculum publication flag or an answer payload.
  final String? teachingMomentId;

  /// Student-facing language preference for this lesson's public Tutor turn.
  /// The backend remains responsible for terminology and output validation.
  final String languageMode;
  final bool waitingForStudentInput;
  final bool answerRevealed;

  /// Local demo lessons may intentionally defer practice until reviewed
  /// questions have been authored. Do not navigate to an unavailable quiz.
  final bool practiceAvailable;

  bool get isLocalCurriculumDemo => isLocalMvpLimitsScope(
    grade: grade,
    subject: subject,
    topic: topic,
    lessonId: lessonId,
    curriculumVersionId: curriculumVersionId,
    teachingMomentId: teachingMomentId,
  );

  String get displayTitle => languageMode == 'bilingual' && englishTitle != null
      ? '$title — $englishTitle'
      : title;

  /// Do not add an unreviewed English lesson name under a Khmer-only title.
  /// Topic remains available for the typed Tutor request.
  String? get displayDescription =>
      description ?? (languageMode == 'khmer' ? null : topic);
}

abstract class StudentLessonsRepository {
  Future<List<StudentLesson>> loadLessons({
    String? search,
    String? subjectId,
    String? topicId,
  });
}

/// A deliberately small, offline catalogue used only by the development demo.
/// Production and staging continue to read published lessons from the backend.
class LocalDemoStudentLessonsRepository implements StudentLessonsRepository {
  const LocalDemoStudentLessonsRepository();

  @override
  Future<List<StudentLesson>> loadLessons({
    String? search,
    String? subjectId,
    String? topicId,
  }) async {
    final query = search?.trim().toLowerCase() ?? '';
    return demoStudentLessons
        .where(
          (lesson) =>
              (subjectId == null || lesson.subjectId == subjectId) &&
              (topicId == null || lesson.topicId == topicId) &&
              (query.isEmpty ||
                  lesson.title.toLowerCase().contains(query) ||
                  (lesson.englishTitle?.toLowerCase().contains(query) ??
                      false) ||
                  lesson.topic.toLowerCase().contains(query) ||
                  (lesson.description?.toLowerCase().contains(query) ?? false)),
        )
        .toList(growable: false);
  }
}

/// The local MVP exposes exactly one source-linked Limits teaching moment. It
/// is not a published curriculum catalogue and must not advertise other
/// grades, subjects, or lessons.
const List<StudentLesson> demoStudentLessons = [
  StudentLesson(
    lessonId: localMvpLessonId,
    curriculumVersionId: localMvpCurriculumVersionId,
    gradeLevelId: 'grade-12',
    grade: localMvpGrade,
    subjectId: localMvpSubjectId,
    subject: localMvpSubject,
    topicId: localMvpTopicId,
    topic: localMvpTopic,
    title: 'លីមីតនៃអនុគមន៍',
    englishTitle: 'Limits of Functions',
    difficulty: 'beginner',
    teachingMomentId: localMvpTeachingMomentId,
    languageMode: 'khmer',
    waitingForStudentInput: true,
    answerRevealed: false,
    practiceAvailable: false,
  ),
];

StudentLessonsRepository buildDefaultStudentLessonsRepository() =>
    AppConfig.current.shouldUseDemoTutorData
    ? const LocalDemoStudentLessonsRepository()
    : BackendStudentLessonsRepository();

class BackendStudentLessonsRepository implements StudentLessonsRepository {
  BackendStudentLessonsRepository({ApiClient? apiClient})
    : _client =
          apiClient ??
          ApiClient(
            config: AppConfig.current,
            tokenProvider: appAuthService.getAccessToken,
          );
  final ApiClient _client;
  @override
  Future<List<StudentLesson>> loadLessons({
    String? search,
    String? subjectId,
    String? topicId,
  }) async {
    final response = await _client.get(
      '/catalog/published-lessons',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (subjectId != null && subjectId.isNotEmpty) 'subject_id': subjectId,
        if (topicId != null && topicId.isNotEmpty) 'topic_id': topicId,
      },
    );
    final data = response['data'];
    final object = data is Map<String, dynamic> ? data : response;
    final rows = object['lessons'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => StudentLesson(
            lessonId: _text(row['lesson_id']),
            curriculumVersionId: _text(row['curriculum_version_id']),
            gradeLevelId: _text(row['grade_level_id']),
            grade: _number(row['grade_number']),
            subjectId: _text(row['subject_id']),
            subject: _text(row['subject_name'], 'Subject'),
            topicId: _text(row['topic_id']),
            topic: _text(row['topic_name'], 'Topic'),
            title: _text(row['title'], 'Lesson'),
            description: _nullable(row['description']),
            difficulty: _text(row['difficulty'], 'beginner'),
            teachingMomentId: _nullable(row['teaching_moment_id']),
            languageMode: _languageMode(row['language_mode']),
          ),
        )
        .where(
          (lesson) =>
              lesson.lessonId.isNotEmpty &&
              lesson.curriculumVersionId.isNotEmpty &&
              lesson.grade >= 10 &&
              lesson.grade <= 12,
        )
        .toList();
  }
}

String _text(Object? value, [String fallback = '']) =>
    value is String && value.trim().isNotEmpty ? value.trim() : fallback;
String? _nullable(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;
int _number(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

String _languageMode(Object? value) {
  final normalized = _text(value).toLowerCase();
  return switch (normalized) {
    'khmer' || 'english' || 'bilingual' => normalized,
    _ => 'english',
  };
}
