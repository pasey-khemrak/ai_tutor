import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';
import '../core/auth/auth_service.dart';
import '../core/routing/app_routes.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/dashboard/dashboard_repository.dart';
import '../screens/history/student_session_history_screen.dart';
import '../screens/learning_selection/learning_selection_repository.dart';
import '../screens/progress/student_progress_screen.dart';
import '../screens/saved/saved_solutions_screen.dart';
import '../screens/profile/student_profile_summary_screen.dart';
import '../screens/quizzes/quizzes_screen.dart';
import '../screens/lessons/student_lessons_screen.dart';
import '../screens/lessons/student_lessons_repository.dart';
import '../screens/profile/student_profile_setup_sheet.dart';
import '../features/quizzes/quiz_repository.dart';
import '../screens/onboarding/first_run_explainer_sheet.dart';
import '../screens/tutor/tutor_screen.dart';
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
  String? _initialTutorPrefill;
  String? _initialTutorSessionId;
  bool _tutorVoiceMode = false;
  TargetedPracticeContext? _targetedPractice;
  int _dashboardRefreshSerial = 0;
  int _tutorSessionSerial = 0;

  static const _askQuestionContext = LearningContext.askQuestion();

  static const _localLimitsResumeKey = 'local_limits_active_view_v1';
  bool _navigationChosen = false;

  @override
  void initState() {
    super.initState();
    if (AppConfig.current.shouldUseDemoTutorData) {
      unawaited(_restoreLocalLimitsView());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FirstRunExplainerSheet.showIfNeeded(
          context,
          onSelectProblem: (problem) => _openLiveTutor(
            initialSubmission: VisualTutorStudentSubmission(
              message: problem,
              intent: 'new_problem',
              action: 'submit_problem',
              inputType: 'text',
              metadata: const {'entry_point': 'first_run_explainer'},
            ),
          ),
        );
      }
    });
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

  void _openTutorTab() {
    _rememberLocalLimitsView(false);
    setState(() {
      _learningContext ??= _askQuestionContext;
      _tutorVoiceMode = false;
      _selectedIndex = 1;
    });
  }

  void _openTutor() {
    _openTutorTab();
  }

  void _resumeLearning(StudentDashboardData data) {
    final canResumeSession = data.resumeSessionId != null;
    setState(() {
      _tutorSessionSerial++;
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
          : _askQuestionContext;
      _initialTutorSubmission = null;
      _initialTutorPrefill = null;
      _initialTutorSessionId = canResumeSession ? data.resumeSessionId : null;
      _tutorVoiceMode = false;
      _selectedIndex = 1;
    });
  }

  void _openTutorHome() {
    _openTutorTab();
  }

  void _openLiveTutor({
    LearningContext context = _askQuestionContext,
    VisualTutorStudentSubmission? initialSubmission,
    String? initialPrefill,
    bool voiceMode = false,
  }) {
    setState(() {
      _tutorSessionSerial++;
      _learningContext = context;
      _initialTutorSubmission = initialSubmission;
      _initialTutorPrefill = initialPrefill;
      _initialTutorSessionId = null;
      _tutorVoiceMode = voiceMode;
      _selectedIndex = 1;
    });
  }

  void _openVoiceTutor() {
    _openLiveTutor(context: _askQuestionContext, voiceMode: true);
  }

  Future<void> _openProgress() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudentProgressScreen(
          onPracticeTopic: (topicId, subjectId) {
            Navigator.of(context).pop();
            _openTargetedPractice(
              TargetedPracticeContext(
                tutorSessionId: 'progress-$topicId',
                topicId: topicId,
                subjectId: subjectId ?? '',
                gradeLevelId: '',
              ),
            );
          },
          onStartLearning: () {
            Navigator.of(context).pop();
            _openTutorHome();
          },
        ),
      ),
    );
  }

  Future<void> _openSavedSolutions() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SavedSolutionsScreen(
          onStartLearning: () {
            Navigator.of(context).pop();
            _openTutorHome();
          },
        ),
      ),
    );
  }

  Future<void> _openSessionHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudentSessionHistoryScreen(
          onOpenSession: (session) {
            Navigator.of(context).pop();
            _reopenSession(session);
          },
          onStartLearning: () {
            Navigator.of(context).pop();
            _openTutorHome();
          },
        ),
      ),
    );
  }

  /// Reopens a past board on the Tutor tab. Session restoration is
  /// authoritative, so the saved session id drives it rather than a fresh turn.
  void _reopenSession(DashboardActivity session) {
    setState(() {
      _tutorSessionSerial++;
      _learningContext = null;
      _initialTutorSubmission = null;
      _initialTutorPrefill = null;
      _initialTutorSessionId = session.tutorSessionId;
      _tutorVoiceMode = false;
      _selectedIndex = 1;
    });
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
      // The local demo is the one lesson that starts itself: it exists to
      // show the evaluator a finished board without anyone typing.
      initialSubmission: isLocalCurriculumDemo
          ? const VisualTutorStudentSubmission(
              message: 'Start local curriculum demo.',
              intent: 'new_problem',
              action: 'submit_problem',
              inputType: 'quick_action',
              metadata: {'entry_point': 'local_curriculum_demo'},
            )
          : null,
      // A published lesson's starter problem is an offer, not a question the
      // student asked. Submitting it on open put a finished board with the
      // answer on it in front of someone who had typed nothing, which is the
      // opposite of how this tutor is meant to teach. It waits in the input
      // box instead, one tap from being asked.
      initialPrefill: isLocalCurriculumDemo
          ? null
          : lesson.starterProblem?.trim(),
    );
  }

  void onWatchDemonstration(StudentLesson lesson, String? exampleProblem) {
    final isLocalCurriculumDemo = lesson.isLocalCurriculumDemo;
    _rememberLocalLimitsView(isLocalCurriculumDemo);
    _openLiveTutor(
      context: learningContextForLesson(lesson),
      initialSubmission: demonstrationSubmissionForLesson(
        lesson,
        exampleProblem,
      ),
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


  Future<void> _logout() async {
    await appAuthService.signOut();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.signIn, (route) => false);
  }

  int _stackIndexFor(int selectedIndex) {
    return switch (selectedIndex) {
      0 => 0,
      1 => 1,
      3 => 2,
      _ => 3,
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
              child: IndexedStack(
                index: _stackIndexFor(_selectedIndex),
                children: [
                  DashboardScreen(
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
                    onVoiceQuestion: _openVoiceTutor,
                    onStartDailyPractice: _startDashboardDailyPractice,
                    onCompleteProfile: _completeLearningProfile,
                    onBrowseCurriculum: () {
                      setState(() {
                        _targetedPractice = null;
                        _selectedIndex = 3;
                      });
                    },
                    onViewProgress: _openProgress,
                  ),
                  VisualTutorHomeScreen(
                    key: ValueKey('tutor-session-$_tutorSessionSerial'),
                    context: _learningContext ?? _askQuestionContext,
                    initialSessionId: _initialTutorSessionId,
                    initialSubmission: _initialTutorSubmission,
                    initialPrefill: _initialTutorPrefill,
                    voiceMode: _tutorVoiceMode,
                    onOpenTargetedPractice: _openTargetedPractice,
                  ),
                  _targetedPractice != null
                      ? QuizzesScreen(targetedPractice: _targetedPractice)
                      : StudentLessonsScreen(
                          onOpenLesson: _openLesson,
                          onWatchDemonstration: onWatchDemonstration,
                          onPractice: _practiceLesson,
                          onAskTutor: (problem) => _openLiveTutor(
                            initialSubmission: (problem != null && problem.isNotEmpty)
                                ? VisualTutorStudentSubmission(
                                    message: problem,
                                    intent: 'new_problem',
                                    action: 'submit_problem',
                                    inputType: 'text',
                                    metadata: const {'entry_point': 'empty_catalog'},
                                  )
                                : null,
                          ),
                        ),
                  StudentProfileSummaryScreen(
                    onSetup: _completeLearningProfile,
                    onLogout: _logout,
                    onOpenProgress: _openProgress,
                    onOpenHistory: _openSessionHistory,
                    onOpenSaved: _openSavedSolutions,
                  ),
                ],
              ),
            ),
            AppBottomNavigation(
              selectedIndex: _selectedIndex,
              onSelected: (index) {
                _rememberLocalLimitsView(false);
                if (index == 1) {
                  _openTutorTab();
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
/// the Tutor. Free question and voice paths use `askQuestion()`.
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

/// Builds the auto-starting demonstration submission when a student clicks
/// "Watch on Whiteboard" from a lesson's example walkthrough.
VisualTutorStudentSubmission demonstrationSubmissionForLesson(
  StudentLesson lesson,
  String? exampleProblem,
) {
  final problem = (exampleProblem != null && exampleProblem.trim().isNotEmpty)
      ? exampleProblem.trim()
      : (lesson.starterProblem != null &&
                lesson.starterProblem!.trim().isNotEmpty)
          ? lesson.starterProblem!.trim()
          : lesson.title;
  return VisualTutorStudentSubmission(
    message: problem,
    action: 'submit_problem',
    intent: 'new_problem',
    inputType: 'quick_action',
    metadata: const {
      'entry_point': 'lesson_demonstration',
      'auto_start': true,
    },
  );
}

extension _FirstStudentLessonOrNull on Iterable<StudentLesson> {
  StudentLesson? get firstOrNull => isEmpty ? null : first;
}
