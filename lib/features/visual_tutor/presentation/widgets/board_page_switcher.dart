import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../board_pagination.dart';
import '../visual_tutor_design.dart';

/// Moves between the boards a long solution is written across.
///
/// Deliberately compact and centred at the top of the board: the bottom of the
/// board is covered by the chat panel, and the corners are taken by the pen
/// tools and the playback controls.
class BoardPageSwitcher extends StatelessWidget {
  const BoardPageSwitcher({
    super.key,
    required this.pages,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<BoardPage> pages;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final current = pages[currentIndex.clamp(0, pages.length - 1)];
    final pageLabel = localizations.boardPageOf(current.index + 1, pages.length);

    return Semantics(
      container: true,
      label: pageLabel,
      child: DecoratedBox(
        key: const Key('visual-tutor-board-pages'),
        decoration: BoxDecoration(
          color: VisualTutorColors.shell.withValues(alpha: .82),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: VisualTutorColors.cyan.withValues(alpha: .5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BoardArrowButton(
              keyValue: 'visual-tutor-board-previous',
              icon: Icons.chevron_left_rounded,
              tooltip: localizations.previousBoard,
              onTap: currentIndex > 0 ? () => onSelected(currentIndex - 1) : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                pageLabel,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.40,
                  fontWeight: FontWeight.w600,
                  color: VisualTutorColors.cyan,
                  fontFamilyFallback: VisualTutorTypography.fontFallback,
                ),
              ),
            ),
            BoardArrowButton(
              keyValue: 'visual-tutor-board-next',
              icon: Icons.chevron_right_rounded,
              tooltip: localizations.nextBoard,
              onTap: currentIndex < pages.length - 1
                  ? () => onSelected(currentIndex + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class BoardArrowButton extends StatelessWidget {
  const BoardArrowButton({
    super.key,
    required this.keyValue,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final String keyValue;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      child: IconButton(
        key: Key(keyValue),
        onPressed: onTap,
        tooltip: tooltip,
        iconSize: 20,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        visualDensity: VisualDensity.compact,
        icon: Icon(
          icon,
          color: enabled
              ? VisualTutorColors.cyan
              : VisualTutorColors.textMuted.withValues(alpha: .35),
        ),
      ),
    );
  }
}
