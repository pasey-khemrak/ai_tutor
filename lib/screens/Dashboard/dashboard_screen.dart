import 'package:flutter/material.dart';

import '../../core/adaptive_colors.dart';
import '../../core/app_colors.dart';
import '../../shared/state_widgets/app_empty_state.dart';
import '../../shared/state_widgets/app_error_state.dart';
import '../../shared/state_widgets/app_loading_state.dart';
import 'dashboard_repository.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({
    super.key,
    DashboardRepository? repository,
    required this.onResumeLearning,
    this.onResumeLearningWithData,
  }) : repository = repository ?? buildDefaultDashboardRepository();

  final DashboardRepository repository;
  final VoidCallback onResumeLearning;
  final ValueChanged<StudentDashboardData>? onResumeLearningWithData;

  @override
  Widget build(BuildContext context) {
    return _DashboardLoader(
      repository: repository,
      onResumeLearning: onResumeLearning,
      onResumeLearningWithData: onResumeLearningWithData,
    );
  }
}

class _DashboardLoader extends StatefulWidget {
  const _DashboardLoader({
    required this.repository,
    required this.onResumeLearning,
    required this.onResumeLearningWithData,
  });

  final DashboardRepository repository;
  final VoidCallback onResumeLearning;
  final ValueChanged<StudentDashboardData>? onResumeLearningWithData;

  @override
  State<_DashboardLoader> createState() => _DashboardLoaderState();
}

class _DashboardLoaderState extends State<_DashboardLoader> {
  late Future<StudentDashboardData?> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = widget.repository.loadDashboard();
  }

  void _retry() {
    setState(() {
      _dashboardFuture = widget.repository.loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StudentDashboardData?>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppLoadingState(message: 'Loading dashboard...');
        }

        if (snapshot.hasError) {
          return AppErrorState(
            message: 'Could not load your dashboard.',
            onRetry: _retry,
          );
        }

        final data = snapshot.data;
        if (data == null || data.isEmpty) {
          return const AppEmptyState(
            title: 'No learning activity yet',
            message: 'Start a tutor session to see your progress here.',
            icon: Icons.school_outlined,
          );
        }

        return _DashboardContent(
          data: data,
          onResumeLearning: () {
            final handler = widget.onResumeLearningWithData;
            if (handler == null) {
              widget.onResumeLearning();
            } else {
              handler(data);
            }
          },
        );
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data, required this.onResumeLearning});

  final StudentDashboardData data;
  final VoidCallback onResumeLearning;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('dashboard-scroll-view'),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WelcomeCard(data: data, onResumeLearning: onResumeLearning),
          const SizedBox(height: 14),
          _SummaryGrid(data: data),
          const SizedBox(height: 14),
          if (data.completedPractice > 0) ...[
            _Panel(
              child: Text(
                '${data.completedPractice} practice ${data.completedPractice == 1 ? 'set' : 'sets'} completed',
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (data.weakTopic != null) ...[
            _WeakTopicCard(topic: data.weakTopic!),
            const SizedBox(height: 14),
          ],
          if (data.practiceRecommendations.isNotEmpty) ...[
            _PracticeRecommendations(items: data.practiceRecommendations),
            const SizedBox(height: 14),
          ],
          _ProgressSection(progress: data.subjectProgress),
          const SizedBox(height: 14),
          _RecentActivitySection(activities: data.recentActivity),
        ],
      ),
    );
  }
}

class _PracticeRecommendations extends StatelessWidget {
  const _PracticeRecommendations({required this.items});
  final List<PracticeRecommendation> items;
  @override
  Widget build(BuildContext context) => _Section(
    title: 'Recommended practice',
    child: Column(
      children: [
        for (final item in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.auto_awesome_outlined,
              color: AppColors.cyan,
            ),
            title: Text(item.topic),
            subtitle: Text(item.reason),
          ),
      ],
    ),
  );
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.data, required this.onResumeLearning});

  final StudentDashboardData data;
  final VoidCallback onResumeLearning;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${data.studentName}',
            style: TextStyle(
              color: AdaptiveColors.text(context),
              fontSize: 24,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.learningGoal == null
                ? 'Ready to continue learning?'
                : 'Goal: ${data.learningGoal}',
            style: TextStyle(
              color: AdaptiveColors.muted(context),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('dashboard-resume-learning-button'),
            onPressed: onResumeLearning,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(data.resumeTitle),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.resumeSubtitle,
            style: TextStyle(
              color: AdaptiveColors.muted(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.data});

  final StudentDashboardData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 620;
        final cards = [
          _MetricCard(
            icon: Icons.grade_rounded,
            label: 'Grade',
            value: data.gradeLabel,
          ),
          _MetricCard(
            icon: Icons.menu_book_rounded,
            label: 'Subjects',
            value: data.subjects.join(', '),
          ),
          _MetricCard(
            icon: Icons.local_fire_department_rounded,
            label: 'Streak',
            value: '${data.learningStreakDays} days',
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }

        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              cards[i],
            ],
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.cyan, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AdaptiveColors.muted(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AdaptiveColors.text(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeakTopicCard extends StatelessWidget {
  const _WeakTopicCard({required this.topic});

  final WeakTopic topic;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      borderColor: AppColors.peach.withValues(alpha: .28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.peach),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weak topic',
                  style: TextStyle(
                    color: AdaptiveColors.muted(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  topic.title,
                  style: TextStyle(
                    color: AdaptiveColors.text(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  topic.reason,
                  style: TextStyle(
                    color: AdaptiveColors.subtle(context),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: Text(topic.actionLabel)),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.progress});

  final List<SubjectProgress> progress;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Subject progress',
      child: Column(
        children: [
          for (var i = 0; i < progress.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _ProgressRow(progress: progress[i]),
          ],
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.progress});

  final SubjectProgress progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress.progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${progress.subject} • ${progress.topic}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AdaptiveColors.text(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.progress,
            minHeight: 8,
            backgroundColor: AppColors.line,
            color: AppColors.cyan,
          ),
        ),
      ],
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.activities});

  final List<DashboardActivity> activities;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Recent activity',
      child: Column(
        children: [
          for (var i = 0; i < activities.length; i++) ...[
            if (i > 0) const Divider(height: 22, color: AppColors.line),
            _ActivityRow(activity: activities[i]),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final DashboardActivity activity;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.history_rounded, color: AppColors.cyan, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                style: TextStyle(
                  color: AdaptiveColors.text(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activity.subtitle,
                style: TextStyle(
                  color: AdaptiveColors.muted(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          activity.timeLabel,
          style: TextStyle(
            color: AdaptiveColors.muted(context),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _Panel(
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

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AdaptiveColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? AdaptiveColors.line(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
