import 'package:flutter/material.dart';
import '../screens/placeholder/placeholder_screen.dart';
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
  int _selectedIndex = 2;

  static const _screens = <Widget>[
    PlaceholderScreen(label: 'Dashboard'),
    TutorScreen(),
    VoiceScreen(),
    QuizzesScreen(),
    PlaceholderScreen(label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(_selectedIndex),
                  child: _screens[_selectedIndex],
                ),
              ),
            ),
            AppBottomNavigation(
              selectedIndex: _selectedIndex,
              onSelected: (index) => setState(() => _selectedIndex = index),
            ),
          ],
        ),
      ),
    );
  }
}
