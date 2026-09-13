import 'package:flutter/material.dart';

import '../../core/adaptive_colors.dart';
import '../../core/app_colors.dart';
import '../../shared/student_design_system.dart';
import 'student_profile_repository.dart';

class StudentProfileSetupSheet extends StatefulWidget {
  const StudentProfileSetupSheet({
    super.key,
    required this.onCompleted,
    this.repository,
  });
  final VoidCallback onCompleted;
  final StudentProfileRepository? repository;
  @override
  State<StudentProfileSetupSheet> createState() =>
      _StudentProfileSetupSheetState();
}

class _StudentProfileSetupSheetState extends State<StudentProfileSetupSheet> {
  late final StudentProfileRepository _repository;
  String? _gradeLevelId;
  String _language = 'en';
  final Set<String> _subjects = {};
  bool _saving = false;
  String? _error;
  late Future<({List<CatalogGrade> grades, List<CatalogSubject> subjects})>
  _catalogFuture;
  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? StudentProfileRepository();
    _catalogFuture = _loadCatalog();
  }

  Future<({List<CatalogGrade> grades, List<CatalogSubject> subjects})>
  _loadCatalog() async {
    final grades = await _repository.loadGrades();
    final subjects = await _repository.loadSubjects();
    return (grades: grades, subjects: subjects);
  }

  Future<void> _save() async {
    if (_gradeLevelId == null || _subjects.isEmpty) {
      setState(() => _error = 'Choose your grade and at least one subject.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repository.completeSetup(
        StudentProfileSetup(
          gradeLevelId: _gradeLevelId!,
          subjectIds: _subjects.toList(growable: false),
          preferredLanguage: _language,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCompleted();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'We could not save your learning profile. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({List<CatalogGrade> grades, List<CatalogSubject> subjects})>(
      future: _catalogFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(StudentSpace.lg),
            child: Center(
              child: SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          );
        }
        if (snapshot.hasError || snapshot.data!.grades.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(StudentSpace.lg),
            child: Text(
              'We could not load the available grades. Please try again.',
              style: TextStyle(color: AdaptiveColors.text(context)),
            ),
          );
        }
        return _buildForm(context, snapshot.data!.grades, snapshot.data!.subjects);
      },
    );
  }

  Widget _buildForm(
    BuildContext context,
    List<CatalogGrade> grades,
    List<CatalogSubject> allSubjects,
  ) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(StudentSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete your learning profile',
                style: TextStyle(
                  color: AdaptiveColors.text(context),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose what you are studying so Rean can show the right published lessons and practice.',
                style: TextStyle(color: Color(0xFFB4BEF2), height: 1.4),
              ),
              const SizedBox(height: 20),
              Text(
                'Grade',
                style: TextStyle(
                  color: AdaptiveColors.text(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: grades
                    .map(
                      (grade) => ChoiceChip(
                        label: Text(grade.gradeName),
                        selected: _gradeLevelId == grade.gradeLevelId,
                        onSelected: (_) => setState(() {
                          _gradeLevelId = grade.gradeLevelId;
                          _subjects.clear();
                        }),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              Text(
                'Language',
                style: TextStyle(
                  color: AdaptiveColors.text(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('English'),
                    selected: _language == 'en',
                    onSelected: (_) => setState(() => _language = 'en'),
                  ),
                  ChoiceChip(
                    label: const Text('ខ្មែរ'),
                    selected: _language == 'km',
                    onSelected: (_) => setState(() => _language = 'km'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Subjects',
                style: TextStyle(
                  color: AdaptiveColors.text(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (_gradeLevelId == null)
                const Text(
                  'Select a grade first.',
                  style: TextStyle(color: AppColors.muted),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allSubjects
                      .map(
                        (subject) => FilterChip(
                          label: Text(subject.subjectName),
                          selected: _subjects.contains(subject.subjectId),
                          onSelected: (selected) => setState(
                            () => selected
                                ? _subjects.add(subject.subjectId)
                                : _subjects.remove(subject.subjectId),
                          ),
                        ),
                      )
                      .toList(),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFFF8B8B)),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  key: const Key('profile-setup-save'),
                  onPressed: _saving || grades.isEmpty ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save learning profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
