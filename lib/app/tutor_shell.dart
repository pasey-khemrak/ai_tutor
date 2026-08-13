import 'package:flutter/material.dart';
import '../core/routing/app_routes.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/dashboard/dashboard_repository.dart';
import '../screens/learning_selection/learning_selection_repository.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/quizzes/quizzes_screen.dart';
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

  static const _defaultTutorContext = LearningContext(
    grade: 10,
    subject: 'Mathematics',
    topic: 'Linear Equations',
  );

  void _openTutor() {
    setState(() => _selectedIndex = 1);
  }

  void _resumeLearning(StudentDashboardData data) {
    final canResumeSession = data.resumeSessionId != null;
    setState(() {
      _learningContext = canResumeSession && data.resumeGrade != null
          ? LearningContext(
              grade: data.resumeGrade!,
              subject: data.resumeSubject,
              topic: data.resumeTopic,
            )
          : null;
      _initialTutorSubmission = null;
      _initialTutorSessionId = canResumeSession ? data.resumeSessionId : null;
      _selectedIndex = 1;
    });
  }

  void _openTutorHome() {
    setState(() {
      _learningContext = null;
      _initialTutorSubmission = null;
      _initialTutorSessionId = null;
      _selectedIndex = 1;
    });
  }

  void _openLiveTutor({
    LearningContext context = _defaultTutorContext,
    VisualTutorStudentSubmission? initialSubmission,
  }) {
    setState(() {
      _learningContext = context;
      _initialTutorSubmission = initialSubmission;
      _initialTutorSessionId = null;
      _selectedIndex = 1;
    });
  }

  void _openVoiceTutor() {
    _openLiveTutor(
      initialSubmission: const VisualTutorStudentSubmission(
        message: '',
        intent: 'voice_ready',
        action: 'start_voice',
        inputType: 'voice',
        metadata: {'entry_point': 'voice_input'},
      ),
    );
  }

  void _openStuckTutor() {
    _openLiveTutor(
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
      initialSubmission: VisualTutorStudentSubmission(
        message: text.trim(),
        intent: 'new_problem',
        action: 'submit_problem',
        inputType: 'image',
        metadata: const {'entry_point': 'scan_problem'},
      ),
    );
  }

  void _logout() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.signIn,
      (route) => false,
    );
  }

  Widget _buildScreen() {
    return switch (_selectedIndex) {
      0 => DashboardScreen(
        onResumeLearning: _openTutor,
        onResumeLearningWithData: _resumeLearning,
      ),
      1 =>
        _learningContext == null
            ? VisualTutorHomeScreen(
                onBack: () => setState(() => _selectedIndex = 0),
                onTypeQuestion: () => _openLiveTutor(),
                onVoiceInput: _openVoiceTutor,
                onStuck: _openStuckTutor,
                onScanProblem: _scanProblem,
                onContinueLearning: (context) =>
                    _openLiveTutor(context: context),
              )
            : TutorScreen(
                context: _learningContext,
                initialSessionId: _initialTutorSessionId,
                initialSubmission: _initialTutorSubmission,
              ),
      2 => TutorScreen(
        context: _defaultTutorContext,
        initialSubmission: const VisualTutorStudentSubmission(
          message: '',
          intent: 'voice_ready',
          action: 'start_voice',
          inputType: 'voice',
          metadata: {'entry_point': 'voice_tab'},
        ),
      ),
      3 => QuizzesScreen(),
      _ => ProfileScreen(
        onBack: () => setState(() => _selectedIndex = 0),
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
                if (index == 1) {
                  _openTutorHome();
                } else if (index == 2) {
                  _openVoiceTutor();
                } else {
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
