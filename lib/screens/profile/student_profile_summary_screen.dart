import 'package:flutter/material.dart';

import '../../core/adaptive_colors.dart';
import '../../core/app_colors.dart';
import '../../shared/state_widgets/app_error_state.dart';
import '../../shared/state_widgets/app_loading_state.dart';
import '../../shared/student_design_system.dart';
import 'student_profile_repository.dart';

class StudentProfileSummaryScreen extends StatefulWidget {
  const StudentProfileSummaryScreen({
    super.key,
    required this.onSetup,
    required this.onLogout,
    this.repository,
  });
  final VoidCallback onSetup;
  final VoidCallback onLogout;
  final StudentProfileRepository? repository;
  @override
  State<StudentProfileSummaryScreen> createState() =>
      _StudentProfileSummaryScreenState();
}

class _StudentProfileSummaryScreenState
    extends State<StudentProfileSummaryScreen> {
  late final StudentProfileRepository _repository;
  late Future<StudentProfileView> _future;
  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? StudentProfileRepository();
    _future = _repository.loadProfile();
  }

  void _reload() => setState(() => _future = _repository.loadProfile());
  @override
  Widget build(BuildContext context) => FutureBuilder<StudentProfileView>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const AppLoadingState(message: 'Loading your profile...');
      }
      if (snapshot.hasError) {
        return AppErrorState(
          message: 'Could not load your profile.',
          onRetry: _reload,
        );
      }
      final profile = snapshot.data!;
      return StudentPage(
        maxWidth: StudentSpace.readableWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StudentSectionTitle('Profile'),
            const SizedBox(height: StudentSpace.lg),
            StudentCard(
              accent: AppColors.cyan,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.cyan.withValues(alpha: .14),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.cyan,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName.isEmpty
                              ? 'Student'
                              : profile.displayName,
                          style: TextStyle(
                            color: AdaptiveColors.text(context),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.isComplete
                              ? '${_gradeLabel(profile.gradeLevelId)} • ${profile.preferredLanguage == 'km' ? 'ខ្មែរ' : 'English'}'
                              : 'Learning profile not complete',
                          style: const TextStyle(color: Color(0xFFB4BEF2)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: StudentSpace.lg),
            StudentCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your learning setup',
                    style: TextStyle(
                      color: AdaptiveColors.text(context),
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (profile.subjects.isEmpty)
                    const Text(
                      'No subjects selected yet.',
                      style: TextStyle(color: AppColors.muted),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.subjects
                          .map((item) => Chip(label: Text(item)))
                          .toList(),
                    ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    key: const Key('profile-complete-learning-profile'),
                    onPressed: widget.onSetup,
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(
                      profile.isComplete
                          ? 'Update learning setup'
                          : 'Complete learning profile',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: StudentSpace.lg),
            OutlinedButton.icon(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      );
    },
  );
}

String _gradeLabel(String id) =>
    id.startsWith('grade-') ? 'Grade ${id.substring(6)}' : id;
