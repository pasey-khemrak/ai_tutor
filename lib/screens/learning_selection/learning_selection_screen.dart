import 'package:flutter/material.dart';

import '../../core/adaptive_colors.dart';
import '../../core/app_colors.dart';
import '../../shared/state_widgets/app_empty_state.dart';
import '../../shared/state_widgets/app_error_state.dart';
import '../../shared/state_widgets/app_loading_state.dart';
import 'learning_selection_repository.dart';

class LearningSelectionScreen extends StatelessWidget {
  LearningSelectionScreen({
    super.key,
    LearningSelectionRepository? repository,
    required this.onJoinClass,
  }) : repository = repository ?? buildDefaultLearningSelectionRepository();

  final LearningSelectionRepository repository;
  final ValueChanged<LearningContext> onJoinClass;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LearningSelectionData>(
      future: repository.loadSelectionData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppLoadingState(message: 'Loading classes...');
        }

        if (snapshot.hasError) {
          return AppErrorState(
            message: 'Could not load subjects and topics.',
            onRetry: () {},
          );
        }

        final data = snapshot.data;
        if (data == null || data.isEmpty) {
          return const AppEmptyState(
            title: 'No classes available',
            message: 'Subjects and topics will appear here after setup.',
            icon: Icons.class_outlined,
          );
        }

        return _LearningSelectionContent(data: data, onJoinClass: onJoinClass);
      },
    );
  }
}

class _LearningSelectionContent extends StatefulWidget {
  const _LearningSelectionContent({
    required this.data,
    required this.onJoinClass,
  });

  final LearningSelectionData data;
  final ValueChanged<LearningContext> onJoinClass;

  @override
  State<_LearningSelectionContent> createState() =>
      _LearningSelectionContentState();
}

class _LearningSelectionContentState extends State<_LearningSelectionContent> {
  late int _selectedGrade = widget.data.grades.first;
  late String _selectedSubject = widget.data.subjects.first.name;
  late String _selectedTopic = widget.data.subjects.first.topics.first;

  LearningSubject get _currentSubject {
    return widget.data.subjects.firstWhere(
      (subject) => subject.name == _selectedSubject,
      orElse: () => widget.data.subjects.first,
    );
  }

  void _selectSubject(String subjectName) {
    final subject = widget.data.subjects.firstWhere(
      (subject) => subject.name == subjectName,
      orElse: () => widget.data.subjects.first,
    );
    setState(() {
      _selectedSubject = subject.name;
      _selectedTopic = subject.topics.first;
    });
  }

  void _joinClass() {
    widget.onJoinClass(
      LearningContext(
        grade: _selectedGrade,
        subject: _selectedSubject,
        topic: _selectedTopic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('learning-selection-scroll-view'),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose your class',
            style: TextStyle(
              color: AdaptiveColors.text(context),
              fontSize: 26,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a grade, subject, and topic before joining Visual Tutor.',
            style: TextStyle(
              color: AdaptiveColors.muted(context),
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          _SelectionPanel(
            title: 'Grade',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final grade in widget.data.grades)
                  _ChoicePill(
                    key: Key('grade-$grade-option'),
                    label: 'Grade $grade',
                    selected: _selectedGrade == grade,
                    onTap: () => setState(() => _selectedGrade = grade),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SelectionPanel(
            title: 'Subject',
            child: Column(
              children: [
                for (final subject in widget.data.subjects)
                  _SubjectCard(
                    key: Key('subject-${subject.name}-option'),
                    subject: subject,
                    selected: _selectedSubject == subject.name,
                    onTap: () => _selectSubject(subject.name),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SelectionPanel(
            title: 'Topic',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final topic in _currentSubject.topics)
                  _ChoicePill(
                    key: Key('topic-$topic-option'),
                    label: topic,
                    selected: _selectedTopic == topic,
                    onTap: () => setState(() => _selectedTopic = topic),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('join-class-button'),
            onPressed: _joinClass,
            icon: const Icon(Icons.school_rounded),
            label: const Text('Join Class'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionPanel extends StatelessWidget {
  const _SelectionPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdaptiveColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdaptiveColors.line(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AdaptiveColors.text(context),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.blue.withValues(alpha: .22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.cyan : AdaptiveColors.line(context),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.cyan : AdaptiveColors.subtle(context),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    super.key,
    required this.subject,
    required this.selected,
    required this.onTap,
  });

  final LearningSubject subject;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.blue.withValues(alpha: .18)
              : AppColors.answer.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.cyan : AdaptiveColors.line(context),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.functions_rounded,
              color: selected ? AppColors.cyan : AdaptiveColors.muted(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
                    style: TextStyle(
                      color: AdaptiveColors.text(context),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${subject.topics.length} topics available',
                    style: TextStyle(
                      color: AdaptiveColors.muted(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.cyan),
          ],
        ),
      ),
    );
  }
}
