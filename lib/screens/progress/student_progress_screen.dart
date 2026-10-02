import 'package:flutter/material.dart';

import '../../core/adaptive_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../shared/state_widgets/app_error_state.dart';
import '../../shared/state_widgets/app_loading_state.dart';
import '../../shared/student_design_system.dart';
import '../dashboard/dashboard_repository.dart';

/// What the student has mastered and what still needs work.
///
/// Reads the same `/progress/dashboard` summary as Home. Home shows a bar per
/// topic; this screen groups those topics by subject and explains what the bar
/// is made of, then routes the weakest topic straight into practice.
class StudentProgressScreen extends StatefulWidget {
  const StudentProgressScreen({
    super.key,
    this.repository,
    this.onPracticeTopic,
    this.onStartLearning,
  });

  final DashboardRepository? repository;

  /// Called with the topic and subject ids the student wants to practise.
  final void Function(String topicId, String? subjectId)? onPracticeTopic;

  /// Offered when there is nothing to show yet.
  final VoidCallback? onStartLearning;

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  late final DashboardRepository _repository;
  late Future<StudentDashboardData?> _future;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? buildDefaultDashboardRepository();
    _future = _repository.loadDashboard();
  }

  void _reload() {
    final next = _repository.loadDashboard();
    setState(() {
      _future = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.progressTitle)),
      body: FutureBuilder<StudentDashboardData?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingState();
          }
          if (snapshot.hasError) {
            return Center(
              key: const Key('progress-error'),
              child: AppErrorState(
                message: l10n.dashboardLoadError,
                onRetry: _reload,
              ),
            );
          }
          final data = snapshot.data;
          if (data == null || data.subjectProgress.isEmpty) {
            return _EmptyProgress(onStart: widget.onStartLearning);
          }
          return _ProgressBody(
            data: data,
            onPracticeTopic: widget.onPracticeTopic,
          );
        },
      ),
    );
  }
}

class _EmptyProgress extends StatelessWidget {
  const _EmptyProgress({this.onStart});
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StudentPage(
      key: const Key('progress-empty'),
      child: StudentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 34,
              color: AdaptiveColors.muted(context),
            ),
            const SizedBox(height: StudentSpace.md),
            Text(l10n.progressEmptyTitle, style: StudentStyle.title(context, 19)),
            const SizedBox(height: StudentSpace.xs),
            Text(l10n.progressEmptyBody, style: StudentStyle.body(context)),
            const SizedBox(height: StudentSpace.md),
            FilledButton(
              key: const Key('progress-empty-start-button'),
              onPressed: onStart,
              child: Text(l10n.startLearningAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({required this.data, this.onPracticeTopic});
  final StudentDashboardData data;
  final void Function(String topicId, String? subjectId)? onPracticeTopic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bySubject = <String, List<SubjectProgress>>{};
    for (final item in data.subjectProgress) {
      bySubject.putIfAbsent(item.subject, () => []).add(item);
    }

    return StudentPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.progressSubtitle, style: StudentStyle.body(context)),
          const SizedBox(height: StudentSpace.lg),
          StudentStatRow(
            key: const Key('progress-stats-row'),
            tiles: [
              StudentStatTile(
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFFF6B39),
                value: l10n.number(data.learningStreakDays),
                label: l10n.dailyStreak,
              ),
              StudentStatTile(
                icon: Icons.menu_book_rounded,
                color: const Color(0xFF12B5CB),
                value: l10n.number(data.lessonsCompleted),
                label: l10n.lessonsCompletedStat,
              ),
              StudentStatTile(
                icon: Icons.fact_check_outlined,
                color: const Color(0xFF8A52FF),
                value: data.averageQuizScore == null
                    ? '—'
                    : l10n.percentValue(data.averageQuizScore!),
                label: l10n.averageScoreStat,
              ),
            ],
          ),
          if (data.weakTopic != null) ...[
            const SizedBox(height: StudentSpace.lg),
            _WeakTopicCard(
              topic: data.weakTopic!,
              onPractice: onPracticeTopic,
              subjectId: _subjectIdForTopic(data, data.weakTopic!.topicId),
            ),
          ],
          const SizedBox(height: StudentSpace.lg),
          for (final subject in bySubject.keys) ...[
            StudentSectionHeader(
              localizedSubjectName(l10n, subject),
              icon: subjectVisual(subject).icon,
            ),
            for (final topic in bySubject[subject]!) ...[
              _TopicProgressCard(topic: topic),
              const SizedBox(height: StudentSpace.sm),
            ],
            const SizedBox(height: StudentSpace.md),
          ],
        ],
      ),
    );
  }

  String? _subjectIdForTopic(StudentDashboardData data, String? topicId) {
    if (topicId == null) return null;
    for (final item in data.subjectProgress) {
      if (item.topicId == topicId) return item.subjectId;
    }
    return null;
  }
}

class _WeakTopicCard extends StatelessWidget {
  const _WeakTopicCard({
    required this.topic,
    required this.subjectId,
    this.onPractice,
  });
  final WeakTopic topic;
  final String? subjectId;
  final void Function(String topicId, String? subjectId)? onPractice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final topicId = topic.topicId;
    return StudentCard(
      accent: const Color(0xFFFF6B6B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudentPill(
            label: l10n.needsPracticeMost,
            color: const Color(0xFFFF6B6B),
            icon: Icons.priority_high_rounded,
          ),
          const SizedBox(height: StudentSpace.sm),
          Text(topic.title, style: StudentStyle.title(context, 18)),
          const SizedBox(height: 4),
          Text(topic.reason, style: StudentStyle.body(context)),
          if (topicId != null && topicId.isNotEmpty) ...[
            const SizedBox(height: StudentSpace.md),
            FilledButton.icon(
              key: const Key('progress-practice-button'),
              onPressed: onPractice == null
                  ? null
                  : () => onPractice!(topicId, subjectId),
              icon: const Icon(Icons.fitness_center_rounded, size: 18),
              label: Text(l10n.practiceThisTopic),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopicProgressCard extends StatelessWidget {
  const _TopicProgressCard({required this.topic});
  final SubjectProgress topic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = (topic.progress * 100).round();
    return StudentCard(
      key: Key('progress-topic-${topic.topicId ?? topic.topic}'),
      padding: const EdgeInsets.all(StudentSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  topic.topic,
                  style: StudentStyle.title(context, 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: StudentSpace.xs),
              Text(
                l10n.percentValue(percent),
                style: StudentStyle.title(context, 15),
              ),
            ],
          ),
          const SizedBox(height: StudentSpace.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: topic.progress,
              minHeight: 8,
              backgroundColor: AdaptiveColors.muted(
                context,
              ).withValues(alpha: .18),
              valueColor: AlwaysStoppedAnimation<Color>(
                _readinessColor(topic.readiness),
              ),
            ),
          ),
          const SizedBox(height: StudentSpace.sm),
          Wrap(
            spacing: StudentSpace.xs,
            runSpacing: StudentSpace.xs,
            children: [
              if (_readinessLabel(l10n, topic.readiness) != null)
                StudentPill(
                  label: _readinessLabel(l10n, topic.readiness)!,
                  color: _readinessColor(topic.readiness),
                ),
              Text(
                topic.totalAnswers == 0
                    ? l10n.noAnswersYet
                    : l10n.answersCorrect(
                        topic.correctAnswers,
                        topic.totalAnswers,
                      ),
                style: StudentStyle.body(context, size: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _readinessColor(String? readiness) => switch (readiness) {
    'ready' => const Color(0xFF10B981),
    'building' => const Color(0xFFF59E0B),
    'needs_practice' => const Color(0xFFFF6B6B),
    _ => const Color(0xFF12B5CB),
  };

  static String? _readinessLabel(AppLocalizations l10n, String? readiness) =>
      switch (readiness) {
        'ready' => l10n.readinessReady,
        'building' => l10n.readinessBuilding,
        'needs_practice' => l10n.readinessNeedsPractice,
        _ => null,
      };
}
