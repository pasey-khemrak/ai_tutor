import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'semantic_board_layout.dart';
import '../domain/entities/visual_tutor_entities.dart';

/// A board continues onto the next one as soon as the writing no longer fits
/// on it, which is what "the board is full" means to a student.
const double _pagingOverflowFactor = 1;

/// A board smaller than this is scrolled rather than divided.
const double _minimumBoardHeight = 240;

/// Boards are for a long worked solution. An ordinary teaching turn of a few
/// parts stays whole, so a normal lesson is never chopped in half.
const int _minimumSectionsToPage = 4;

/// Height of the board switcher. Every caller must subtract this from the
/// visible height before paginating: if the screen and the board disagree
/// about how much room there is, the screen keeps a tall scrolling canvas
/// while the board splits into pages inside it, and the student is left
/// scrolling through blank paper.
const double boardTabsHeight = 44;

/// One board's worth of teaching, in reading order.
@immutable
class BoardPage {
  const BoardPage({required this.index, required this.actions});

  final int index;
  final List<VisualTutorBoardActionEntity> actions;

  /// What a student sees on the tab: "Board 1".
  String get label => 'Board ${index + 1}';
}

/// Splits a long solution across boards the way a teacher fills one blackboard
/// and starts the next.
///
/// A step is never split: actions sharing a `section_id` move to the next board
/// together, so an explanation can never end up on a different board from the
/// equation it describes. A single step taller than the board keeps its own
/// board rather than disappearing.
List<BoardPage> paginateBoardActions({
  required List<VisualTutorBoardActionEntity> actions,
  required double viewportHeight,
  double viewportWidth = 390,
  TextDirection textDirection = TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  /// The height this content really occupies once laid out at this width.
  /// A width-blind estimate under-counts wrapped explanations, and a board
  /// that is over-filled silently cuts its last step off the bottom.
  double measure(List<VisualTutorBoardActionEntity> candidate) {
    final resolved = SemanticBoardLayout.resolve(
      actions: candidate,
      viewport: Size(viewportWidth, viewportHeight),
      textDirection: textDirection,
      textScaler: textScaler,
    );
    var bottom = 0.0;
    for (final action in resolved) {
      bottom = math.max(bottom, (action.y ?? 0) + (action.height ?? 44));
    }
    return bottom + 16;
  }

  if (actions.isEmpty) return const [];
  // An unbounded height gives no usable budget, and a small board is not worth
  // dividing: splitting it makes many near-empty boards where scrolling a
  // single board reads better.
  if (!viewportHeight.isFinite || viewportHeight < _minimumBoardHeight) {
    return [BoardPage(index: 0, actions: List.unmodifiable(actions))];
  }

  // Only a multi-step solution is paged. A single teaching moment keeps its
  // existing behaviour (one board, scrolled by the screen around it) so short
  // turns are not chopped in half on a landscape phone.
  final sections = actions
      .map((action) => action.sectionId)
      .whereType<String>()
      .toSet();
  final overflows = measure(actions) > viewportHeight * _pagingOverflowFactor;
  if (sections.length < _minimumSectionsToPage || !overflows) {
    return [BoardPage(index: 0, actions: List.unmodifiable(actions))];
  }

  final budget = viewportHeight;
  final groups = _sectionGroups(actions);
  final pages = <List<VisualTutorBoardActionEntity>>[];
  var current = <VisualTutorBoardActionEntity>[];

  for (final group in groups) {
    if (current.isEmpty) {
      current = [...group];
      continue;
    }
    final candidate = [...current, ...group];
    if (measure(candidate) <= budget) {
      current = candidate;
    } else {
      pages.add(current);
      current = [...group];
    }
  }
  if (current.isNotEmpty) pages.add(current);

  return [
    for (var index = 0; index < pages.length; index++)
      BoardPage(index: index, actions: List.unmodifiable(pages[index])),
  ];
}

/// The board showing [actionId], or null when it is not on any board.
int? pageIndexOfAction(List<BoardPage> pages, String? actionId) {
  if (actionId == null) return null;
  for (final page in pages) {
    if (page.actions.any((action) => action.id == actionId)) return page.index;
  }
  return null;
}

List<List<VisualTutorBoardActionEntity>> _sectionGroups(
  List<VisualTutorBoardActionEntity> actions,
) {
  final groups = <List<VisualTutorBoardActionEntity>>[];
  String? openSection;
  for (final action in actions) {
    final section = action.sectionId;
    final continuesGroup =
        groups.isNotEmpty && section != null && section == openSection;
    if (continuesGroup) {
      groups.last.add(action);
    } else {
      groups.add([action]);
    }
    // An action with no section ends the run: the next one starts fresh rather
    // than joining a section it was never part of.
    openSection = section;
  }
  return groups;
}
