import 'package:ai_tutor/features/visual_tutor/presentation/visual_tutor_board_snapshot.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const action = <String, dynamic>{
    'id': 'step-1-equation',
    'type': 'write_equation',
    'sequence_index': 1,
    'latex': '2x + 5 = 15',
    'duration_ms': 520,
  };

  test(
    'migrates a schema-v1 snapshot into the current safe representation',
    () {
      final snapshot = VisualTutorBoardSnapshot.tryFromJson({
        'schema_version': 1,
        'session_id': 'session-1',
        'board_state_id': 'board-1',
        'actions': [action],
        'board_state': {
          'visible_action_ids': ['step-1-equation'],
          'hidden_action_ids': [],
          'faded_action_ids': [],
          'focused_action_id': 'step-1-equation',
        },
        'viewport': {'scale': 1.5, 'translate_x': 12, 'translate_y': -8},
      });

      expect(snapshot, isNotNull);
      expect(snapshot!.schemaVersion, 2);
      expect(snapshot.actions.single.id, 'step-1-equation');
      expect(snapshot.visibleActionIds, ['step-1-equation']);
      expect(snapshot.hiddenActionIds, isEmpty);
      expect(snapshot.fadedActionIds, isEmpty);
      expect(snapshot.focusedActionId, 'step-1-equation');
      expect(snapshot.playheadIndex, 0);
      expect(snapshot.playbackPaused, isFalse);
      expect(snapshot.viewport.scale, 1.5);
    },
  );

  test('preserves a versioned snapshot including isolated student ink', () {
    final snapshot = VisualTutorBoardSnapshot.tryFromJson({
      'schema_version': 2,
      'session_id': 'session-1',
      'board_state_id': 'board-1',
      'actions': [action],
      'board_state': {
        'visible_action_ids': ['step-1-equation'],
        'hidden_action_ids': [],
        'faded_action_ids': [],
        'focused_action_id': 'step-1-equation',
      },
      'student_ink': [
        {
          'points': [
            {'x': 10.0, 'y': 20.0},
            {'x': 14.0, 'y': 25.0},
          ],
        },
      ],
      'playback': {'playhead_index': 1, 'is_paused': true},
      'viewport': {'scale': 1.25, 'translate_x': 8.0, 'translate_y': -4.0},
    });

    expect(snapshot, isNotNull);
    expect(snapshot!.schemaVersion, 2);
    expect(snapshot.studentInk, hasLength(1));
    expect(snapshot.studentInk.single.points, hasLength(2));
    expect(snapshot.playheadIndex, 1);
    expect(snapshot.playbackPaused, isTrue);
    expect(snapshot.viewport.translateX, 8.0);
  });

  test('fails closed for corrupt snapshots without blocking session parsing', () {
    expect(
      VisualTutorBoardSnapshot.tryFromJson({
        'schema_version': 999,
        'actions': 'not-a-list',
      }),
      isNull,
    );
    expect(
      VisualTutorBoardSnapshot.tryFromJson({
        'schema_version': 2,
        'session_id': 'recoverable-session',
        'board_state_id': 'board-1',
        'actions': [action],
        'student_ink': [
          {'points': 'not-a-list'},
        ],
      }),
      isNull,
      reason:
          'Callers can ignore a corrupt device snapshot and restore the authoritative board.',
    );
  });

  testWidgets(
    'restores saved ink and viewport without silently replaying the lesson',
    (tester) async {
      final snapshot = VisualTutorBoardSnapshot.tryFromJson({
        'schema_version': 2,
        'session_id': 'session-1',
        'board_state_id': 'board-1',
        'actions': [action],
        'board_state': {
          'visible_action_ids': ['step-1-equation'],
        },
        'student_ink': [
          {
            'points': [
              {'x': 10.0, 'y': 20.0},
              {'x': 14.0, 'y': 25.0},
            ],
          },
        ],
        'playback': {'playhead_index': 1, 'is_paused': true},
        'viewport': {'scale': 1.25, 'translate_x': 8.0, 'translate_y': -4.0},
      });
      final persisted = <VisualTutorBoardSnapshot>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 360,
              child: TeachingCanvasBoard(
                actions: [snapshot!.actions.single],
                finalAnswerLocked: true,
                restored: true,
                sessionId: 'session-1',
                boardStateId: 'board-1',
                snapshot: snapshot,
                onSnapshotChanged: persisted.add,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('teaching-board-action-step-1-equation')),
        findsOneWidget,
      );
      expect(
        persisted,
        isEmpty,
        reason:
            'Restore must render from the snapshot instead of starting a new timeline.',
      );

      // Reset emits a fresh local snapshot. It must retain student ink while
      // resetting only the student-controlled viewport.
      await tester.tap(find.byKey(const Key('visual-tutor-board-reset-fit')));
      await tester.pump();
      expect(persisted, isNotEmpty);
      expect(persisted.last.studentInk.single.points, hasLength(2));
      expect(persisted.last.viewport.scale, 1);
      expect(persisted.last.playbackPaused, isFalse);
    },
  );
}
