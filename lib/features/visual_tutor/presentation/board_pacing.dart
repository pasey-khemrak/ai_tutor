import 'dart:math' as math;

import '../domain/entities/visual_tutor_entities.dart';

/// How long the board takes to write each action.
///
/// The teaching plan carries a `duration_ms` per action, but it is authored by
/// a solver or by the planning model, neither of which has seen the rendered
/// board. In practice those values are nominal — 450ms for text, 550ms for an
/// equation — so every action animated for about the same time no matter how
/// much was being written. A real hand does the opposite: it moves at a roughly
/// constant speed, so longer working simply takes longer.
///
/// [BoardPacing.teacher] derives the duration from how much ink an action
/// actually puts on the board, and treats the authored value as a floor so a
/// plan that deliberately asks for a slow reveal still gets one. It never
/// speeds an action up.
///
/// [BoardPacing.verbatim] plays the authored duration exactly. It exists for
/// tests that pin the timeline's sequencing, where a content-derived duration
/// would make the assertions depend on the sample text.
class BoardPacing {
  const BoardPacing.teacher() : _contentDriven = true;
  const BoardPacing.verbatim() : _contentDriven = false;

  final bool _contentDriven;

  /// Below this an action reads as a flash rather than a stroke.
  static const _minMs = 200;

  /// Above this the board feels stalled, however much was written. A single
  /// action holding the lesson for longer than this is a planning fault, not
  /// something to render faithfully.
  static const _maxMs = 4500;

  /// The bounds the board applied before pacing existed. Verbatim keeps them
  /// so a timeline test that authors 160ms still measures exactly 160ms.
  static const _verbatimMinMs = 160;
  static const _verbatimMaxMs = 1800;

  /// Milliseconds per Latin character of prose.
  ///
  /// This is not tuned to match the speed of the narration reading the same
  /// sentence. It does not have to be: the board already waits for a step's
  /// narration to finish before starting the next one, so the voice sets the
  /// rhythm whenever it is available. This rate only governs how the writing
  /// itself looks — and, when the student has muted the tutor or the voice
  /// service is down, how long they wait to read it. A long step lands around
  /// three seconds, which reads as a deliberate hand rather than a paste.
  static const _msPerProseChar = 18.0;

  /// Milliseconds per glyph of mathematics.
  ///
  /// Maths is drawn more deliberately than prose, and there are far fewer
  /// glyphs in an equation than characters in the LaTeX that describes it.
  static const _msPerEquationGlyph = 95.0;

  /// Khmer glyphs stack consonants, vowels and diacritics into one cluster, so
  /// an equal character count is materially more ink than Latin.
  static const _khmerWeight = 1.7;

  static const _msPerTableRow = 300.0;
  static const _tableBaseMs = 400.0;

  Duration resolve(VisualTutorBoardActionEntity action) {
    final authored = math.max(0, action.durationMs);
    if (!_contentDriven) {
      final requested = authored > 0 ? authored : _fallbackFor(action.type);
      return Duration(
        milliseconds: requested.clamp(_verbatimMinMs, _verbatimMaxMs).toInt(),
      );
    }

    // Pacing only ever gives an action more room. A plan asking for a long
    // pause on a short line is expressing intent, so it wins.
    final natural = _naturalMsFor(action);
    final chosen = math.max(authored.toDouble(), natural);
    final floored = chosen <= 0 ? _fallbackFor(action.type).toDouble() : chosen;
    return Duration(
      milliseconds: floored.round().clamp(_minMs, _maxMs).toInt(),
    );
  }

  /// The time this action's own content is worth, ignoring what was authored.
  double _naturalMsFor(VisualTutorBoardActionEntity action) {
    switch (action.type) {
      case 'write_text':
      case 'student_task':
        return _weightedLength(action.text ?? '') * _msPerProseChar;
      case 'write_equation':
        return _equationGlyphs(action.latex ?? '') * _msPerEquationGlyph;
      case 'show_table':
        final rows = action.metadata['rows'];
        final count = rows is List ? rows.length : 0;
        return _tableBaseMs + count * _msPerTableRow;
      default:
        // Lines, arrows, circles and strike-throughs are single movements of
        // the arm. Their length is geometry, not content, so the authored
        // duration already describes them.
        return 0;
    }
  }

  /// Character count, weighting Khmer clusters above Latin.
  static double _weightedLength(String value) {
    var total = 0.0;
    for (final rune in value.runes) {
      // Khmer occupies U+1780..U+17FF. Never use a word-boundary or per-word
      // measure here: Khmer is written without spaces between words.
      final isKhmer = rune >= 0x1780 && rune <= 0x17FF;
      total += isKhmer ? _khmerWeight : 1.0;
    }
    return total;
  }

  /// Roughly how many marks a LaTeX string puts on the board.
  ///
  /// `\frac`, `\left` and their braces are instructions to the renderer rather
  /// than strokes, so counting raw characters would pace an equation by how
  /// verbosely it was spelled instead of by how much of it is visible.
  static double _equationGlyphs(String latex) {
    if (latex.isEmpty) return 0;
    var working = latex;
    // A command is one visible mark at most (\int, \sum, \to, \alpha), and
    // often none at all (\left, \frac, \displaystyle).
    working = working.replaceAll(RegExp(r'\\(left|right|displaystyle|,|;|!)'), '');
    working = working.replaceAll(RegExp(r'\\[a-zA-Z]+'), 'x');
    working = working.replaceAll(RegExp(r'[{}$\s]'), '');
    return _weightedLength(working);
  }

  static int _fallbackFor(String type) {
    return switch (type) {
      'write_text' => 360,
      'write_equation' => 520,
      'draw_line' || 'draw_arrow' => 420,
      'circle' || 'cross_out' => 560,
      _ => 420,
    };
  }
}
