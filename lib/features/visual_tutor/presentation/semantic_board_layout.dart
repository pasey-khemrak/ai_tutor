import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../domain/entities/visual_tutor_entities.dart';

const semanticBoardLayoutZones = <String>{
  'problem',
  'working',
  'visual',
  'student_task',
  'reference',
  'feedback',
};

const semanticBoardLayoutFlows = <String>{
  'vertical',
  'horizontal',
  'overlay',
  'diagram',
};

/// Resolves safe, declarative placement into physical board coordinates.
/// Actions with no semantic zone are legacy snapshots and retain their x/y.
class SemanticBoardLayout {
  const SemanticBoardLayout._();

  static List<VisualTutorBoardActionEntity> resolve({
    required List<VisualTutorBoardActionEntity> actions,
    required Size viewport,
    required TextDirection textDirection,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final ordered = [...actions]
      ..sort((a, b) {
        final sequence = a.sequenceIndex.compareTo(b.sequenceIndex);
        return sequence != 0 ? sequence : a.id.compareTo(b.id);
      });
    final isPhone = viewport.width < 600;
    final padding = isPhone ? 20.0 : 28.0;
    final gap = isPhone ? 16.0 : 24.0;
    final primaryWidth =
        (isPhone
                ? math.max(160, viewport.width - padding * 2)
                : math.max(340, viewport.width * .62 - padding))
            .toDouble();
    final secondaryWidth =
        (isPhone
                ? primaryWidth
                : math.max(
                    240,
                    viewport.width - primaryWidth - padding * 2 - gap,
                  ))
            .toDouble();
    final secondaryLeft = isPhone ? padding : padding + primaryWidth + gap;
    var mainCursor = padding;
    var sideCursor = padding;
    var phoneCursor = padding;
    String? previousSection;
    final resolved = <VisualTutorBoardActionEntity>[];
    final resolvedById = <String, VisualTutorBoardActionEntity>{};
    String? horizontalPairKey;
    double? horizontalPairTop;

    for (final action in ordered) {
      final zone = action.layoutZone;
      if (zone == null || !semanticBoardLayoutZones.contains(zone)) {
        resolved.add(action);
        continue;
      }
      final flow = semanticBoardLayoutFlows.contains(action.layoutFlow)
          ? action.layoutFlow!
          : 'vertical';
      final isSecondary = !isPhone && (zone == 'visual' || zone == 'reference');
      final width = isSecondary ? secondaryWidth : primaryWidth;
      final left = isSecondary ? secondaryLeft : padding;
      final sectionBreak =
          previousSection != null &&
          action.sectionId != null &&
          action.sectionId != previousSection;
      if (sectionBreak) {
        if (isPhone) {
          phoneCursor += 28;
        } else if (isSecondary) {
          sideCursor += 28;
        } else {
          mainCursor += 28;
        }
      }
      final baseHeight = _heightFor(
        action,
        width: width,
        textDirection: textDirection,
        textScaler: textScaler,
      );
      final laneCursor = isPhone
          ? phoneCursor
          : (isSecondary ? sideCursor : mainCursor);
      // A two-column pair is useful on a wide board, but a required teaching
      // action must never be pushed off the right edge of a phone. Resolve
      // every semantic flow as one vertical reading column on phone widths.
      final horizontal = !isPhone && flow == 'horizontal';
      final laneKey =
          '${isPhone
              ? 'phone'
              : isSecondary
              ? 'side'
              : 'main'}:'
          '${action.layoutZone}:${action.sectionId ?? ''}';
      final continuesHorizontalPair =
          horizontal &&
          horizontalPairKey == laneKey &&
          horizontalPairTop != null;
      final overlayTarget = flow == 'overlay' && action.targetId != null
          ? resolvedById[action.targetId]
          : null;
      final top =
          overlayTarget?.y ??
          (continuesHorizontalPair ? horizontalPairTop : laneCursor);
      final actionWidth = horizontal ? (width - gap) / 2 : width.toDouble();
      final actionLeft =
          overlayTarget?.x ??
          (horizontal && continuesHorizontalPair
              ? left + actionWidth + gap
              : left);
      final laidOut = action.copyWith(
        x: actionLeft,
        y: top,
        width: overlayTarget?.width ?? actionWidth,
        height: overlayTarget?.height ?? baseHeight,
      );
      resolved.add(laidOut);
      resolvedById[laidOut.id] = laidOut;
      if (horizontal && !continuesHorizontalPair) {
        horizontalPairKey = laneKey;
        horizontalPairTop = top;
      } else {
        if (flow != 'overlay' || overlayTarget == null) {
          final next = top + (laidOut.height ?? baseHeight) + 16;
          if (isPhone) {
            phoneCursor = next;
          } else if (isSecondary) {
            sideCursor = next;
          } else {
            mainCursor = next;
          }
        }
        horizontalPairKey = null;
        horizontalPairTop = null;
      }
      previousSection = action.sectionId ?? previousSection;
    }
    return resolved;
  }

  static double estimatedContentBottom(
    List<VisualTutorBoardActionEntity> actions,
  ) {
    var cursor = 28.0;
    String? previousSection;
    for (final action in actions) {
      if (action.layoutZone == null) {
        cursor = math.max(cursor, (action.y ?? 0) + (action.height ?? 44) + 18);
        continue;
      }
      if (previousSection != null &&
          action.sectionId != null &&
          action.sectionId != previousSection) {
        cursor += 28;
      }
      cursor += _estimatedHeight(action) + 16;
      previousSection = action.sectionId ?? previousSection;
    }
    return cursor;
  }

  static double _heightFor(
    VisualTutorBoardActionEntity action, {
    required double width,
    required TextDirection textDirection,
    required TextScaler textScaler,
  }) {
    if (_isVisual(action)) {
      return action.type == 'show_graph' || action.type == 'plot_function'
          ? math.min(320, math.max(190, width * .62))
          : math.min(260, math.max(110, width * .42));
    }
    final text = action.latex ?? action.text ?? '';
    if (text.isEmpty) return _estimatedHeight(action);
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 19, height: 1.35),
      ),
      textDirection: textDirection,
      textScaler: textScaler,
      // Khmer syllables can use several vertical glyph marks; measuring all
      // lines prevents a semantic board slot from overlapping the following
      // equation or student task on a narrow phone.
      maxLines: null,
    )..layout(maxWidth: math.max(120, width - 12));
    final minimum = action.type == 'student_task' ? 72.0 : 48.0;
    return math
        .max(minimum, painter.height + 18)
        .clamp(minimum, 280)
        .toDouble();
  }

  static double _estimatedHeight(VisualTutorBoardActionEntity action) =>
      _isVisual(action) ? 190 : (action.type == 'student_task' ? 72 : 56);

  static bool _isVisual(VisualTutorBoardActionEntity action) => <String>{
    'show_graph',
    'plot_function',
    'show_table',
    'show_number_line',
    'draw_axes',
    'draw_free_body_diagram',
    'draw_molecule',
    'draw_wave',
  }.contains(action.type);
}
