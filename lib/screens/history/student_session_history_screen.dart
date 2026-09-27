import 'package:flutter/material.dart';

import '../../core/adaptive_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../shared/state_widgets/app_error_state.dart';
import '../../shared/state_widgets/app_loading_state.dart';
import '../../shared/student_design_system.dart';
import '../dashboard/dashboard_repository.dart';

/// Boards the student worked on before, newest first.
///
/// Only activity that carries a tutor session id is listed: a quiz result has
/// nothing to reopen, so offering it would be a dead tap.
class StudentSessionHistoryScreen extends StatefulWidget {
  const StudentSessionHistoryScreen({
    super.key,
    this.repository,
    this.onOpenSession,
    this.onStartLearning,
  });

  final DashboardRepository? repository;

  /// Called with the activity whose board should be reopened.
  final void Function(DashboardActivity session)? onOpenSession;

  /// Offered when the student has no sessions yet.
  final VoidCallback? onStartLearning;

  @override
  State<StudentSessionHistoryScreen> createState() =>
      _StudentSessionHistoryScreenState();
}

class _StudentSessionHistoryScreenState
    extends State<StudentSessionHistoryScreen> {
  late final DashboardRepository _repository;
  late Future<StudentDashboardData?> _future;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? buildDefaultDashboardRepository();
    _future = _repository.loadDashboard();
  }

  void _reload() {
    setState(() => _future = _repository.loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sessionHistoryTitle)),
      body: FutureBuilder<StudentDashboardData?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingState();
          }
          if (snapshot.hasError) {
            return Center(
              key: const Key('history-error'),
              child: AppErrorState(
                message: l10n.dashboardLoadError,
                onRetry: _reload,
              ),
            );
          }
          final sessions = (snapshot.data?.recentActivity ?? const [])
              .where(
                (item) =>
                    item.tutorSessionId != null &&
                    item.tutorSessionId!.trim().isNotEmpty,
              )
              .toList();
          if (sessions.isEmpty) {
            return _EmptyHistory(onStart: widget.onStartLearning);
          }
          return StudentPage(
            maxWidth: StudentSpace.readableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sessionHistorySubtitle,
                  style: StudentStyle.body(context),
                ),
                const SizedBox(height: StudentSpace.lg),
                for (final session in sessions) ...[
                  _SessionCard(
                    session: session,
                    onOpen: widget.onOpenSession,
                  ),
                  const SizedBox(height: StudentSpace.sm),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({this.onStart});
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StudentPage(
      key: const Key('history-empty'),
      child: StudentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.history_rounded,
              size: 34,
              color: AdaptiveColors.muted(context),
            ),
            const SizedBox(height: StudentSpace.md),
            Text(l10n.historyEmptyTitle, style: StudentStyle.title(context, 19)),
            const SizedBox(height: StudentSpace.xs),
            Text(l10n.historyEmptyBody, style: StudentStyle.body(context)),
            const SizedBox(height: StudentSpace.md),
            FilledButton(
              key: const Key('history-empty-start-button'),
              onPressed: onStart,
              child: Text(l10n.startLearningAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, this.onOpen});
  final DashboardActivity session;
  final void Function(DashboardActivity session)? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      key: Key('history-session-${session.tutorSessionId}'),
      borderRadius: StudentRadius.card,
      onTap: onOpen == null ? null : () => onOpen!(session),
      child: StudentCard(
        padding: const EdgeInsets.all(StudentSpace.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF12B5CB).withValues(alpha: .14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.draw_outlined,
                size: 20,
                color: Color(0xFF12B5CB),
              ),
            ),
            const SizedBox(width: StudentSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: StudentStyle.title(context, 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (session.subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      session.subtitle,
                      style: StudentStyle.body(context, size: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    l10n.relativeTime(session.timeLabel),
                    style: StudentStyle.body(context, size: 12),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AdaptiveColors.muted(context),
            ),
          ],
        ),
      ),
    );
  }
}
