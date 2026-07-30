import 'package:flutter/material.dart';

import '../screens/Dashboard/dashboard.dart';
import '../screens/auth/auth_form_screen.dart';
import '../screens/profile/profile.dart';
import '../screens/quizzes/quizzes_screen.dart';
import '../screens/tutor/tutor_screen.dart';
import '../screens/voice/voice_screen.dart';
import '../shared/app_bottom_navigation.dart';
import '../shared/app_header.dart';

class TutorShell extends StatefulWidget {
  const TutorShell({super.key});

  @override
  State<TutorShell> createState() => _TutorShellState();
}

class _TutorShellState extends State<TutorShell> {
  int _selectedIndex = 0;

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  void _logout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const AuthFormScreen(initialIsSignUp: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      DashboardScreen(onOpenTab: _selectTab),
      const TutorScreen(),
      const VoiceScreen(),
      const QuizzesScreen(),
      ProfileScreen(onLogout: _logout),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_selectedIndex != 0 && _selectedIndex != 4) const AppHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(_selectedIndex),
                  child: screens[_selectedIndex],
                ),
              ),
            ),
            AppBottomNavigation(
              selectedIndex: _selectedIndex,
              onSelected: _selectTab,
            ),
          ],
        ),
      ),
    );
  }
}
