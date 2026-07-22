import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/tutor_shell.dart';
import '../../core/app_colors.dart';

class SetupFlowScreen extends StatefulWidget {
  const SetupFlowScreen({super.key});

  @override
  State<SetupFlowScreen> createState() => _SetupFlowScreenState();
}

class _SetupFlowScreenState extends State<SetupFlowScreen> {
  int _step = 0;
  int _grade = 10;
  String _lesson = 'math';

  void _continue() {
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const TutorShell()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _SetupBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 44, 32, 28),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: _step == 0
                  ? _ChooseGradeStep(
                      key: const ValueKey('grade'),
                      selectedGrade: _grade,
                      onSelect: (value) => setState(() => _grade = value),
                      onContinue: _continue,
                    )
                  : _ChooseLessonStep(
                      key: const ValueKey('lesson'),
                      selectedLesson: _lesson,
                      onSelect: (value) => setState(() => _lesson = value),
                      onContinue: _continue,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChooseGradeStep extends StatelessWidget {
  const _ChooseGradeStep({
    super.key,
    required this.selectedGrade,
    required this.onSelect,
    required this.onContinue,
  });

  final int selectedGrade;
  final ValueChanged<int> onSelect;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _SetupContent(
      title: 'ជ្រើសរើស ថ្នាក់',
      subtitle: 'ជ្រើសថ្នាក់ដែលអ្នកកំពុងសិក្សា',
      child: Column(
        children: [
          for (final grade in const [10, 11, 12]) ...[
            _SetupOptionCard(
              selected: selectedGrade == grade,
              leading: Text(
                '$grade',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              activeColor: grade == 10
                  ? AppColors.blue
                  : grade == 11
                  ? AppColors.cyan
                  : const Color(0xFF8B4CFF),
              title: 'ថ្នាក់ទី $grade',
              subtitle: 'សម្រាប់មេរៀន សំណួរ និង លំហាត់',
              onTap: () => onSelect(grade),
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 54),
          _SetupContinueButton(onPressed: onContinue),
        ],
      ),
    );
  }
}

class _ChooseLessonStep extends StatelessWidget {
  const _ChooseLessonStep({
    super.key,
    required this.selectedLesson,
    required this.onSelect,
    required this.onContinue,
  });

  final String selectedLesson;
  final ValueChanged<String> onSelect;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _SetupContent(
      title: 'ជ្រើសរើស មុខវិជ្ជា',
      subtitle: 'ជ្រើសមុខវិជ្ជាដែលអ្នកចង់រៀន',
      child: Column(
        children: [
          _SetupOptionCard(
            selected: selectedLesson == 'math',
            leading: const Icon(
              Icons.functions_rounded,
              color: Colors.black,
              size: 28,
            ),
            activeColor: AppColors.blue,
            title: 'គណិតវិទ្យា',
            subtitle: 'អនុគមន៍ សមីការ ត្រីកោណមាត្រ និងលំហាត់ថ្នាក់ទី 12',
            onTap: () => onSelect('math'),
          ),
          const SizedBox(height: 14),
          _SetupOptionCard(
            selected: selectedLesson == 'physics',
            leading: const Icon(
              Icons.science_rounded,
              color: Colors.black,
              size: 28,
            ),
            activeColor: AppColors.cyan,
            title: 'រូបវិទ្យា',
            subtitle: 'មេកានិច អគ្គិសនី រលក និងលំហាត់គណនា',
            onTap: () => onSelect('physics'),
          ),
          const SizedBox(height: 14),
          _SetupOptionCard(
            selected: selectedLesson == 'english',
            leading: const Text(
              'ENG',
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            activeColor: const Color(0xFF8B4CFF),
            title: 'អង់គ្លេស',
            subtitle: 'Vocabulary, Grammar and any General Lesson',
            onTap: () => onSelect('english'),
          ),
          const SizedBox(height: 54),
          _SetupContinueButton(onPressed: onContinue),
        ],
      ),
    );
  }
}

class _SetupContent extends StatelessWidget {
  const _SetupContent({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const _CapMark(),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF8793C3),
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 30),
        child,
      ],
    );
  }
}

class _SetupOptionCard extends StatelessWidget {
  const _SetupOptionCard({
    required this.selected,
    required this.leading,
    required this.activeColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final Widget leading;
  final Color activeColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: activeColor, width: 1.8),
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: .12),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
              child: leading,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8793C3),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected
                  ? activeColor
                  : activeColor.withValues(alpha: .85),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupContinueButton extends StatelessWidget {
  const _SetupContinueButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.blue, Color(0xFF7647FF)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'Continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupBackground extends StatelessWidget {
  const _SetupBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF080D19),
            Color(0xFF09101E),
            Color(0xFF10112A),
            Color(0xFF171342),
          ],
          stops: [0, .46, .74, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 96, sigmaY: 96),
                child: Align(
                  alignment: const Alignment(.2, -1.05),
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.blue.withValues(alpha: .18),
                    ),
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _CapMark extends StatelessWidget {
  const _CapMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 128,
        height: 128,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF071026).withValues(alpha: .68),
          border: Border.all(color: AppColors.blue.withValues(alpha: .8)),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: .18),
              blurRadius: 22,
            ),
          ],
        ),
        child: const Icon(
          Icons.school_outlined,
          color: AppColors.cyan,
          size: 72,
        ),
      ),
    );
  }
}
