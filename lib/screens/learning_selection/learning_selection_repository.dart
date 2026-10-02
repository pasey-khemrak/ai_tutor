import '../../core/config/app_config.dart';

class LearningContext {
  const LearningContext({
    required this.grade,
    required this.subject,
    required this.topic,
    this.gradeLevelId,
    this.subjectId,
    this.topicId,
    this.lessonId,
    this.curriculumVersionId,
    this.teachingMomentId,
    this.languageMode = 'english',
    this.isCurriculumScoped = true,
  });

  /// A free-form Tutor entry deliberately has no curriculum identifiers.
  /// Display labels remain clear to the learner, while [isCurriculumScoped]
  /// prevents them from being sent to the backend as a false lesson match.
  const LearningContext.askQuestion({this.languageMode = 'english'})
    : grade = 0,
      subject = 'General',
      topic = 'Ask a question',
      gradeLevelId = null,
      subjectId = null,
      topicId = null,
      lessonId = null,
      curriculumVersionId = null,
      teachingMomentId = null,
      isCurriculumScoped = false;

  final int grade;
  final String subject;
  final String topic;

  /// Safe public curriculum identifiers. They travel with Tutor entry context,
  /// never with curriculum body or hidden instructional material.
  final String? gradeLevelId;
  final String? subjectId;
  final String? topicId;
  final String? lessonId;
  final String? curriculumVersionId;

  /// Safe identifier for an authored local teaching moment. It never carries
  /// lesson content or an answer payload.
  final String? teachingMomentId;

  /// `khmer`, `english`, or `bilingual` for the public Tutor contract.
  final String languageMode;

  /// False for free question and voice routes. In that case the
  /// backend classifies the learner request without false curriculum metadata.
  final bool isCurriculumScoped;

  String get gradeLabel => 'Grade $grade';
}

class LearningSubject {
  const LearningSubject({
    required this.name,
    this.topics = const [],
    this.topicsByGrade = const {},
  });

  final String name;

  /// Legacy/default topics for injected test data. Production MVP selection
  /// uses [topicsByGrade] so students never choose an unsupported lesson.
  final List<String> topics;
  final Map<int, List<String>> topicsByGrade;

  List<String> topicsForGrade(int grade) => topicsByGrade[grade] ?? topics;
}

class LearningSelectionData {
  const LearningSelectionData({required this.grades, required this.subjects});

  final List<int> grades;
  final List<LearningSubject> subjects;

  bool get isEmpty => grades.isEmpty || subjects.isEmpty;
}

abstract class LearningSelectionRepository {
  Future<LearningSelectionData> loadSelectionData();
}

class MockLearningSelectionRepository implements LearningSelectionRepository {
  const MockLearningSelectionRepository({
    this.delay = const Duration(milliseconds: 180),
    this.data = demoLearningSelectionData,
  });

  final Duration delay;
  final LearningSelectionData data;

  @override
  Future<LearningSelectionData> loadSelectionData() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return data;
  }
}

class EmptyLearningSelectionRepository implements LearningSelectionRepository {
  const EmptyLearningSelectionRepository();

  @override
  Future<LearningSelectionData> loadSelectionData() async =>
      const LearningSelectionData(grades: [], subjects: []);
}

LearningSelectionRepository buildDefaultLearningSelectionRepository() {
  // There is no production remote source for this legacy screen yet. Do not
  // silently show a Grade-10 Mathematics demo outside explicit local demo mode.
  return AppConfig.current.shouldUseDemoTutorData
      ? const MockLearningSelectionRepository()
      : const EmptyLearningSelectionRepository();
}

class ErrorLearningSelectionRepository implements LearningSelectionRepository {
  const ErrorLearningSelectionRepository();

  @override
  Future<LearningSelectionData> loadSelectionData() async {
    throw StateError('Learning selection unavailable');
  }
}

const demoLearningSelectionData = LearningSelectionData(
  grades: [8, 9, 10],
  subjects: [
    LearningSubject(
      name: 'Mathematics',
      topicsByGrade: {
        8: [
          'Integer, Fraction & Decimal Arithmetic',
          'Percentages',
          'Linear Equations',
        ],
        9: [
          'Linear Equations',
          'Slope from Two Points',
          'Straight-Line Graphs',
        ],
        10: ['Linear Equations', 'Basic Quadratic Graphs'],
      },
    ),
  ],
);
