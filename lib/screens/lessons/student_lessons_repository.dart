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
    this.khmerDescription,
    this.starterProblem,
    required this.difficulty,
    this.teachingMomentId,
    this.languageMode = 'english',
    this.waitingForStudentInput = false,
    this.answerRevealed = false,
    this.practiceAvailable = true,
    this.isAvailable = true,
    this.tags = const [],
    this.problemCount = 4,
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
  final String? khmerDescription;
  final String? starterProblem;
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

  /// Indicates whether the visual whiteboard tutor has an authoritative solver
  /// ready to teach this lesson today. Topics still in development are false.
  final bool isAvailable;

  /// Curriculum keyword tags for dynamic discovery and filtering.
  final List<String> tags;

  /// Total practice or worked problems available for this topic.
  final int problemCount;

  bool get isLocalCurriculumDemo => isLocalMvpLimitsScope(
    grade: grade,
    subject: subject,
    topic: topic,
    lessonId: lessonId,
    curriculumVersionId: curriculumVersionId,
    teachingMomentId: teachingMomentId,
  );

  String get displayTitle {
    if (englishTitle == null || englishTitle!.isEmpty) return title;
    if (languageMode == 'khmer') return title;
    if (languageMode == 'english') return englishTitle!;
    return '$title — $englishTitle';
  }

  /// Returns Khmer description in Khmer mode, English in English/bilingual mode.
  String? get displayDescription {
    if (languageMode == 'khmer' && khmerDescription != null) {
      return khmerDescription;
    }
    return description ?? khmerDescription ?? (languageMode == 'khmer' ? null : topic);
  }

  StudentLesson copyWith({
    String? lessonId,
    String? curriculumVersionId,
    String? gradeLevelId,
    int? grade,
    String? subjectId,
    String? subject,
    String? topicId,
    String? topic,
    String? title,
    String? englishTitle,
    String? description,
    String? khmerDescription,
    String? starterProblem,
    String? difficulty,
    String? teachingMomentId,
    String? languageMode,
    bool? waitingForStudentInput,
    bool? answerRevealed,
    bool? practiceAvailable,
    bool? isAvailable,
    List<String>? tags,
    int? problemCount,
  }) {
    return StudentLesson(
      lessonId: lessonId ?? this.lessonId,
      curriculumVersionId: curriculumVersionId ?? this.curriculumVersionId,
      gradeLevelId: gradeLevelId ?? this.gradeLevelId,
      grade: grade ?? this.grade,
      subjectId: subjectId ?? this.subjectId,
      subject: subject ?? this.subject,
      topicId: topicId ?? this.topicId,
      topic: topic ?? this.topic,
      title: title ?? this.title,
      englishTitle: englishTitle ?? this.englishTitle,
      description: description ?? this.description,
      khmerDescription: khmerDescription ?? this.khmerDescription,
      starterProblem: starterProblem ?? this.starterProblem,
      difficulty: difficulty ?? this.difficulty,
      teachingMomentId: teachingMomentId ?? this.teachingMomentId,
      languageMode: languageMode ?? this.languageMode,
      waitingForStudentInput:
          waitingForStudentInput ?? this.waitingForStudentInput,
      answerRevealed: answerRevealed ?? this.answerRevealed,
      practiceAvailable: practiceAvailable ?? this.practiceAvailable,
      isAvailable: isAvailable ?? this.isAvailable,
      tags: tags ?? this.tags,
      problemCount: problemCount ?? this.problemCount,
    );
  }
}

class LessonConceptItem {
  const LessonConceptItem({
    required this.title,
    required this.summary,
    required this.body,
  });

  final String title;
  final String summary;
  final String body;

  factory LessonConceptItem.fromJson(Map<String, dynamic> json) {
    return LessonConceptItem(
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
    );
  }
}

class LessonFormulaItem {
  const LessonFormulaItem({
    required this.name,
    required this.expression,
    this.explanation,
    this.variables = const {},
  });

  final String name;
  final String expression;
  final String? explanation;
  final Map<String, String> variables;

  factory LessonFormulaItem.fromJson(Map<String, dynamic> json) {
    Map<String, String> vars = {};
    if (json['variables'] is Map) {
      vars = (json['variables'] as Map).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    }
    return LessonFormulaItem(
      name: json['name']?.toString() ?? json['title']?.toString() ?? 'Formula',
      expression: json['expression']?.toString() ?? json['latex']?.toString() ?? '',
      explanation: json['explanation']?.toString() ??
          json['conditions']?.toString() ??
          json['summary']?.toString(),
      variables: vars,
    );
  }
}

class LessonExampleItem {
  const LessonExampleItem({
    required this.problem,
    required this.solution,
    this.steps = const [],
  });

  final String problem;
  final String solution;
  final List<String> steps;

  factory LessonExampleItem.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'] ?? json['solution_steps'];
    final steps = (rawSteps is List)
        ? rawSteps.map((s) => s.toString()).toList()
        : <String>[];
    return LessonExampleItem(
      problem: json['problem']?.toString() ?? json['summary']?.toString() ?? '',
      solution: json['solution']?.toString() ??
          json['answer']?.toString() ??
          json['expression']?.toString() ??
          '',
      steps: steps,
    );
  }
}

class LessonDetailedContent {
  const LessonDetailedContent({
    required this.lessonId,
    required this.title,
    required this.topicId,
    required this.topicName,
    this.topicKhmerName,
    required this.subjectId,
    required this.subjectName,
    required this.gradeNumber,
    required this.gradeName,
    this.learningObjectives = const [],
    this.concepts = const [],
    this.formulas = const [],
    this.examples = const [],
    this.commonMisconceptions = const [],
    this.khmerTerms = const {},
    this.prerequisites = const [],
    this.starterProblem,
  });

  final String lessonId;
  final String title;
  final String topicId;
  final String topicName;
  final String? topicKhmerName;
  final String subjectId;
  final String subjectName;
  final int gradeNumber;
  final String gradeName;
  final List<String> learningObjectives;
  final List<LessonConceptItem> concepts;
  final List<LessonFormulaItem> formulas;
  final List<LessonExampleItem> examples;
  final List<String> commonMisconceptions;
  final Map<String, String> khmerTerms;
  final List<String> prerequisites;
  final String? starterProblem;

  factory LessonDetailedContent.fromJson(Map<String, dynamic> json) {
    final rawConcepts = json['concepts'];
    final concepts = (rawConcepts is List)
        ? rawConcepts
            .whereType<Map<String, dynamic>>()
            .map(LessonConceptItem.fromJson)
            .toList()
        : <LessonConceptItem>[];

    final rawFormulas = json['formulas'];
    final formulas = (rawFormulas is List)
        ? rawFormulas
            .whereType<Map<String, dynamic>>()
            .map(LessonFormulaItem.fromJson)
            .toList()
        : <LessonFormulaItem>[];

    final rawExamples = json['examples'];
    final examples = (rawExamples is List)
        ? rawExamples
            .whereType<Map<String, dynamic>>()
            .map(LessonExampleItem.fromJson)
            .toList()
        : <LessonExampleItem>[];

    final rawMisconceptions = json['common_misconceptions'];
    final commonMisconceptions = (rawMisconceptions is List)
        ? rawMisconceptions.map((m) => m.toString()).toList()
        : <String>[];

    Map<String, String> khmerTerms = {};
    if (json['khmer_terms'] is Map) {
      khmerTerms = (json['khmer_terms'] as Map).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    }

    final rawObjectives = json['learning_objectives'];
    final learningObjectives = (rawObjectives is List)
        ? rawObjectives.map((o) => o.toString()).toList()
        : <String>[];

    final rawPrereqs = json['prerequisites'];
    final prerequisites = (rawPrereqs is List)
        ? rawPrereqs.map((p) => p.toString()).toList()
        : <String>[];

    return LessonDetailedContent(
      lessonId: json['lesson_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      topicId: json['topic_id']?.toString() ?? '',
      topicName: json['topic_name']?.toString() ?? 'Topic',
      topicKhmerName: json['topic_khmer_name']?.toString(),
      subjectId: json['subject_id']?.toString() ?? 'math',
      subjectName: json['subject_name']?.toString() ?? 'Subject',
      gradeNumber: json['grade_number'] is num ? (json['grade_number'] as num).toInt() : 12,
      gradeName: json['grade_name']?.toString() ?? 'Grade 12',
      learningObjectives: learningObjectives,
      concepts: concepts,
      formulas: formulas,
      examples: examples,
      commonMisconceptions: commonMisconceptions,
      khmerTerms: khmerTerms,
      prerequisites: prerequisites,
      starterProblem: json['starter_problem']?.toString(),
    );
  }
}

abstract class StudentLessonsRepository {
  Future<List<StudentLesson>> loadLessons({
    String? search,
    String? subjectId,
    String? topicId,
    int? grade,
  });

  Future<LessonDetailedContent> loadLessonContent(String lessonId) async {
    return fallbackLessonDetailedContent(lessonId);
  }
}

/// A deliberately small, offline catalogue used only by the development demo.
/// Production and staging continue to read published lessons from the backend.
class LocalDemoStudentLessonsRepository implements StudentLessonsRepository {
  const LocalDemoStudentLessonsRepository();

  @override
  Future<LessonDetailedContent> loadLessonContent(String lessonId) async {
    return fallbackLessonDetailedContent(lessonId);
  }

  @override
  Future<List<StudentLesson>> loadLessons({
    String? search,
    String? subjectId,
    String? topicId,
    int? grade,
  }) async {
    final query = search?.trim().toLowerCase() ?? '';
    return demoStudentLessons
        .where(
          (lesson) =>
              (grade == null || lesson.grade == grade) &&
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
    int? grade,
  }) async {
    Map<String, dynamic>? response;
    try {
      response = await _client.get(
        '/curriculum/catalog',
        queryParameters: {
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (subjectId != null && subjectId.isNotEmpty) 'subject_id': subjectId,
          if (topicId != null && topicId.isNotEmpty) 'topic_id': topicId,
          if (grade != null) 'grade': grade.toString(),
        },
      );
    } catch (_) {
      try {
        response = await _client.get(
          '/catalog/published-lessons',
          queryParameters: {
            if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
            if (subjectId != null && subjectId.isNotEmpty) 'subject_id': subjectId,
            if (topicId != null && topicId.isNotEmpty) 'topic_id': topicId,
          },
        );
      } catch (_) {
        response = null;
      }
    }
    final data = response?['data'];
    final object = data is Map<String, dynamic> ? data : (response ?? const <String, dynamic>{});
    final rows = object['topics'] ?? object['lessons'];
    final parsed = (rows is List)
        ? rows
            .whereType<Map<String, dynamic>>()
            .map(
              (row) => StudentLesson(
                lessonId: _text(row['lesson_id']),
                curriculumVersionId: _text(row['curriculum_version_id']),
                gradeLevelId: _text(row['grade_level_id']),
                grade: _number(row['grade'] ?? row['grade_number']),
                subjectId: _text(row['subject_id']),
                subject: _text(row['subject_name'], 'Subject'),
                topicId: _text(row['topic_id']),
                topic: _text(row['topic_name'], 'Topic'),
                title: _text(row['title'], 'Lesson'),
                englishTitle: _nullable(row['english_title']) ?? _nullable(row['topic_name']),
                description: _nullable(row['description']),
                khmerDescription: _nullable(row['khmer_description']) ?? _nullable(row['topic_khmer_name']),
                starterProblem: _nullable(row['starter_problem']),
                difficulty: _text(row['difficulty'], 'beginner'),
                teachingMomentId: _nullable(row['teaching_moment_id']),
                languageMode: _languageMode(row['language_mode']),
                isAvailable: row['is_available'] == null ? true : (row['is_available'] == true),
                tags: (row['tags'] is List)
                    ? (row['tags'] as List).map((t) => '$t').toList()
                    : const [],
                problemCount: _number(row['problem_count'] ?? 4),
              ),
            )
            .where(
              (lesson) =>
                  lesson.lessonId.isNotEmpty &&
                  lesson.curriculumVersionId.isNotEmpty &&
                  lesson.grade >= 10 &&
                  lesson.grade <= 12 &&
                  (grade == null || lesson.grade == grade),
            )
            .toList()
        : const <StudentLesson>[];

    if (parsed.isNotEmpty) return parsed;

    // When the backend catalog is unseeded, ensure students still have
    // Grade 10-12 STEM lessons ready to learn rather than meeting a dead-end.
    final query = search?.trim().toLowerCase() ?? '';
    final fallbackList = switch (grade) {
      10 => publishedGrade10StemFallbackLessons,
      11 => publishedGrade11StemFallbackLessons,
      12 => publishedGrade12StemFallbackLessons,
      _ => publishedGrade12StemFallbackLessons,
    };
    return fallbackList
        .where(
          (lesson) =>
              (grade == null || lesson.grade == grade) &&
              (subjectId == null || lesson.subjectId == subjectId) &&
              (topicId == null || lesson.topicId == topicId) &&
              (query.isEmpty ||
                  lesson.title.toLowerCase().contains(query) ||
                  (lesson.englishTitle?.toLowerCase().contains(query) ??
                      false) ||
                  lesson.topic.toLowerCase().contains(query) ||
                  (lesson.description?.toLowerCase().contains(query) ?? false) ||
                  (lesson.khmerDescription?.toLowerCase().contains(query) ?? false) ||
                  lesson.tags.any((tag) => tag.toLowerCase().contains(query))),
        )
        .toList(growable: false);
  }

  @override
  Future<LessonDetailedContent> loadLessonContent(String lessonId) async {
    try {
      final response = await _client.get('/catalog/lessons/$lessonId/content');
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return LessonDetailedContent.fromJson(data);
      }
    } catch (_) {
      try {
        final response =
            await _client.get('/catalog/published-lessons/$lessonId/content');
        final data = response['data'];
        if (data is Map<String, dynamic>) {
          return LessonDetailedContent.fromJson(data);
        }
      } catch (_) {}
    }
    return fallbackLessonDetailedContent(lessonId);
  }
}

LessonDetailedContent fallbackLessonDetailedContent(String lessonId) {
  final lower = lessonId.toLowerCase();

  if (lower.contains('kinematic')) {
    return const LessonDetailedContent(
      lessonId: 'physics.g12.lesson1.kinematics',
      title: 'ស៊ីនេម៉ាទិច (Kinematics & 1D/2D Motion)',
      topicId: 'kinematics-g12',
      topicName: 'Kinematics & Motion',
      topicKhmerName: 'ស៊ីនេម៉ាទិច និងចលនា',
      subjectId: 'physics',
      subjectName: 'Physics',
      gradeNumber: 12,
      gradeName: 'Grade 12',
      learningObjectives: [
        'Apply kinematic equations to uniformly accelerated rectilinear motion',
        'Analyze velocity-time graphs to determine displacement and acceleration',
        'Solve projectile motion by separating horizontal and vertical components',
      ],
      concepts: [
        LessonConceptItem(
          title: 'Uniformly Accelerated Rectilinear Motion (ចលនាត្រង់ប្រែប្រួលស្មើ)',
          summary: 'Motion along a straight line with constant acceleration a.',
          body:
              'When acceleration is constant, velocity changes at a steady rate over time. Displacement, velocity, acceleration, and time are related through fundamental kinematic equations.',
        ),
        LessonConceptItem(
          title: 'Projectile Motion (ចលនាគ្រាប់បាញ់)',
          summary: 'Two-dimensional motion under the influence of gravity alone.',
          body:
              'Horizontal motion has constant velocity (a_x = 0), while vertical motion has constant downward gravitational acceleration (a_y = -g). Both dimensions share time t.',
        ),
      ],
      formulas: [
        LessonFormulaItem(
          name: 'Velocity-Time Relation',
          expression: r'v = v_0 + at',
          explanation: 'Final velocity equals initial velocity plus acceleration multiplied by time.',
        ),
        LessonFormulaItem(
          name: 'Displacement-Time Relation',
          expression: r'x = x_0 + v_0 t + \frac{1}{2}at^2',
          explanation: 'Displacement under constant acceleration.',
        ),
        LessonFormulaItem(
          name: 'Torricelli Equation (Time-Independent)',
          expression: r'v^2 - v_0^2 = 2a(x - x_0)',
          explanation: 'Relates velocities, acceleration, and displacement without time.',
        ),
      ],
      examples: [
        LessonExampleItem(
          problem: 'A car starts from rest (v_0 = 0) with acceleration a = 2 m/s^2. Find its velocity and displacement after t = 5 s.',
          solution: r'v = 10 \text{ m/s}, \quad x = 25 \text{ m}',
          steps: [
            'Identify given variables: v_0 = 0 m/s, a = 2 m/s^2, t = 5 s.',
            'Use velocity equation: v = v_0 + at = 0 + (2)(5) = 10 m/s.',
            'Use displacement equation: x = v_0 t + (1/2) a t^2 = 0 + 0.5(2)(5^2) = 25 m.',
          ],
        ),
      ],
      commonMisconceptions: [
        'Confusing velocity with acceleration (an object can have zero velocity but non-zero acceleration at peak height).',
        'Applying constant acceleration formulas when acceleration is varying.',
      ],
      khmerTerms: {
        'kinematics': 'ស៊ីនេម៉ាទិច',
        'velocity': 'ល្បឿន',
        'acceleration': 'សំទុះ',
        'displacement': 'បម្លាស់ទី',
        'projectile': 'គ្រាប់បាញ់',
      },
      prerequisites: ['Vectors and trigonometry', 'Basic algebraic manipulation'],
      starterProblem: 'v = u + at, u=0, a=2, t=5',
    );
  }

  if (lower.contains('stoichio') || lower.contains('reaction') || lower.contains('chemical')) {
    return const LessonDetailedContent(
      lessonId: 'chemistry.g12.lesson1.stoichiometry',
      title: 'ស្តូគ្យូម៉េទ្រី និងសមីការគីមី (Stoichiometry & Reaction Balance)',
      topicId: 'stoichiometry-g12',
      topicName: 'Stoichiometry & Reaction Balance',
      topicKhmerName: 'ស្តូគ្យូម៉េទ្រី និងសមីការគីមី',
      subjectId: 'chemistry',
      subjectName: 'Chemistry',
      gradeNumber: 12,
      gradeName: 'Grade 12',
      learningObjectives: [
        'Balance chemical equations obeying the Law of Conservation of Mass',
        'Convert between mass, moles, and number of particles using molar mass',
        'Determine limiting reactant and theoretical yield in a chemical reaction',
      ],
      concepts: [
        LessonConceptItem(
          title: 'Law of Conservation of Mass (ច្បាប់រក្សាម៉ាស)',
          summary: 'Atoms are neither created nor destroyed in a chemical reaction.',
          body:
              'A chemical equation must have the same number of atoms of each element on both sides of the reaction arrow. Coefficients indicate stoichiometric molar ratios.',
        ),
        LessonConceptItem(
          title: 'Mole Concept & Molar Conversions (គំនិតម៉ូល)',
          summary: 'Relating macroscopic measurable mass (grams) to microscopic particle quantities (moles).',
          body:
              'One mole contains 6.022 * 10^23 particles. The molar mass M (g/mol) converts between mass and moles via n = m / M.',
        ),
      ],
      formulas: [
        LessonFormulaItem(
          name: 'Mole from Mass',
          expression: r'n = \frac{m}{M}',
          explanation: 'n is amount in moles, m is mass in grams, M is molar mass in g/mol.',
        ),
        LessonFormulaItem(
          name: 'Molar Concentration',
          expression: r'C = \frac{n}{V}',
          explanation: 'C is molar concentration in mol/L, V is solution volume in liters.',
        ),
        LessonFormulaItem(
          name: 'Stoichiometric Ratio',
          expression: r'\frac{n_A}{a} = \frac{n_B}{b}',
          explanation: 'For reaction aA + bB -> products, reactants are consumed in ratio a:b.',
        ),
      ],
      examples: [
        LessonExampleItem(
          problem: 'Balance the reaction: H_2 + O_2 -> H_2O, and find how many moles of H_2O are produced from 4 moles of H_2.',
          solution: r'2H_2 + O_2 \to 2H_2O; \quad 4 \text{ mol } H_2O',
          steps: [
            'Count atoms: Left has 2 H and 2 O; Right has 2 H and 1 O.',
            'Multiply H_2O by 2 to balance O: H_2 + O_2 -> 2H_2O.',
            'Now right has 4 H; multiply H_2 by 2: 2H_2 + O_2 -> 2H_2O.',
            'By stoichiometric ratio 2:2 (1:1), 4 mol H_2 yields 4 mol H_2O.',
          ],
        ),
      ],
      commonMisconceptions: [
        'Altering chemical subscripts instead of coefficients when balancing equations.',
        'Assuming mass ratios equal mole ratios directly without using molar masses.',
      ],
      khmerTerms: {
        'stoichiometry': 'ស្តូគ្យូម៉េទ្រី',
        'chemical equation': 'សមីការគីមី',
        'mole': 'ម៉ូល',
        'molar mass': 'ម៉ាសម៉ូល',
        'limiting reactant': 'អង្គធាតុកំណត់',
      },
      prerequisites: ['Periodic table and atomic masses', 'Chemical symbols and formulas'],
      starterProblem: r'2H_2 + O_2 \to 2H_2O',
    );
  }

  if (lower.contains('complex')) {
    return const LessonDetailedContent(
      lessonId: 'math.g12.lesson4.complex-numbers',
      title: 'ចំនួនកុំផ្លិច (Complex Numbers)',
      topicId: 'complex-numbers-g12',
      topicName: 'Complex Numbers',
      topicKhmerName: 'ចំនួនកុំផ្លិច',
      subjectId: 'math',
      subjectName: 'Mathematics',
      gradeNumber: 12,
      gradeName: 'Grade 12',
      learningObjectives: [
        'Write complex numbers in algebraic (a + bi), trigonometric, and exponential forms',
        'Compute modulus |z| and argument arg(z)',
        'Apply De Moivre’s theorem to compute powers and roots of complex numbers',
      ],
      concepts: [
        LessonConceptItem(
          title: 'Algebraic Form & Modulus (ទម្រង់ពីជគណិត និងម៉ូឌុល)',
          summary: 'z = a + bi where a, b in R and i^2 = -1.',
          body:
              'The real part is Re(z) = a and imaginary part is Im(z) = b. The modulus is |z| = sqrt(a^2 + b^2).',
        ),
        LessonConceptItem(
          title: 'Trigonometric & Exponential Form (ទម្រង់ត្រីកោណមាត្រ)',
          summary: 'z = r(cos theta + i sin theta) = r e^(i theta).',
          body:
              'r = |z| is modulus and theta = arg(z) is argument satisfying cos theta = a/r and sin theta = b/r.',
        ),
      ],
      formulas: [
        LessonFormulaItem(
          name: 'Modulus',
          expression: r'|z| = \sqrt{a^2 + b^2}',
          explanation: 'Magnitude of complex number z = a + bi.',
        ),
        LessonFormulaItem(
          name: 'Argument',
          expression: r'\tan \theta = \frac{b}{a} \quad (a \neq 0)',
          explanation: 'Angle theta in the complex plane, adjusted for quadrant.',
        ),
        LessonFormulaItem(
          name: "De Moivre's Theorem",
          expression: r'[r(\cos\theta + i\sin\theta)]^n = r^n(\cos n\theta + i\sin n\theta)',
          explanation: 'Computes integer powers of complex numbers in polar form.',
        ),
      ],
      examples: [
        LessonExampleItem(
          problem: r'For z = 1 + i\sqrt{3}, find |z|, \arg(z), and z^6.',
          solution: r'|z| = 2, \quad \arg(z) = \frac{\pi}{3}, \quad z^6 = 64',
          steps: [
            r'Modulus: |z| = \sqrt{1^2 + (\sqrt{3})^2} = \sqrt{1 + 3} = 2.',
            r'Argument: \cos\theta = 1/2, \sin\theta = \sqrt{3}/2 \implies \theta = \pi/3.',
            r'Trigonometric form: z = 2(\cos(\pi/3) + i\sin(\pi/3)).',
            r'De Moivre power: z^6 = 2^6(\cos(6 \cdot \pi/3) + i\sin(6 \cdot \pi/3)) = 64(\cos 2\pi + i\sin 2\pi) = 64(1 + 0) = 64.',
          ],
        ),
      ],
      commonMisconceptions: [
        r'Applying \sqrt{a}\sqrt{b} = \sqrt{ab} when both a and b are negative.',
        'Forgetting to adjust argument theta based on the quadrant of (a, b).',
      ],
      khmerTerms: {
        'complex number': 'ចំនួនកុំផ្លិច',
        'modulus': 'ម៉ូឌុល',
        'argument': 'អាគុយម៉ង់',
        'real part': 'ផ្នែកពិត',
        'imaginary part': 'ផ្នែកនិម្មិត',
      },
      prerequisites: ['Trigonometric circle and angles', 'Quadratic formula with negative discriminant'],
      starterProblem: r'z = 1 + i\sqrt{3}',
    );
  }

  // Default to Limits of Functions (MoEYS Grade 12 core)
  return const LessonDetailedContent(
    lessonId: 'math.g12.lesson1.limits-of-functions',
    title: 'លីមីតនៃអនុគមន៍ (Limits of Functions)',
    topicId: 'limits-of-functions-g12',
    topicName: 'Limits of Functions',
    topicKhmerName: 'លីមីតនៃអនុគមន៍',
    subjectId: 'math',
    subjectName: 'Mathematics',
    gradeNumber: 12,
    gradeName: 'Grade 12',
    learningObjectives: [
      'Evaluate finite limits at a point by direct substitution',
      'Recognize and resolve 0/0 indeterminate forms by factoring or multiplying by conjugate',
      'Calculate limits at infinity and identify vertical/horizontal asymptotes',
    ],
    concepts: [
      LessonConceptItem(
        title: 'Finite Limit & Direct Substitution (លីមីតកំណត់ត្រង់មួយចំណុច)',
        summary: 'Evaluating lim_{x -> a} f(x) by direct substitution when f is continuous at a.',
        body:
            'If a function f(x) is continuous at x = a, the limit as x approaches a is simply f(a). If direct substitution yields a real number L, then lim_{x -> a} f(x) = L.',
      ),
      LessonConceptItem(
        title: 'Indeterminate Form 0/0 (រាងមិនកំណត់ 0/0)',
        summary: 'When direct substitution yields 0/0, simplify using factorization or conjugate expressions.',
        body:
            'When f(a) / g(a) = 0/0, both numerator and denominator contain (x - a) as a factor. Factor both polynomials, simplify the common term (x - a) for x != a, and evaluate the limit of the simplified expression.',
      ),
      LessonConceptItem(
        title: 'Infinite Limits & Asymptotes (លីមីតអនន្ត និងអាស៊ីមតូត)',
        summary: 'Connecting infinite limits to vertical asymptotes and limits at infinity to horizontal asymptotes.',
        body:
            'If lim_{x -> a} f(x) = +-infinity, the line x = a is a vertical asymptote. If lim_{x -> +-infinity} f(x) = L, the line y = L is a horizontal asymptote.',
      ),
    ],
    formulas: [
      LessonFormulaItem(
        name: 'Two-Sided Limit Existence',
        expression: r'\lim_{x \to a} f(x) = L \iff \lim_{x \to a^-} f(x) = \lim_{x \to a^+} f(x) = L',
        explanation: 'Limit exists if and only if both left-hand and right-hand limits are equal.',
      ),
      LessonFormulaItem(
        name: 'Indeterminate Form 0/0 Resolution',
        expression: r'\lim_{x \to a} \frac{P(x)}{Q(x)} = \lim_{x \to a} \frac{(x - a)P_1(x)}{(x - a)Q_1(x)} = \lim_{x \to a} \frac{P_1(x)}{Q_1(x)}',
        explanation: 'Factor out (x - a) and simplify before substituting.',
      ),
      LessonFormulaItem(
        name: 'Reciprocal Power Limits',
        expression: r'\lim_{x \to \pm\infty} \frac{c}{x^n} = 0 \quad (n > 0)',
        explanation: 'As x approaches infinity, any constant divided by a positive power of x approaches zero.',
      ),
    ],
    examples: [
      LessonExampleItem(
        problem: r'\lim_{x \to 3} \frac{x^2 - 9}{x - 3}',
        solution: '6',
        steps: [
          'Direct substitution: (3^2 - 9)/(3 - 3) = 0/0 (indeterminate form).',
          'Factor numerator using difference of two squares: x^2 - 9 = (x - 3)(x + 3).',
          'Cancel common factor (x - 3) for x != 3: (x - 3)(x + 3)/(x - 3) = x + 3.',
          'Substitute x = 3 into simplified expression: 3 + 3 = 6.',
        ],
      ),
      LessonExampleItem(
        problem: r'\lim_{x \to +\infty} \frac{2x^2 + 5}{3x^2 - 2x + 1}',
        solution: r'\frac{2}{3}',
        steps: [
          'Factor out dominant term x^2 from numerator and denominator.',
          'Numerator: x^2(2 + 5/x^2), Denominator: x^2(3 - 2/x + 1/x^2).',
          'Cancel x^2 and apply reciprocal limit laws as x -> infinity.',
          'Result: (2 + 0)/(3 - 0 + 0) = 2/3. Horizontal asymptote y = 2/3.',
        ],
      ),
    ],
    commonMisconceptions: [
      'Assuming 0/0 equals 1 or 0 (it is indeterminate and requires algebraic transformation).',
      'Canceling (x - a) without noting that the limit evaluates the behavior near a, not at a.',
    ],
    khmerTerms: {
      'limit': 'លីមីត',
      'indeterminate form': 'រាងមិនកំណត់',
      'vertical asymptote': 'អាស៊ីមតូតឈរ',
      'horizontal asymptote': 'អាស៊ីមតូតដេក',
      'continuity': 'ភាពជាប់នៃអនុគមន៍',
    },
    prerequisites: ['Factoring polynomials and difference of squares', 'Domain of rational functions'],
    starterProblem: r'\lim_{x \to 3} \frac{x^2 - 9}{x - 3}',
  );
}

/// Fallback published curriculum catalog for Grade 12 STEM. Ensures students
/// always have vetted lessons in Mathematics, Physics, and Chemistry.
const List<StudentLesson> publishedGrade12StemFallbackLessons = [
  // ── Mathematics (Grade 12) ────────────────────────────────────────────────
  StudentLesson(
    lessonId: 'math.g12.lesson1.limits-of-functions',
    curriculumVersionId: 'g12-stem-math-v1',
    gradeLevelId: 'grade-12',
    grade: 12,
    subjectId: 'math',
    subject: 'Mathematics',
    topicId: 'math-g12-limits-of-functions',
    topic: 'Limits of Functions',
    title: 'លីមីតនៃអនុគមន៍',
    englishTitle: 'Limits of Functions',
    description: 'Calculate finite limits, indeterminate forms 0/0, and rational function limits.',
    khmerDescription: 'គណនាលីមីតកំណត់ រាងមិនកំណត់ 0/0 និងលីមីតនៃអនុគមន៍សនិទាន។',
    starterProblem: r'\lim_{x \to 3} \frac{x^2 - 9}{x - 3}',
    difficulty: 'beginner',
    languageMode: 'bilingual',
    isAvailable: true,
    waitingForStudentInput: true,
    answerRevealed: false,
    practiceAvailable: true,
    tags: ['#Limits', '#Calculus', '#Grade12Math'],
    problemCount: 6,
  ),
  StudentLesson(
    lessonId: 'math.g12.lesson2.derivatives',
    curriculumVersionId: 'g12-stem-math-v1',
    gradeLevelId: 'grade-12',
    grade: 12,
    subjectId: 'math',
    subject: 'Mathematics',
    topicId: 'math-g12-derivatives',
    topic: 'Derivatives of Functions',
    title: 'ដេរីវេនៃអនុគមន៍',
    englishTitle: 'Derivatives of Functions',
    description: 'Calculate derivatives, instantaneous rates of change, and tangent line equations.',
    khmerDescription: 'គណនាដេរីវេ អត្រាបម្រែបម្រួលភ្លាមៗ និងសមីការបន្ទាត់ប៉ះ។',
    difficulty: 'advanced',
    languageMode: 'bilingual',
    isAvailable: false,
    waitingForStudentInput: false,
    answerRevealed: false,
    practiceAvailable: false,
  ),
  StudentLesson(
    lessonId: 'math.g12.lesson3.integrals',
    curriculumVersionId: 'g12-stem-math-v1',
    gradeLevelId: 'grade-12',
    grade: 12,
    subjectId: 'math',
    subject: 'Mathematics',
    topicId: 'math-g12-integrals',
    topic: 'Integrals & Area Calculation',
    title: 'អាំងតេក្រាល និងផ្ទៃក្រឡា',
    englishTitle: 'Integrals & Area Calculation',
    description: 'Evaluate indefinite and definite integrals to compute area under curves.',
    khmerDescription: 'គណនាអាំងតេក្រាលមិនកំណត់ និងអាំងតេក្រាលកំណត់សម្រាប់ស្វែងរកផ្ទៃក្រឡា។',
    difficulty: 'advanced',
    languageMode: 'bilingual',
    isAvailable: false,
    waitingForStudentInput: false,
    answerRevealed: false,
    practiceAvailable: false,
  ),
  StudentLesson(
    lessonId: 'math.g12.lesson4.complex-numbers',
    curriculumVersionId: 'g12-stem-math-v1',
    gradeLevelId: 'grade-12',
    grade: 12,
    subjectId: 'math',
    subject: 'Mathematics',
    topicId: 'math-g12-complex-numbers',
    topic: 'Complex Numbers',
    title: 'ចំនួនកុំផ្លិច',
    englishTitle: 'Complex Numbers',
    description: 'Represent and operate with complex numbers in algebraic and trigonometric forms.',
    khmerDescription: 'ទម្រង់ពីជគណិត និងទម្រង់ត្រីកោណមាត្រនៃចំនួនកុំផ្លិច។',
    difficulty: 'advanced',
    languageMode: 'bilingual',
    isAvailable: false,
    waitingForStudentInput: false,
    answerRevealed: false,
    practiceAvailable: false,
  ),
  StudentLesson(
    lessonId: 'math.g12.lesson5.probability',
    curriculumVersionId: 'g12-stem-math-v1',
    gradeLevelId: 'grade-12',
    grade: 12,
    subjectId: 'math',
    subject: 'Mathematics',
    topicId: 'math-g12-probability',
    topic: 'Probability & Combinatorics',
    title: 'ប្រូបាប និងបន្សំ',
    englishTitle: 'Probability & Combinatorics',
    description: 'Compute combinations, permutations, and probability of discrete events.',
    khmerDescription: 'គណនាបន្សំ តម្រៀប និងប្រូបាបនៃព្រឹត្តិការណ៍ចៃដន្យ។',
    difficulty: 'intermediate',
    languageMode: 'bilingual',
    isAvailable: false,
    waitingForStudentInput: false,
    answerRevealed: false,
    practiceAvailable: false,
  ),

  // ── Physics (Grade 12) ────────────────────────────────────────────────────
  StudentLesson(
    lessonId: 'physics.g12.lesson1.kinematics',
    curriculumVersionId: 'g12-stem-physics-v1',
    gradeLevelId: 'grade-12',
    grade: 12,
    subjectId: 'physics',
    subject: 'Physics',
    topicId: 'physics-g12-kinematics',
    topic: 'Kinematics & Motion',
    title: 'ចលនាត្រង់ស្ទុះស្មើ',
    englishTitle: 'Kinematics: Constant Acceleration',
    description: 'Solve motion problems with constant acceleration using v = u + at and s = ut + 1/2 at^2.',
    khmerDescription: 'ដោះស្រាយបញ្ហាចលនាដោយប្រើសមីការ v = u + at និង s = ut + 1/2 at^2 ជាមួយខ្នាតច្បាស់លាស់។',
    starterProblem: 'v = u + at, u=0, a=2, t=5',
    difficulty: 'beginner',
    languageMode: 'bilingual',
    isAvailable: true,
    waitingForStudentInput: true,
    answerRevealed: false,
    practiceAvailable: true,
    tags: ['#Kinematics', '#Acceleration', '#Grade12Physics'],
    problemCount: 5,
  ),
  StudentLesson(
    lessonId: 'physics.g12.lesson2.dynamics',
    curriculumVersionId: 'g12-stem-physics-v1',
    gradeLevelId: 'grade-12',
    grade: 12,
    subjectId: 'physics',
    subject: 'Physics',
    topicId: 'physics-g12-dynamics',
    topic: "Newton's Laws & Dynamics",
    title: 'ច្បាប់ញូតុន និងឌីណាមិច',
    englishTitle: "Newton's Laws & Dynamics",
    description: 'Construct free-body diagrams and calculate acceleration and resultant forces.',
    khmerDescription: 'វិភាគកម្លាំង សំទុះ និងគំនូសកម្លាំងសេរី (Free-body diagram)។',
    difficulty: 'intermediate',
    languageMode: 'bilingual',
    isAvailable: false,
    waitingForStudentInput: false,
    answerRevealed: false,
    practiceAvailable: false,
  ),
  StudentLesson(
    lessonId: 'physics.g12.lesson3.work-energy',
    curriculumVersionId: 'g12-stem-physics-v1',
    gradeLevelId: 'grade-12',
    grade: 12,
    subjectId: 'physics',
    subject: 'Physics',
    topicId: 'physics-g12-work-energy',
    topic: 'Work, Energy & Power',
    title: 'កម្មន្ត ថាមពល និងអានុភាព',
    englishTitle: 'Work, Energy & Power',
    description: 'Apply the work-energy theorem and mechanical energy conservation principles.',
    khmerDescription: 'ច្បាប់រក្សាថាមពលមេកានិច និងការគណនាកម្មន្តនៃកម្លាំង។',
    difficulty: 'intermediate',
    languageMode: 'bilingual',
    isAvailable: false,
    waitingForStudentInput: false,
    answerRevealed: false,
    practiceAvailable: false,
  ),
  StudentLesson(
    lessonId: 'physics.g12.lesson4.waves',
    curriculumVersionId: 'g12-stem-physics-v1',
    gradeLevelId: 'grade-12',
    grade: 12,
    subjectId: 'physics',
    subject: 'Physics',
    topicId: 'physics-g12-waves',
    topic: 'Mechanical Waves & Oscillations',
    title: 'រលកមេកានិច និងសំឡេង',
    englishTitle: 'Mechanical Waves & Oscillations',
    description: 'Relate wave frequency, period, wavelength, and propagation speed in material media.',
    khmerDescription: 'លក្ខណៈរលក ប្រេកង់ ប្រវែងរលក និងល្បឿនដំណាលរលក។',
    difficulty: 'advanced',
    languageMode: 'bilingual',
    isAvailable: false,
    waitingForStudentInput: false,
    answerRevealed: false,
    practiceAvailable: false,
  ),
  StudentLesson(
    lessonId: 'physics.g12.lesson5.electromagnetism',
    curriculumVersionId: 'g12-stem-physics-v1',
    gradeLevelId: 'grade-12',
    grade: 12,
    subjectId: 'physics',
    subject: 'Physics',
    topicId: 'physics-g12-electromagnetism',
    topic: 'Electromagnetism & Induction',
    title: 'អគ្គិសនី និងដែនម៉ាញ៉េទិច',
    englishTitle: 'Electromagnetism & Induction',
    description: 'Calculate magnetic forces and induced electromotive force using Faraday and Lenz laws.',
    khmerDescription: 'ដែនម៉ាញ៉េទិច ច្បាប់ហ្វារ៉ាដេយ និងកម្លាំងអេឡិចត្រូម៉ូទ័រអាំងឌ្វី។',
    difficulty: 'advanced',
    languageMode: 'bilingual',
    isAvailable: false,
    waitingForStudentInput: false,
    answerRevealed: false,
    practiceAvailable: false,
  ),

  // ── Chemistry (Grade 12) ──────────────────────────────────────────────────
  StudentLesson(
    lessonId: 'chemistry.g12.lesson1.stoichiometry',
    curriculumVersionId: 'g12-stem-chem-v1',
    gradeLevelId: 'grade-12',
    grade: 12,
    subjectId: 'chemistry',
    subject: 'Chemistry',
    topicId: 'chemistry-g12-stoichiometry',
    topic: 'Stoichiometry & Reactions',
    title: 'ស្តូគ្យូម៉េទ្រី និងសមីការគីមី',
    englishTitle: 'Stoichiometry & Reaction Balance',
    description: 'Balance chemical reactions, calculate moles, molar masses, and mass-mole relationships.',
    khmerDescription: 'ថ្លឹងសមីការគីមី គណនាម៉ូល ម៉ាសម៉ូល និងទំនាក់ទំនងម៉ាស-ម៉ូលក្នុងប្រតិកម្ម។',
    starterProblem: r'2H_2 + O_2 \to 2H_2O',
    difficulty: 'beginner',
    languageMode: 'bilingual',
    isAvailable: true,
    waitingForStudentInput: true,
    answerRevealed: false,
    practiceAvailable: true,
    tags: ['#Stoichiometry', '#Moles', '#Grade12Chemistry'],
    problemCount: 5,
  ),
  StudentLesson(
    lessonId: 'chemistry.g12.lesson2.kinetics',
    curriculumVersionId: 'g12-stem-chem-v1',
    gradeLevelId: 'grade-12',
    grade: 12,
    subjectId: 'chemistry',
    subject: 'Chemistry',
    topicId: 'chemistry-g12-kinetics',
    topic: 'Chemical Kinetics & Reaction Rates',
    title: 'ស៊ីនេទិចគីមី និងល្បឿនប្រតិកម្ម',
    englishTitle: 'Chemical Kinetics & Reaction Rates',
    description: 'Analyze rate laws, half-life, and factors affecting chemical reaction rates.',
    khmerDescription: 'កត្តាជះឥទ្ធិពលលើល្បឿនប្រតិកម្ម និងច្បាប់ល្បឿន។',
    difficulty: 'advanced',
    languageMode: 'bilingual',
    isAvailable: false,
    waitingForStudentInput: false,
    answerRevealed: false,
    practiceAvailable: false,
  ),
  StudentLesson(
    lessonId: 'chemistry.g12.lesson3.equilibrium',
    curriculumVersionId: 'g12-stem-chem-v1',
    gradeLevelId: 'grade-12',
    grade: 12,
    subjectId: 'chemistry',
    subject: 'Chemistry',
    topicId: 'chemistry-g12-equilibrium',
    topic: 'Chemical Equilibrium & Le Chatelier',
    title: 'លំនឹងគីមី និងគោលការណ៍ឡឺឆាតឺលីយេ',
    englishTitle: 'Chemical Equilibrium & Le Chatelier',
    description: 'Determine equilibrium constants and predict equilibrium shifts using Le Chatelier principle.',
    khmerDescription: 'ថេរលំនឹង Kc ការផ្លាស់ប្តូរលំនឹងតាមកំហាប់ សម្ពាធ និងសីតុណ្ហភាព។',
    difficulty: 'advanced',
    languageMode: 'bilingual',
    isAvailable: false,
    waitingForStudentInput: false,
    answerRevealed: false,
    practiceAvailable: false,
  ),
  StudentLesson(
    lessonId: 'chemistry.g12.lesson4.acids-bases',
    curriculumVersionId: 'g12-stem-chem-v1',
    gradeLevelId: 'grade-12',
    grade: 12,
    subjectId: 'chemistry',
    subject: 'Chemistry',
    topicId: 'chemistry-g12-acids-bases',
    topic: 'Acids, Bases & pH Calculations',
    title: 'អាស៊ីត-បាស និងកម្រិត pH',
    englishTitle: 'Acids, Bases & pH Calculations',
    description: 'Calculate pH, pOH, and hydronium/hydroxide concentrations in aqueous solution.',
    khmerDescription: 'គណនា pH, pOH, កំហាប់អ៊ីយ៉ុង H3O+ និង OH- ក្នុងសូលុយស្យុង។',
    difficulty: 'intermediate',
    languageMode: 'bilingual',
    isAvailable: false,
    waitingForStudentInput: false,
    answerRevealed: false,
    practiceAvailable: false,
  ),
  StudentLesson(
    lessonId: 'chemistry.g12.lesson5.organic',
    curriculumVersionId: 'g12-stem-chem-v1',
    gradeLevelId: 'grade-12',
    grade: 12,
    subjectId: 'chemistry',
    subject: 'Chemistry',
    topicId: 'chemistry-g12-organic',
    topic: 'Organic Chemistry: Functional Groups',
    title: 'គីមីសរីរាង្គ៖ បង្គុំនាទី',
    englishTitle: 'Organic Chemistry: Functional Groups',
    description: 'Identify functional groups and apply IUPAC nomenclature for alcohols, aldehydes, and acids.',
    khmerDescription: 'សម្គាល់ និងហៅឈ្មោះអាល់កុល អាល់ដេអ៊ីត សេតូន និងអាស៊ីតកាបុកស៊ីលិច។',
    difficulty: 'advanced',
    languageMode: 'bilingual',
    isAvailable: false,
    waitingForStudentInput: false,
    answerRevealed: false,
    practiceAvailable: false,
  ),
];

/// Fallback published curriculum catalog for Grade 10 STEM.
const List<StudentLesson> publishedGrade10StemFallbackLessons = [
  // ── Mathematics (Grade 10) ────────────────────────────────────────────────
  StudentLesson(
    lessonId: 'math.g10.lesson1.linear-systems',
    curriculumVersionId: 'g10-stem-math-v1',
    gradeLevelId: 'grade-10',
    grade: 10,
    subjectId: 'math',
    subject: 'Mathematics',
    topicId: 'math-g10-linear-systems',
    topic: 'Systems of Linear Equations',
    title: 'ប្រព័ន្ធសមីការលីនេអ៊ែរ',
    englishTitle: 'Systems of Linear Equations',
    description: 'Solve systems of two and three linear equations using substitution and elimination.',
    khmerDescription: 'ដោះស្រាយប្រព័ន្ធសមីការលីនេអ៊ែរមានពីរ និងបីអញ្ញាត ដោយវិធីជំនួស និងវិធីបូកបំបាត់។',
    starterProblem: r'\begin{cases} 2x + y = 7 \\ x - y = 2 \end{cases}',
    difficulty: 'beginner',
    languageMode: 'bilingual',
    isAvailable: true,
    waitingForStudentInput: true,
    answerRevealed: false,
    practiceAvailable: true,
    tags: ['#LinearEquations', '#Algebra', '#Grade10'],
    problemCount: 5,
  ),
  StudentLesson(
    lessonId: 'math.g10.lesson2.quadratic-functions',
    curriculumVersionId: 'g10-stem-math-v1',
    gradeLevelId: 'grade-10',
    grade: 10,
    subjectId: 'math',
    subject: 'Mathematics',
    topicId: 'math-g10-quadratic-functions',
    topic: 'Quadratic Functions & Parabolas',
    title: 'អនុគមន៍ដឺក្រេទីពីរ និងប៉ារ៉ាបូល',
    englishTitle: 'Quadratic Functions & Parabolas',
    description: 'Analyze quadratic curves, find vertex, axis of symmetry, and roots using discriminant.',
    khmerDescription: 'សិក្សាខ្សែគោចរដឺក្រេទីពីរ រកកំពូល អ័ក្សឆ្លុះ និងឫសដោយប្រើឌីស្គ្រីមីណង់។',
    difficulty: 'intermediate',
    languageMode: 'bilingual',
    isAvailable: false,
    tags: ['#Quadratics', '#Parabolas', '#Vertex'],
    problemCount: 4,
  ),
  StudentLesson(
    lessonId: 'math.g10.lesson3.trig-ratios',
    curriculumVersionId: 'g10-stem-math-v1',
    gradeLevelId: 'grade-10',
    grade: 10,
    subjectId: 'math',
    subject: 'Mathematics',
    topicId: 'math-g10-trig-ratios',
    topic: 'Trigonometric Ratios in Right Triangles',
    title: 'ផលធៀបត្រីកោណមាត្រក្នុងត្រីកោណកែង',
    englishTitle: 'Trigonometric Ratios in Right Triangles',
    description: 'Calculate sine, cosine, and tangent ratios for acute angles in right-angled triangles.',
    khmerDescription: 'គណនាផលធៀបស៊ីនុស កូស៊ីនុស និងតង់សង់សម្រាប់មុំស្រួចក្នុងត្រីកោណកែង។',
    difficulty: 'beginner',
    languageMode: 'bilingual',
    isAvailable: false,
    tags: ['#Trigonometry', '#RightTriangles'],
    problemCount: 4,
  ),

  // ── Physics (Grade 10) ────────────────────────────────────────────────────
  StudentLesson(
    lessonId: 'physics.g10.lesson1.uniform-motion',
    curriculumVersionId: 'g10-stem-physics-v1',
    gradeLevelId: 'grade-10',
    grade: 10,
    subjectId: 'physics',
    subject: 'Physics',
    topicId: 'physics-g10-uniform-motion',
    topic: 'Uniform Linear Motion & Speed',
    title: 'ចលនាត្រង់ស្មើ និងល្បឿន',
    englishTitle: 'Uniform Linear Motion & Speed',
    description: 'Calculate constant velocity, travel distance, and elapsed time in uniform linear motion.',
    khmerDescription: 'គណនាល្បឿនថេរ ចម្ងាយចរ និងរយៈពេលក្នុងចលនាត្រង់ស្មើ។',
    starterProblem: r'v = \frac{s}{t}, s = 120\text{ m}, t = 6\text{ s}',
    difficulty: 'beginner',
    languageMode: 'bilingual',
    isAvailable: true,
    waitingForStudentInput: true,
    answerRevealed: false,
    practiceAvailable: true,
    tags: ['#Kinematics', '#Speed', '#Grade10Physics'],
    problemCount: 5,
  ),
  StudentLesson(
    lessonId: 'physics.g10.lesson2.newtons-laws',
    curriculumVersionId: 'g10-stem-physics-v1',
    gradeLevelId: 'grade-10',
    grade: 10,
    subjectId: 'physics',
    subject: 'Physics',
    topicId: 'physics-g10-newtons-laws',
    topic: "Newton's Laws of Motion",
    title: 'ច្បាប់ចលនាញូតុន',
    englishTitle: "Newton's Laws of Motion",
    description: 'Apply F = ma and action-reaction principles to analyze forces acting on objects.',
    khmerDescription: 'អនុវត្តរូបមន្ត F = ma និងគោលការណ៍អំពើ-ប្រតិកម្មដើម្បីវិភាគកម្លាំង។',
    difficulty: 'intermediate',
    languageMode: 'bilingual',
    isAvailable: false,
    tags: ['#Forces', '#NewtonsLaws', '#Dynamics'],
    problemCount: 4,
  ),
  StudentLesson(
    lessonId: 'physics.g10.lesson3.work-energy',
    curriculumVersionId: 'g10-stem-physics-v1',
    gradeLevelId: 'grade-10',
    grade: 10,
    subjectId: 'physics',
    subject: 'Physics',
    topicId: 'physics-g10-work-energy',
    topic: 'Mechanical Work & Energy',
    title: 'កម្មន្តមេកានិច និងថាមពល',
    englishTitle: 'Mechanical Work & Energy',
    description: 'Calculate work done by constant forces and kinetic/potential mechanical energy.',
    khmerDescription: 'គណនាកម្មន្តនៃកម្លាំងថេរ និងថាមពលស៊ីនេទិច/ប៉ូតង់ស្យែលមេកានិច។',
    difficulty: 'intermediate',
    languageMode: 'bilingual',
    isAvailable: false,
    tags: ['#Work', '#Energy', '#Conservation'],
    problemCount: 4,
  ),

  // ── Chemistry (Grade 10) ──────────────────────────────────────────────────
  StudentLesson(
    lessonId: 'chemistry.g10.lesson1.atomic-structure',
    curriculumVersionId: 'g10-stem-chem-v1',
    gradeLevelId: 'grade-10',
    grade: 10,
    subjectId: 'chemistry',
    subject: 'Chemistry',
    topicId: 'chemistry-g10-atomic-structure',
    topic: 'Atomic Structure & Periodic Table',
    title: 'ទម្រង់អាតូម និងតារាងខួប',
    englishTitle: 'Atomic Structure & Periodic Table',
    description: 'Understand protons, neutrons, electrons, electron shells, and periodic trends.',
    khmerDescription: 'ស្វែងយល់ពីប្រូតុង ណឺត្រុង អេឡិចត្រុង ស្រទាប់អេឡិចត្រុង និងការរៀបចំក្នុងតារាងខួប។',
    starterProblem: r'\text{Electron configuration of } \text{Cl } (Z=17)',
    difficulty: 'beginner',
    languageMode: 'bilingual',
    isAvailable: true,
    waitingForStudentInput: true,
    answerRevealed: false,
    practiceAvailable: true,
    tags: ['#AtomicStructure', '#PeriodicTable', '#Grade10Chemistry'],
    problemCount: 5,
  ),
  StudentLesson(
    lessonId: 'chemistry.g10.lesson2.chemical-bonding',
    curriculumVersionId: 'g10-stem-chem-v1',
    gradeLevelId: 'grade-10',
    grade: 10,
    subjectId: 'chemistry',
    subject: 'Chemistry',
    topicId: 'chemistry-g10-chemical-bonding',
    topic: 'Chemical Bonding: Ionic & Covalent',
    title: 'សម្ព័ន្ធគីមី៖ អ៊ីយ៉ុង និងកូវ៉ាឡង់',
    englishTitle: 'Chemical Bonding: Ionic & Covalent',
    description: 'Distinguish between ionic electron transfer and covalent electron sharing.',
    khmerDescription: 'បែងចែករវាងសម្ព័ន្ធអ៊ីយ៉ុង (ផ្ទេរអេឡិចត្រុង) និងសម្ព័ន្ធកូវ៉ាឡង់ (ចូលរួមអេឡិចត្រុង)។',
    difficulty: 'intermediate',
    languageMode: 'bilingual',
    isAvailable: false,
    tags: ['#Bonding', '#IonicBond', '#CovalentBond'],
    problemCount: 4,
  ),
  StudentLesson(
    lessonId: 'chemistry.g10.lesson3.solutions-concentration',
    curriculumVersionId: 'g10-stem-chem-v1',
    gradeLevelId: 'grade-10',
    grade: 10,
    subjectId: 'chemistry',
    subject: 'Chemistry',
    topicId: 'chemistry-g10-solutions-concentration',
    topic: 'Solutions & Molar Concentration',
    title: 'សូលុយស្យុង និងកំហាប់ជាម៉ូល',
    englishTitle: 'Solutions & Molar Concentration',
    description: 'Calculate molarity, solute mass, and volume of prepared aqueous solutions.',
    khmerDescription: 'គណនាកំហាប់ជាម៉ូល ម៉ាសសារធាតុរលាយ និងមាឌសូលុយស្យុង។',
    difficulty: 'intermediate',
    languageMode: 'bilingual',
    isAvailable: false,
    tags: ['#Molarity', '#Solutions', '#Concentration'],
    problemCount: 4,
  ),
];

/// Fallback published curriculum catalog for Grade 11 STEM.
const List<StudentLesson> publishedGrade11StemFallbackLessons = [
  // ── Mathematics (Grade 11) ────────────────────────────────────────────────
  StudentLesson(
    lessonId: 'math.g11.lesson1.sequences-series',
    curriculumVersionId: 'g11-stem-math-v1',
    gradeLevelId: 'grade-11',
    grade: 11,
    subjectId: 'math',
    subject: 'Mathematics',
    topicId: 'math-g11-sequences-series',
    topic: 'Sequences & Progressions (AP/GP)',
    title: 'ស្វ៊ីត និងស្វ៊ីតចំនួន (AP/GP)',
    englishTitle: 'Sequences & Progressions (AP/GP)',
    description: 'Find general terms and sums of arithmetic and geometric progressions.',
    khmerDescription: 'រកតួទូទៅ និងផលបូកតួនៃស្វ៊ីតនព្វន្ត និងស្វ៊ីតធរណីមាត្រ។',
    starterProblem: r'u_n = u_1 + (n - 1)d, u_1 = 3, d = 4, n = 10',
    difficulty: 'intermediate',
    languageMode: 'bilingual',
    isAvailable: true,
    waitingForStudentInput: true,
    answerRevealed: false,
    practiceAvailable: true,
    tags: ['#Sequences', '#ArithmeticProgression', '#Grade11Math'],
    problemCount: 5,
  ),
  StudentLesson(
    lessonId: 'math.g11.lesson2.trig-equations',
    curriculumVersionId: 'g11-stem-math-v1',
    gradeLevelId: 'grade-11',
    grade: 11,
    subjectId: 'math',
    subject: 'Mathematics',
    topicId: 'math-g11-trig-equations',
    topic: 'Trigonometric Equations & Formulas',
    title: 'សមីការត្រីកោណមាត្រ និងរូបមន្តបំប្លែង',
    englishTitle: 'Trigonometric Equations & Formulas',
    description: 'Solve trigonometric equations using compound angle and double angle identities.',
    khmerDescription: 'ដោះស្រាយសមីការត្រីកោណមាត្រដោយប្រើរូបមន្តមុំទ្វេ និងរូបមន្តផលបូក-ផលដក។',
    difficulty: 'advanced',
    languageMode: 'bilingual',
    isAvailable: false,
    tags: ['#Trigonometry', '#TrigEquations'],
    problemCount: 4,
  ),
  StudentLesson(
    lessonId: 'math.g11.lesson3.probability',
    curriculumVersionId: 'g11-stem-math-v1',
    gradeLevelId: 'grade-11',
    grade: 11,
    subjectId: 'math',
    subject: 'Mathematics',
    topicId: 'math-g11-probability',
    topic: 'Permutations, Combinations & Probability',
    title: 'ចម្លាស់ បន្សំ និងប្រូបាប៊ីលីតេ',
    englishTitle: 'Permutations, Combinations & Probability',
    description: 'Compute counting arrangements and classical probability of independent events.',
    khmerDescription: 'គណនាចំនួនរៀបតាមចម្លាស់ បន្សំ និងប្រូបាបនៃព្រឹត្តិការណ៍។',
    difficulty: 'intermediate',
    languageMode: 'bilingual',
    isAvailable: false,
    tags: ['#Probability', '#Combinations', '#Permutations'],
    problemCount: 4,
  ),

  // ── Physics (Grade 11) ────────────────────────────────────────────────────
  StudentLesson(
    lessonId: 'physics.g11.lesson1.optics-snells-law',
    curriculumVersionId: 'g11-stem-physics-v1',
    gradeLevelId: 'grade-11',
    grade: 11,
    subjectId: 'physics',
    subject: 'Physics',
    topicId: 'physics-g11-optics-snells-law',
    topic: "Geometrical Optics & Snell's Law",
    title: 'អុបទិចធរណីមាត្រ និងច្បាប់ដេកាត (Snell)',
    englishTitle: "Geometrical Optics & Snell's Law",
    description: 'Calculate angles of refraction and critical angles using Snell-Descartes law.',
    khmerDescription: 'គណនាមុំកំណក និងមុំព្រំដែនដោយប្រើច្បាប់ដេកាត n1 sin(θ1) = n2 sin(θ2)។',
    starterProblem: r'n_1 \sin(\theta_1) = n_2 \sin(\theta_2), n_1=1.0, \theta_1=30^\circ, n_2=1.5',
    difficulty: 'intermediate',
    languageMode: 'bilingual',
    isAvailable: true,
    waitingForStudentInput: true,
    answerRevealed: false,
    practiceAvailable: true,
    tags: ['#Optics', '#SnellsLaw', '#Refraction', '#Grade11Physics'],
    problemCount: 5,
  ),
  StudentLesson(
    lessonId: 'physics.g11.lesson2.rotational-dynamics',
    curriculumVersionId: 'g11-stem-physics-v1',
    gradeLevelId: 'grade-11',
    grade: 11,
    subjectId: 'physics',
    subject: 'Physics',
    topicId: 'physics-g11-rotational-dynamics',
    topic: 'Rotational Dynamics & Torque',
    title: 'ឌីណាមិចរង្វិល និងម៉ូម៉ង់កម្លាំង (Torque)',
    englishTitle: 'Rotational Dynamics & Torque',
    description: 'Apply torque τ = rF sin(θ) and moment of inertia to rotating rigid bodies.',
    khmerDescription: 'អនុវត្តរូបមន្តម៉ូម៉ង់កម្លាំង τ = rF sin(θ) និងម៉ូម៉ង់និចលភាព។',
    difficulty: 'advanced',
    languageMode: 'bilingual',
    isAvailable: false,
    tags: ['#Torque', '#Rotation', '#Dynamics'],
    problemCount: 4,
  ),
  StudentLesson(
    lessonId: 'physics.g11.lesson3.thermodynamics',
    curriculumVersionId: 'g11-stem-physics-v1',
    gradeLevelId: 'grade-11',
    grade: 11,
    subjectId: 'physics',
    subject: 'Physics',
    topicId: 'physics-g11-thermodynamics',
    topic: 'Thermodynamics & Heat Transfer',
    title: 'ទែម៉ូឌីណាមិច និងការបញ្ជូនកម្តៅ',
    englishTitle: 'Thermodynamics & Heat Transfer',
    description: 'First law of thermodynamics, heat engines, conduction, and thermal equilibrium.',
    khmerDescription: 'ច្បាប់ទីមួយនៃទែម៉ូឌីណាមិច ម៉ាស៊ីនកម្តៅ និងការចម្លងកម្តៅ។',
    difficulty: 'advanced',
    languageMode: 'bilingual',
    isAvailable: false,
    tags: ['#Thermodynamics', '#HeatTransfer'],
    problemCount: 4,
  ),

  // ── Chemistry (Grade 11) ──────────────────────────────────────────────────
  StudentLesson(
    lessonId: 'chemistry.g11.lesson1.gas-laws',
    curriculumVersionId: 'g11-stem-chem-v1',
    gradeLevelId: 'grade-11',
    grade: 11,
    subjectId: 'chemistry',
    subject: 'Chemistry',
    topicId: 'chemistry-g11-gas-laws',
    topic: 'Ideal Gas Law (PV = nRT)',
    title: 'ច្បាប់ឧស្ម័នបរិសុទ្ធ (PV = nRT)',
    englishTitle: 'Ideal Gas Law (PV = nRT)',
    description: 'Apply ideal gas equations to calculate pressure, volume, temperature, and moles.',
    khmerDescription: 'អនុវត្តសមីការឧស្ម័នបរិសុទ្ធ PV = nRT គណនាសម្ពាធ មាឌ សីតុណ្ហភាព និងចំនួនម៉ូល។',
    starterProblem: r'PV = nRT, P=1\text{ atm}, V=22.4\text{ L}, T=273.15\text{ K}',
    difficulty: 'intermediate',
    languageMode: 'bilingual',
    isAvailable: true,
    waitingForStudentInput: true,
    answerRevealed: false,
    practiceAvailable: true,
    tags: ['#GasLaws', '#PVnRT', '#IdealGas', '#Grade11Chemistry'],
    problemCount: 5,
  ),
  StudentLesson(
    lessonId: 'chemistry.g11.lesson2.chemical-kinetics',
    curriculumVersionId: 'g11-stem-chem-v1',
    gradeLevelId: 'grade-11',
    grade: 11,
    subjectId: 'chemistry',
    subject: 'Chemistry',
    topicId: 'chemistry-g11-chemical-kinetics',
    topic: 'Chemical Kinetics & Reaction Rates',
    title: 'ស៊ីនេទិចគីមី និងល្បឿនប្រតិកម្ម',
    englishTitle: 'Chemical Kinetics & Reaction Rates',
    description: 'Factors affecting chemical reaction rates: concentration, temperature, and catalysts.',
    khmerDescription: 'កត្តាជះឥទ្ធិពលលើល្បឿនប្រតិកម្ម៖ កំហាប់ សីតុណ្ហភាព និងកាតាលីករ។',
    difficulty: 'advanced',
    languageMode: 'bilingual',
    isAvailable: false,
    tags: ['#Kinetics', '#ReactionRates', '#Catalysts'],
    problemCount: 4,
  ),
  StudentLesson(
    lessonId: 'chemistry.g11.lesson3.thermochemistry',
    curriculumVersionId: 'g11-stem-chem-v1',
    gradeLevelId: 'grade-11',
    grade: 11,
    subjectId: 'chemistry',
    subject: 'Chemistry',
    topicId: 'chemistry-g11-thermochemistry',
    topic: 'Thermochemistry & Reaction Enthalpy',
    title: 'ទែម៉ូគីមី និងអង់តាល់ពីនៃប្រតិកម្ម',
    englishTitle: 'Thermochemistry & Reaction Enthalpy',
    description: 'Calculate exothermic and endothermic enthalpy changes using Hess law.',
    khmerDescription: 'គណនាបម្រែបម្រួលអង់តាល់ពីប្រតិកម្មបញ្ចេញកម្តៅ និងស្រូបកម្តៅតាមច្បាប់ហែស។',
    difficulty: 'advanced',
    languageMode: 'bilingual',
    isAvailable: false,
    tags: ['#Thermochemistry', '#Enthalpy', '#HessLaw'],
    problemCount: 4,
  ),
];

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
