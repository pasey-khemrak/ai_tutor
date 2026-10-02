import 'package:flutter/material.dart';

import '../../core/adaptive_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../features/saved_solutions/saved_solution.dart';
import '../../features/saved_solutions/saved_solutions_repository.dart';
import '../../shared/state_widgets/app_error_state.dart';
import '../../shared/state_widgets/app_loading_state.dart';
import '../../shared/student_design_system.dart';
import 'saved_solution_view_screen.dart';

/// The boards a student chose to keep, newest first.
class SavedSolutionsScreen extends StatefulWidget {
  const SavedSolutionsScreen({
    super.key,
    this.repository,
    this.onStartLearning,
  });

  final SavedSolutionsRepository? repository;
  final VoidCallback? onStartLearning;

  @override
  State<SavedSolutionsScreen> createState() => _SavedSolutionsScreenState();
}

class _SavedSolutionsScreenState extends State<SavedSolutionsScreen> {
  late final SavedSolutionsRepository _repository;
  late Future<List<SavedSolution>> _future;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SavedSolutionsRepository();
    _future = _repository.loadAll();
  }

  void _reload() {
    final next = _repository.loadAll();
    setState(() {
      _future = next;
    });
  }

  Future<void> _confirmRemove(SavedSolution solution) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.removeSavedSolutionPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('saved-remove-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.removeSavedSolution),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.remove(solution.id);
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.savedSolutionsTitle)),
      body: FutureBuilder<List<SavedSolution>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingState();
          }
          if (snapshot.hasError) {
            return Center(
              key: const Key('saved-error'),
              child: AppErrorState(
                message: l10n.savedSolutionsLoadError,
                onRetry: _reload,
              ),
            );
          }
          final items = snapshot.data ?? const <SavedSolution>[];
          if (items.isEmpty) {
            return _EmptySaved(onStart: widget.onStartLearning);
          }
          return StudentPage(
            maxWidth: StudentSpace.readableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.savedSolutionsSubtitle,
                  style: StudentStyle.body(context),
                ),
                const SizedBox(height: StudentSpace.lg),
                for (final item in items) ...[
                  _SavedCard(
                    solution: item,
                    onOpen: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SavedSolutionViewScreen(solution: item),
                      ),
                    ),
                    onRemove: () => _confirmRemove(item),
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

class _EmptySaved extends StatelessWidget {
  const _EmptySaved({this.onStart});
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StudentPage(
      key: const Key('saved-empty'),
      child: StudentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 34,
              color: AdaptiveColors.muted(context),
            ),
            const SizedBox(height: StudentSpace.md),
            Text(l10n.savedEmptyTitle, style: StudentStyle.title(context, 19)),
            const SizedBox(height: StudentSpace.xs),
            Text(l10n.savedEmptyBody, style: StudentStyle.body(context)),
            const SizedBox(height: StudentSpace.md),
            FilledButton(
              key: const Key('saved-empty-start-button'),
              onPressed: onStart,
              child: Text(l10n.startLearningAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedCard extends StatelessWidget {
  const _SavedCard({
    required this.solution,
    required this.onOpen,
    required this.onRemove,
  });
  final SavedSolution solution;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visual = subjectVisual(solution.subject);
    return InkWell(
      key: Key('saved-solution-${solution.id}'),
      borderRadius: StudentRadius.card,
      onTap: onOpen,
      child: StudentCard(
        padding: const EdgeInsets.all(StudentSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: visual.color.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(visual.icon, size: 18, color: visual.color),
                ),
                const SizedBox(width: StudentSpace.sm),
                Expanded(
                  child: Text(
                    solution.problemText,
                    style: StudentStyle.title(context, 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  key: Key('saved-remove-${solution.id}'),
                  tooltip: l10n.removeSavedSolution,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: StudentSpace.xs),
            Text(
              '${localizedSubjectName(l10n, solution.subject)} · ${solution.topic}',
              style: StudentStyle.body(context, size: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (solution.answerSummary.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                solution.answerSummary,
                style: StudentStyle.body(context, size: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: StudentSpace.xs),
            Wrap(
              spacing: StudentSpace.xs,
              runSpacing: StudentSpace.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StudentPill(
                  label: solution.verified
                      ? l10n.verifiedAnswer
                      : l10n.unverifiedAnswer,
                  color: solution.verified
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                  icon: solution.verified
                      ? Icons.verified_rounded
                      : Icons.info_outline_rounded,
                ),
                Text(
                  _dateLabel(l10n, solution.savedAt),
                  style: StudentStyle.body(context, size: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _dateLabel(AppLocalizations l10n, DateTime savedAt) {
    final now = DateTime.now();
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(savedAt.year, savedAt.month, savedAt.day)).inDays;
    if (days <= 0) return l10n.today;
    if (days == 1) return l10n.yesterday;
    return l10n.daysAgo(days);
  }
}
