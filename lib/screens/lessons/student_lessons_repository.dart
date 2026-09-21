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
}

abstract class StudentLessonsRepository {
  Future<List<StudentLesson>> loadLessons({
    String? search,
    String? subjectId,
    String? topicId,
    int? grade,
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
