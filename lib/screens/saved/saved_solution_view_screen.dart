import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localizations.dart';
import '../../features/saved_solutions/saved_solution.dart';
import '../../features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import '../../features/visual_tutor/presentation/widgets/live_teaching_board.dart';
import '../../shared/student_design_system.dart';

/// A saved board, reopened read-only.
///
/// It paints the stored actions directly through the board widget with
/// `restored: true`, so the whole solution appears at once. Nothing here calls
/// the planner, the solver or the LLM, and it never goes through the tutor
/// screen's board adoption path — so a reopened solution cannot disturb a live
/// lesson's board identity.
class SavedSolutionViewScreen extends StatelessWidget {
  const SavedSolutionViewScreen({super.key, required this.solution});

  final SavedSolution solution;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(solution.topic.isEmpty ? l10n.savedSolutionsTitle : solution.topic),
        actions: [
          IconButton(
            key: const Key('saved-export-button'),
            tooltip: l10n.copySolutionAction,
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: () => _copy(context, l10n),
          ),
        ],
      ),
      // The board paints into fixed constraints, as it does everywhere else, so
      // the header scrolls with it rather than the board being asked to size
      // itself inside an unbounded column.
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 900
              ? StudentSpace.xl
              : StudentSpace.lg;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              StudentSpace.lg,
              horizontal,
              StudentSpace.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  solution.problemText,
                  style: StudentStyle.title(context, 18),
                ),
                const SizedBox(height: StudentSpace.xs),
                Text(
                  l10n.savedSolutionReadOnly,
                  style: StudentStyle.body(context, size: 12),
                ),
                const SizedBox(height: StudentSpace.md),
                SizedBox(
                  width: constraints.maxWidth - horizontal * 2,
                  height: (constraints.maxHeight * .78).clamp(320.0, 900.0),
                  child: LiveTeachingBoard(
                    actions: solution.boardActions,
                    // The answer was already revealed when this was saved, and
                    // the board is complete, so nothing is withheld or
                    // animating.
                    finalAnswerLocked: false,
                    restored: true,
                    transitionsEnabled: false,
                    verification: VisualTutorVerificationEntity(
                      status: solution.verificationStatus,
                      verified: solution.verified,
                      studentMessage: solution.answerSummary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _copy(BuildContext context, AppLocalizations l10n) async {
    await Clipboard.setData(ClipboardData(text: solution.toShareText()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copySolutionConfirmation)),
    );
  }
}
