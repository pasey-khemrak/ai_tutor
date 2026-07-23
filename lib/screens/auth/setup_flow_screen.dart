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
  String _subject = 'math';

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
            padding: const EdgeInsets.fromLTRB(28, 34, 28, 28),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: _step == 0
                  ? _GradeStep(
                      key: const ValueKey('grade'),
                      selectedGrade: _grade,
                      onSelect: (value) => setState(() => _grade = value),
                      onContinue: _continue,
                    )
                  : _SubjectStep(
                      key: const ValueKey('subject'),
                      selectedSubject: _subject,
                      onSelect: (value) => setState(() => _subject = value),
                      onContinue: _continue,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradeStep extends StatelessWidget {
  const _GradeStep({
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
            _OptionCard(
              selected: selectedGrade == grade,
              leading: Text(
                '$grade',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
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
          const SizedBox(height: 10),
          _ContinueButton(onPressed: onContinue),
        ],
      ),
    );
  }
}

class _SubjectStep extends StatelessWidget {
  const _SubjectStep({
    super.key,
    required this.selectedSubject,
    required this.onSelect,
    required this.onContinue,
  });

  final String selectedSubject;
  final ValueChanged<String> onSelect;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _SetupContent(
      title: 'ជ្រើសរើស មុខវិជ្ជា',
      subtitle: 'ជ្រើសមុខវិជ្ជាដែលអ្នកចង់រៀន',
      child: Column(
        children: [
          _OptionCard(
            selected: selectedSubject == 'math',
            leading: const Icon(Icons.functions_rounded, color: Colors.black),
            activeColor: AppColors.blue,
            title: 'គណិតវិទ្យា',
            subtitle: 'អនុគមន៍ សមីការ ត្រីកោណមាត្រ និងលំហាត់ថ្នាក់ទី 12',
            onTap: () => onSelect('math'),
          ),
          const SizedBox(height: 14),
          _OptionCard(
            selected: selectedSubject == 'physics',
            leading: const Icon(Icons.science_rounded, color: Colors.black),
            activeColor: AppColors.cyan,
            title: 'រូបវិទ្យា',
            subtitle: 'មេកានិច អគ្គិសនី រលក និងលំហាត់គណនា',
            onTap: () => onSelect('physics'),
          ),
          const SizedBox(height: 14),
          _OptionCard(
            selected: selectedSubject == 'english',
            leading: const Text(
              'ENG',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            activeColor: const Color(0xFF8B4CFF),
            title: 'អង់គ្លេស',
            subtitle: 'Vocabulary, Grammar and any General Lesson',
            onTap: () => onSelect('english'),
          ),
          const SizedBox(height: 24),
          _ContinueButton(onPressed: onContinue),
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
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        const _CapMark(),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF8793C3),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 34),
        child,
      ],
    );
  }
}

class _CapMark extends StatelessWidget {
  const _CapMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 98,
        height: 98,
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
        child: Icon(Icons.school_outlined, color: AppColors.cyan, size: 54),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
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
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? activeColor : activeColor.withValues(alpha: .72),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
              child: leading,
            ),
            const SizedBox(width: 13),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8793C3),
                      fontSize: 9.5,
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
              size: 19,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Continue',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
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
