import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';
import '../core/auth/auth_service.dart';
import '../core/routing/app_routes.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/dashboard/dashboard_repository.dart';
import '../screens/learning_selection/learning_selection_repository.dart';
import '../screens/profile/student_profile_summary_screen.dart';
import '../screens/quizzes/quizzes_screen.dart';
import '../screens/lessons/student_lessons_screen.dart';
import '../screens/lessons/student_lessons_repository.dart';
import '../screens/profile/student_profile_setup_sheet.dart';
import '../features/quizzes/quiz_repository.dart';
import '../screens/tutor/tutor_screen.dart';
import '../screens/tutor/scan_problem_screen.dart';
import '../screens/tutor/visual_tutor_home_screen.dart';
import '../shared/app_bottom_navigation.dart';
import '../shared/app_header.dart';

class TutorShell extends StatefulWidget {
  const TutorShell({super.key});

  @override
  State<TutorShell> createState() => _TutorShellState();
}

class _TutorShellState extends State<TutorShell> {
  int _selectedIndex = 0;
  LearningContext? _learningContext;
  VisualTutorStudentSubmission? _initialTutorSubmission;
  String? _initialTutorSessionId;
  bool _tutorVoiceMode = false;
  TargetedPracticeContext? _targetedPractice;
  int _dashboardRefreshSerial = 0;

  static const _askQuestionContext = LearningContext.askQuestion();

  static const _localLimitsResumeKey = 'local_limits_active_view_v1';
  bool _navigationChosen = false;

  @override
  void initState() {
    super.initState();
    if (AppConfig.current.shouldUseDemoTutorData) {
      unawaited(_restoreLocalLimitsView());
    }
  }

  Future<void> _restoreLocalLimitsView() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || _navigationChosen ||
          prefs.getBool(_localLimitsResumeKey) != true) {
        return;
      }
      _openLesson(demoStudentLessons.single);
    } catch (_) {
      // Unavailable device storage must not block the lesson catalogue.
    }
  }

  void _rememberLocalLimitsView(bool active) {
    _navigationChosen = true;
    if (!AppConfig.current.shouldUseDemoTutorData) return;
    unawaited(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_localLimitsResumeKey, active);
      } catch (_) {
        // Presentation-only preference; lesson state has its own snapshot.
      }
    }());
  }


  void _openTutor() {
    setState(() {
      _tutorVoiceMode = false;
      _selectedIndex = 1;
    });
  }

  void _resumeLearning(StudentDashboardData data) {
    final canResumeSession = data.resumeSessionId != null;
    setState(() {
      // Session restoration is authoritative. A profile missing its grade must
      // not turn a valid resume action into the empty Tutor home.
      _learningContext = canResumeSession
          ? LearningContext(
              grade: data.resumeGrade ?? 10,
              subject: data.resumeSubject.isEmpty
                  ? 'Mathematics'
                  : data.resumeSubject,
              topic: data.resumeTopic.isEmpty
                  ? 'General tutoring'
                  : data.resumeTopic,
            )
          : null;
      _initialTutorSubmission = null;
      _initialTutorSessionId = canResumeSession ? data.resumeSessionId : null;
      _tutorVoiceMode = false;
      _selectedIndex = 1;
    });
  }

  void _openTutorHome() {
    _rememberLocalLimitsView(false);
    setState(() {
      _learningContext = null;
      _initialTutorSubmission = null;
      _initialTutorSessionId = null;
      _tutorVoiceMode = false;
      _selectedIndex = 1;
    });
  }

  void _openLiveTutor({
    LearningContext context = _askQuestionContext,
    VisualTutorStudentSubmission? initialSubmission,
    bool voiceMode = false,
  }) {
    setState(() {
      _learningContext = context;
      _initialTutorSubmission = initialSubmission;
      _initialTutorSessionId = null;
      _tutorVoiceMode = voiceMode;
      _selectedIndex = 1;
    });
  }

  void _openVoiceTutor() {
    _openLiveTutor(context: _askQuestionContext, voiceMode: true);
  }

  void _openTargetedPractice(TargetedPracticeContext practice) {
    setState(() {
      _targetedPractice = practice;
      _selectedIndex = 3;
    });
  }

  void _openLesson(StudentLesson lesson) {
    final isLocalCurriculumDemo = lesson.isLocalCurriculumDemo;
    _rememberLocalLimitsView(isLocalCurriculumDemo);
    _openLiveTutor(
      context: learningContextForLesson(lesson),
      // Only the explicitly selected local curriculum demo starts itself.
      // The device-local evaluator restores the approved current moment,
      // including when the gateway or AI service is unavailable.
      initialSubmission: isLocalCurriculumDemo
          ? const VisualTutorStudentSubmission(
              message: 'Start local curriculum demo.',
              intent: 'new_problem',
              action: 'submit_problem',
              inputType: 'quick_action',
              metadata: {'entry_point': 'local_curriculum_demo'},
            )
          : null,
    );
  }

  void _practiceLesson(StudentLesson lesson) {
    setState(() {
      _targetedPractice = TargetedPracticeContext(
        tutorSessionId: 'lesson-${lesson.lessonId}',
        topicId: lesson.topicId,
        subjectId: lesson.subjectId,
        gradeLevelId: lesson.gradeLevelId,
      );
      _selectedIndex = 3;
    });
  }

  Future<void> _completeLearningProfile() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111623),
      builder: (_) => StudentProfileSetupSheet(
        onCompleted: () => setState(() => _dashboardRefreshSerial++),
      ),
    );
  }

  Future<void> _startDashboardDailyPractice(StudentDashboardData data) async {
    final topicId = data.weakTopic?.topicId;
    if (topicId == null || topicId.isEmpty) {
      _openTutor();
      return;
    }
    try {
      final lessons = await BackendStudentLessonsRepository().loadLessons(
        topicId: topicId,
      );
      final lesson = lessons.firstOrNull;
      if (lesson == null) throw StateError('No active published lesson');
      _openLiveTutor(
        context: LearningContext(
          grade: lesson.grade,
          subject: lesson.subject,
          topic: lesson.topic,
          gradeLevelId: lesson.gradeLevelId,
          subjectId: lesson.subjectId,
          topicId: lesson.topicId,
          lessonId: lesson.lessonId,
          curriculumVersionId: lesson.curriculumVersionId,
          teachingMomentId: lesson.teachingMomentId,
          languageMode: lesson.languageMode,
        ),
        initialSubmission: VisualTutorStudentSubmission(
          message: 'Give me a short practice challenge for ${lesson.topic}.',
          intent: 'new_problem',
          action: 'submit_problem',
          inputType: 'quick_action',
          metadata: {
            'entry_point': 'dashboard_daily_practice',
            'lesson_id': lesson.lessonId,
            'curriculum_version_id': lesson.curriculumVersionId,
            'topic_id': lesson.topicId,
            'subject_id': lesson.subjectId,
            'grade_level_id': lesson.gradeLevelId,
            'recommended_difficulty': lesson.difficulty,
          },
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This practice topic is unavailable. Choose a lesson instead.',
          ),
        ),
      );
      setState(() => _selectedIndex = 3);
    }
  }

  void _openStuckTutor() {
    _openLiveTutor(
      context: _askQuestionContext,
      initialSubmission: const VisualTutorStudentSubmission(
        message: "I'm stuck",
        intent: 'stuck',
        action: 'stuck',
        inputType: 'quick_action',
        metadata: {'entry_point': 'visual_tutor_home_stuck'},
      ),
    );
  }

  Future<void> _scanProblem() async {
    final text = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanProblemScreen()),
    );
    if (!mounted || text == null || text.trim().isEmpty) return;
    _openLiveTutor(
      context: _askQuestionContext,
      initialSubmission: VisualTutorStudentSubmission(
        message: text.trim(),
        intent: 'new_problem',
        action: 'submit_problem',
        inputType: 'image',
        metadata: const {'entry_point': 'scan_problem'},
      ),
    );
  }

  Future<void> _logout() async {
    await appAuthService.signOut();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.signIn, (route) => false);
  }

  Widget _buildScreen() {
    return switch (_selectedIndex) {
      0 => DashboardScreen(
        key: ValueKey('dashboard-$_dashboardRefreshSerial'),
        onResumeLearning: _openTutor,
        onResumeLearningWithData: _resumeLearning,
        onAskQuestion: (question) => _openLiveTutor(
          initialSubmission: VisualTutorStudentSubmission(
            message: question,
            intent: 'new_problem',
            action: 'submit_problem',
            inputType: 'text',
            metadata: const {'entry_point': 'dashboard_ask_anything'},
          ),
        ),
        onScanQuestion: _scanProblem,
        onVoiceQuestion: _openVoiceTutor,
        onStartDailyPractice: _startDashboardDailyPractice,
        onCompleteProfile: _completeLearningProfile,
      ),
      1 =>
        _learningContext == null
            ? VisualTutorHomeScreen(
                onBack: () => setState(() => _selectedIndex = 0),
                onTypeQuestion: () => _openLiveTutor(),
                onVoiceInput: _openVoiceTutor,
                onStuck: _openStuckTutor,
                onScanProblem: _scanProblem,
                onOpenLessons: () => setState(() => _selectedIndex = 3),
                onContinueLearning: (context) =>
                    _openLiveTutor(context: context),
              )
            : TutorScreen(
                context: _learningContext,
                initialSessionId: _initialTutorSessionId,
                initialSubmission: _initialTutorSubmission,
                voiceMode: _tutorVoiceMode,
                onOpenTargetedPractice: _openTargetedPractice,
              ),
      2 => const SizedBox.shrink(),
      3 =>
        _targetedPractice != null
            ? QuizzesScreen(targetedPractice: _targetedPractice)
            : StudentLessonsScreen(
                onOpenLesson: _openLesson,
                onPractice: _practiceLesson,
              ),
      _ => StudentProfileSummaryScreen(
        onSetup: _completeLearningProfile,
        onLogout: _logout,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_selectedIndex != 4 && _selectedIndex != 1) const AppHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(_selectedIndex),
                  child: _buildScreen(),
                ),
              ),
            ),
            AppBottomNavigation(
              selectedIndex: _selectedIndex,
              onSelected: (index) {
                _rememberLocalLimitsView(false);
                if (index == 1) {
                  _openTutorHome();
                } else if (index == 2) {
                  _openVoiceTutor();
                } else {
                  if (index == 3) _targetedPractice = null;
                  setState(() => _selectedIndex = index);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A selected lesson is the only source of curriculum identifiers passed to
/// the Tutor. Free question, voice, and scan paths use `askQuestion()`.
LearningContext learningContextForLesson(StudentLesson lesson) =>
    LearningContext(
      grade: lesson.grade,
      subject: lesson.subject,
      topic: lesson.topic,
      gradeLevelId: lesson.gradeLevelId,
      subjectId: lesson.subjectId,
      topicId: lesson.topicId,
      lessonId: lesson.lessonId,
      curriculumVersionId: lesson.curriculumVersionId,
      teachingMomentId: lesson.teachingMomentId,
      languageMode: lesson.languageMode,
    );

extension _FirstStudentLessonOrNull on Iterable<StudentLesson> {
  StudentLesson? get firstOrNull => isEmpty ? null : first;
}
