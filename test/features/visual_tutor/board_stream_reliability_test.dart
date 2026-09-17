import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/live_board_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('typed stream duration wins over legacy metadata timing', () {
    const action = VisualTutorBoardActionEntity(
      id: 'typed-duration',
      type: 'write_text',
      text: 'Write this deliberately.',
      durationMs: 760,
      metadata: {'duration_ms': 200},
    );

    expect(streamedBoardRevealDelayMs(action), 760);
  });

  test('legacy metadata timing remains a bounded fallback', () {
    const action = VisualTutorBoardActionEntity(
      id: 'legacy-duration',
      type: 'write_text',
      text: 'Legacy timing.',
      metadata: {'duration_ms': 920},
    );

    expect(streamedBoardRevealDelayMs(action), 920);
  });

  test('stale stream events cannot queue onto a newer board', () {
    expect(
      isCurrentStreamedBoardAction(
        requestBoardVersion: 4,
        currentBoardVersion: 5,
        eventBoardVersion: 5,
        eventBaseBoardVersion: 4,
      ),
      isFalse,
    );
  });

  test(
    'current stream events queue only for their requested board version',
    () {
      expect(
        isCurrentStreamedBoardAction(
          requestBoardVersion: 4,
          currentBoardVersion: 4,
          eventBoardVersion: 5,
          eventBaseBoardVersion: 4,
        ),
        isTrue,
      );
    },
  );

  test('a completed turn keeps the identity of the board it streamed', () {
    // Same actions, arriving a second time inside turn_complete.
    expect(
      boardIdentityMustChange(
        renderedActionIds: const ['step-1', 'step-2'],
        nextActionIds: const ['step-1', 'step-2', 'task-3'],
      ),
      isFalse,
    );
  });

  test('a board that drops what is written starts a new board', () {
    expect(
      boardIdentityMustChange(
        renderedActionIds: const ['old-1'],
        nextActionIds: const ['new-1', 'new-2'],
      ),
      isTrue,
    );
  });
}
