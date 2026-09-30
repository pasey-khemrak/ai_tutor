/// The board should write at a human pace, not a uniform one.
///
/// Every action used to animate for whatever `duration_ms` the plan happened to
/// carry — 450ms for text, 550ms for an equation — regardless of how much was
/// being written. So `x = 2` and a five-term factorisation took exactly the
/// same time, which is the one thing a real hand never does: a teacher's speed
/// is roughly constant per character, so longer working simply takes longer.
///
/// These durations are also what the narration has to fit inside, because the
/// tutor speaks each step while that step is being written. Writing a sentence
/// in 450ms when saying it aloud takes three seconds is what made the board
/// feel like it was racing the voice.
library;

import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/board_pacing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const teacher = BoardPacing.teacher();
  const verbatim = BoardPacing.verbatim();

  VisualTutorBoardActionEntity text(String value, {int durationMs = 450}) {
    return VisualTutorBoardActionEntity(
      id: 'a',
      type: 'write_text',
      text: value,
      durationMs: durationMs,
    );
  }

  VisualTutorBoardActionEntity equation(String latex, {int durationMs = 550}) {
    return VisualTutorBoardActionEntity(
      id: 'a',
      type: 'write_equation',
      latex: latex,
      durationMs: durationMs,
    );
  }

  group('teacher pacing', () {
    test('a longer sentence takes longer to write than a short one', () {
      final short = teacher.resolve(text('Substitute.'));
      final long = teacher.resolve(
        text(
          'Substitute x = 2 into the simplified expression and read off the '
          'value the function approaches.',
        ),
      );

      expect(
        long,
        greaterThan(short * 3),
        reason:
            'writing speed must scale with how much is written, or long '
            'working races past at the same speed as a single word',
      );
    });

    test('a long step is deliberate without being a wait', () {
      // 98 characters, which is a typical step of a worked solution. It used
      // to appear in 450ms, effectively pasted. It should now read as a hand
      // writing it — but not as slowly as the sentence is spoken, because the
      // board separately waits for the narration to finish before moving on.
      final step = teacher.resolve(
        text(
          'Factor the numerator as a difference of two squares, then cancel '
          'the common factor with x minus 2.',
        ),
      );

      expect(step.inMilliseconds, greaterThanOrEqualTo(1200));
      expect(step.inMilliseconds, lessThanOrEqualTo(3000));
    });

    test('an equation is paced by its glyphs, not its LaTeX source', () {
      // Same visible maths, but one is spelled with more LaTeX machinery.
      final plain = teacher.resolve(equation('x^2 - 4'));
      final wrapped = teacher.resolve(equation(r'\left( x^{2} - 4 \right)'));

      // \left, \right and the braces are instructions, not strokes, so the two
      // should land close together rather than one taking twice as long.
      final ratio = wrapped.inMilliseconds / plain.inMilliseconds;
      expect(ratio, lessThan(2.0), reason: 'LaTeX commands are not glyphs');
    });

    test('a long equation takes longer than a short one', () {
      final short = teacher.resolve(equation('x = 2'));
      final long = teacher.resolve(
        equation(r'\lim_{x \to 2} \frac{x^{2} - 4}{x - 2} = \frac{0}{0}'),
      );
      expect(long, greaterThan(short));
    });

    test('Khmer is written more slowly per character than Latin', () {
      // Khmer glyphs stack and carry diacritics, so an equal character count
      // is more ink. The Khmer line here is deliberately shorter in characters
      // than the English one it mirrors.
      final english = teacher.resolve(text('Substitute the value'));
      final khmer = teacher.resolve(text('ជំនួសតម្លៃ'));

      final perCharEnglish = english.inMilliseconds / 20;
      final perCharKhmer = khmer.inMilliseconds / 10;
      expect(perCharKhmer, greaterThan(perCharEnglish));
    });

    test('a single gesture is not paced by character count', () {
      // A circle round a term is one movement of the arm, however long the
      // term underneath happens to be.
      const circle = VisualTutorBoardActionEntity(
        id: 'a',
        type: 'circle',
        durationMs: 560,
      );
      final resolved = teacher.resolve(circle);
      expect(resolved.inMilliseconds, greaterThanOrEqualTo(560));
      expect(resolved.inMilliseconds, lessThanOrEqualTo(1600));
    });

    test('pathological input cannot stall the board', () {
      final huge = teacher.resolve(text('x' * 20000));
      expect(huge.inMilliseconds, lessThanOrEqualTo(4500));
    });

    test('an empty action still takes a readable beat', () {
      final empty = teacher.resolve(text('', durationMs: 0));
      expect(empty.inMilliseconds, greaterThan(0));
    });

    test('a deliberately slow authored duration is never sped up', () {
      // A plan that asks for a long, dramatic reveal gets it; pacing only ever
      // gives an action more room, never less.
      final slow = teacher.resolve(text('Answer', durationMs: 3000));
      expect(slow.inMilliseconds, greaterThanOrEqualTo(3000));
    });
  });

  group('verbatim pacing', () {
    test('honours the authored duration exactly', () {
      expect(
        verbatim.resolve(text('Any length of sentence at all', durationMs: 160)),
        const Duration(milliseconds: 160),
      );
      expect(
        verbatim.resolve(equation('x = 2', durationMs: 900)),
        const Duration(milliseconds: 900),
      );
    });

    test('falls back to a per-type default when none is authored', () {
      expect(
        verbatim.resolve(text('hello', durationMs: 0)).inMilliseconds,
        greaterThan(0),
      );
    });
  });
}
