import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  String _subject = 'Mathematics';

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _saveGoal() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Learning goal added.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF080D19), Color(0xFF09101E), Color(0xFF10112A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SizedBox.square(
                      dimension: 34,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFFDDE4FF),
                          size: 19,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Add Goal',
                      style: TextStyle(
                        color: Color(0xFFDDE4FF),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Create Learning Goal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set a focused target for your next study session.',
                  style: TextStyle(
                    color: Color(0xFF96A0CF),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 28),
                _GoalTextField(
                  label: 'Goal Title',
                  hint: 'Master derivatives',
                  icon: Icons.flag_outlined,
                  controller: _titleController,
                ),
                const SizedBox(height: 18),
                _SubjectSelector(
                  selectedSubject: _subject,
                  onChanged: (value) => setState(() => _subject = value),
                ),
                const SizedBox(height: 18),
                _GoalTextField(
                  label: 'Goal Details',
                  hint: 'Describe what you want to improve',
                  icon: Icons.notes_rounded,
                  controller: _detailsController,
                  minLines: 4,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _saveGoal,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Goal'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalTextField extends StatelessWidget {
  const _GoalTextField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.minLines = 1,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF96A0CF),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: minLines == 1 ? 1 : null,
          style: const TextStyle(
            color: Color(0xFFDDE4FF),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF747A9B),
              fontWeight: FontWeight.w700,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF8BA0FF), size: 18),
            filled: true,
            fillColor: const Color(0xFF090D19).withValues(alpha: .9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.blue.withValues(alpha: .32),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.blue, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubjectSelector extends StatelessWidget {
  const _SubjectSelector({
    required this.selectedSubject,
    required this.onChanged,
  });

  final String selectedSubject;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const subjects = ['Mathematics', 'Physics', 'English'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subject',
          style: TextStyle(
            color: Color(0xFF96A0CF),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final subject in subjects)
              ChoiceChip(
                label: Text(subject),
                selected: selectedSubject == subject,
                onSelected: (_) => onChanged(subject),
                labelStyle: TextStyle(
                  color: selectedSubject == subject
                      ? Colors.white
                      : const Color(0xFF8BA0FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
                selectedColor: AppColors.blue,
                backgroundColor: AppColors.blue.withValues(alpha: .16),
                side: BorderSide(color: AppColors.blue.withValues(alpha: .28)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
