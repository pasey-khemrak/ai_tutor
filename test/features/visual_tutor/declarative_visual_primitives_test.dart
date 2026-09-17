import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/data/models/visual_tutor_models.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/live_board_state.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/widgets/live_teaching_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget board(List<VisualTutorBoardActionEntity> actions) => MaterialApp(
    theme: AppTheme.dark(),
    home: Scaffold(
      body: SizedBox(
        width: 720,
        height: 600,
        child: LiveTeachingBoard(
          variant: 'speaking_writing',
          finalAnswerLocked: true,
          board: const VisualTutorBoardEntity(type: 'coordinate_graph'),
          actions: actions,
        ),
      ),
    ),
  );

  const primitives = <VisualTutorBoardActionEntity>[
    VisualTutorBoardActionEntity(
      id: 'rectangle',
      type: 'draw_rectangle',
      sequenceIndex: 0,
      x: 12,
      y: 12,
      width: 112,
      height: 58,
    ),
    VisualTutorBoardActionEntity(
      id: 'circle',
      type: 'circle',
      sequenceIndex: 1,
      x: 138,
      y: 12,
      width: 54,
      height: 54,
    ),
    VisualTutorBoardActionEntity(
      id: 'arrow',
      type: 'draw_arrow',
      sequenceIndex: 2,
      x: 12,
      y: 86,
      width: 160,
      height: 34,
      metadata: {'label': 'Next step'},
    ),
    VisualTutorBoardActionEntity(
      id: 'axes',
      type: 'draw_axes',
      sequenceIndex: 3,
      x: 210,
      y: 12,
      width: 180,
      height: 120,
    ),
    VisualTutorBoardActionEntity(
      id: 'point',
      type: 'draw_point',
      sequenceIndex: 4,
      x: 250,
      y: 56,
      width: 20,
      height: 20,
      metadata: {'label': 'A (2, 3)'},
    ),
    VisualTutorBoardActionEntity(
      id: 'number-line',
      type: 'show_number_line',
      sequenceIndex: 5,
      x: 12,
      y: 138,
      width: 378,
      height: 62,
      metadata: {
        'number_line': {
          'min': -3,
          'max': 3,
          'step': 1,
          'labels': ['-3', '0', '3'],
        },
      },
    ),
    VisualTutorBoardActionEntity(
      id: 'table',
      type: 'show_table',
      sequenceIndex: 6,
      x: 12,
      y: 214,
      width: 190,
      height: 96,
      metadata: {
        'table': {
          'columns': ['x', 'y'],
          'rows': [
            [0, 1],
            [1, 3],
          ],
        },
      },
    ),
    VisualTutorBoardActionEntity(
      id: 'annotation',
      type: 'graph_annotation',
      sequenceIndex: 7,
      x: 212,
      y: 220,
      width: 176,
      height: 38,
      text: 'A is above the axis.',
    ),
    VisualTutorBoardActionEntity(
      id: 'source-equation',
      type: 'write_equation',
      sequenceIndex: 8,
      x: 12,
      y: 328,
      width: 376,
      height: 50,
      latex: '2x - 5 = 10',
    ),
    VisualTutorBoardActionEntity(
      id: 'transform',
      type: 'transform_equation',
      sequenceIndex: 9,
      x: 12,
      y: 388,
      width: 376,
      height: 50,
      latex: '2x - 5 + 5 = 10 + 5',
      targetId: 'source-equation',
    ),
  ];

  test('validates bounded safe primitives and keeps legacy actions valid', () {
    for (final action in primitives) {
      expect(isValidBoardAction(action), isTrue, reason: action.id);
    }
    expect(
      isValidBoardAction(
        const VisualTutorBoardActionEntity(
          id: 'legacy-equation',
          type: 'write_equation',
          latex: '2x + 5 = 15',
        ),
      ),
      isTrue,
    );
    expect(
      isValidBoardAction(
        const VisualTutorBoardActionEntity(
          id: 'unsafe',
          type: 'draw_rectangle',
          x: 0,
          y: 0,
          width: 10001,
          height: 20,
        ),
      ),
      isFalse,
    );
  });

  test('normalizes public primitive fields to safe Flutter metadata', () {
    final action = VisualTutorBoardActionModel.fromJson({
      'id': 'arrow',
      'type': 'draw_arrow',
      'sequence_index': 0,
      'x': 10,
      'y': 10,
      'width': 120,
      'height': 30,
      'label': 'Next step',
      'number_line': {'min': -2, 'max': 2, 'step': 1},
      'table': {
        'columns': ['x'],
        'rows': [
          [1],
        ],
      },
    });

    expect(action.metadata['label'], 'Next step');
    expect(action.metadata['number_line'], {'min': -2, 'max': 2, 'step': 1});
    expect(action.metadata['table'], {
      'columns': ['x'],
      'rows': [
        [1],
      ],
    });
  });

  testWidgets(
    'renders declarative shapes, labels, axes, table and equation transformation',
    (tester) async {
      await tester.pumpWidget(board(primitives));

      expect(
        find.byKey(const Key('teaching-board-draw_rectangle-rectangle')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('teaching-board-circle-circle')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('teaching-board-draw_arrow-arrow')),
        findsOneWidget,
      );
      expect(find.text('Next step'), findsOneWidget);
      expect(find.byKey(const Key('teaching-board-axes-axes')), findsOneWidget);
      expect(
        find.byKey(const Key('teaching-board-point-point')),
        findsOneWidget,
      );
      expect(find.text('A (2, 3)'), findsOneWidget);
      expect(
        find.byKey(const Key('teaching-board-number-line-number-line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('teaching-board-table-table')),
        findsOneWidget,
      );
      expect(find.text('x'), findsOneWidget);
      expect(find.text('A is above the axis.'), findsOneWidget);
      expect(
        find.byKey(const Key('teaching-board-action-source-equation')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('teaching-board-action-transform')),
        findsOneWidget,
      );
    },
  );
}
