import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/live_board_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects unknown and malformed board actions before rendering', () {
    expect(
      isValidBoardAction(
        const VisualTutorBoardActionEntity(id: 'bad', type: 'remote_widget'),
      ),
      isFalse,
    );
    expect(
      isValidBoardAction(
        const VisualTutorBoardActionEntity(
          id: 'empty-equation',
          type: 'write_equation',
        ),
      ),
      isFalse,
    );
    expect(
      isValidBoardAction(
        const VisualTutorBoardActionEntity(
          id: 'safe-equation',
          type: 'write_equation',
          latex: '2x + 5 = 15',
        ),
      ),
      isTrue,
    );
  });
  const base = [
    VisualTutorBoardActionEntity(
      id: 'a',
      type: 'write_equation',
      latex: '3x - 9 = 12',
      sequenceIndex: 0,
    ),
    VisualTutorBoardActionEntity(
      id: 'b',
      type: 'write_equation',
      latex: '3x = 21',
      sequenceIndex: 1,
    ),
  ];

  VisualTutorBoardActionEntity patch(
    String id,
    String type, {
    String? targetId,
    Map<String, dynamic> metadata = const {},
    String? latex,
  }) {
    return VisualTutorBoardActionEntity(
      id: id,
      type: type,
      targetId: targetId,
      latex: latex,
      metadata: metadata,
    );
  }

  test('applies add update highlight fade focus hide reveal remove safely', () {
    final hidden = applyVisualTutorBoardPatch(base, [
      patch('highlight-a', 'highlight', targetId: 'a'),
      patch('fade-a', 'fade_previous', targetId: 'a'),
      patch('focus-b', 'focus', targetId: 'b'),
      patch('hide-a', 'hide', targetId: 'a'),
      patch('missing', 'highlight', targetId: 'missing-target'),
      patch('add-c', 'write_equation', latex: 'x = 7'),
    ]);

    final a = hidden.firstWhere((action) => action.id == 'a');
    final b = hidden.firstWhere((action) => action.id == 'b');
    expect(a.hidden, isTrue);
    expect(a.metadata['highlighted'], isTrue);
    expect(a.metadata['faded'], isTrue);
    expect(b.metadata['focused'], isTrue);
    expect(hidden.any((action) => action.id == 'add-c'), isTrue);

    final revealed = applyVisualTutorBoardPatch(hidden, [
      patch('reveal-a', 'reveal', targetId: 'a'),
      patch(
        'update-b',
        'update',
        targetId: 'b',
        latex: '3x = 21',
        metadata: {'patch_op': 'update', 'focused': true},
      ),
      patch('remove-c', 'erase', targetId: 'add-c'),
    ]);

    final revealedA = revealed.firstWhere((action) => action.id == 'a');
    expect(revealedA.hidden, isFalse);
    expect(revealedA.metadata['highlighted'], isFalse);
    expect(revealedA.metadata['faded'], isFalse);
    expect(revealed.any((action) => action.id == 'add-c'), isFalse);
  });

  test('focus clears previous focus unless multi focus is requested', () {
    final first = applyVisualTutorBoardPatch(base, [
      patch('focus-a', 'focus', targetId: 'a'),
      patch('focus-b', 'focus', targetId: 'b'),
    ]);

    expect(
      first.firstWhere((action) => action.id == 'a').metadata['focused'],
      isFalse,
    );
    expect(
      first.firstWhere((action) => action.id == 'b').metadata['focused'],
      isTrue,
    );

    final multi = applyVisualTutorBoardPatch(first, [
      patch(
        'focus-a-again',
        'focus',
        targetId: 'a',
        metadata: {'multi_focus': true},
      ),
    ]);

    expect(
      multi.firstWhere((action) => action.id == 'a').metadata['focused'],
      isTrue,
    );
    expect(
      multi.firstWhere((action) => action.id == 'b').metadata['focused'],
      isTrue,
    );
  });
}
