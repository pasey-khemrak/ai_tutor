import 'package:flutter/material.dart';
import '../screens/placeholder/placeholder_screen.dart';
import '../screens/profile/profile_screen.dart';
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

  Widget _buildScreen() {
    return switch (_selectedIndex) {
      0 => const PlaceholderScreen(label: 'Dashboard'),
      1 => const TutorScreen(),
      2 => const VoiceScreen(),
      3 => const QuizzesScreen(),
      _ => ProfileScreen(onBack: () => setState(() => _selectedIndex = 0)),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_selectedIndex != 4) const AppHeader(),
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
              onSelected: (index) => setState(() => _selectedIndex = index),
            ),
          ],
        ),
      ),
    );
  }
}
