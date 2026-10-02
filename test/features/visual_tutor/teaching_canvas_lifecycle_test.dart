import 'dart:io';

import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/board_pacing.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/live_board_state.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const action = VisualTutorBoardActionEntity(
    id: 'lifecycle-step',
    type: 'write_text',
    text: 'Factor the numerator.',
    sequenceIndex: 0,
    durationMs: 600,
  );

  Widget board({
    List<VisualTutorBoardActionEntity> actions = const [action],
    bool disableAnimations = false,
    bool reducedMotion = false,
    double? pageViewportHeight,
    Future<void> Function(VisualTutorBoardActionEntity)? onNarrate,
    ValueChanged<BoardActionDiagnostic>? onActionDiagnostic,
    ValueChanged<String>? onActionCompleted,
  }) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: SizedBox(
            width: 420,
            height: 360,
            child: TeachingCanvasBoard(
              actions: actions,
              finalAnswerLocked: true,
              pacing: const BoardPacing.verbatim(),
              reducedMotion: reducedMotion,
              pageViewportHeight: pageViewportHeight,
              onNarrate: onNarrate,
              onActionDiagnostic: onActionDiagnostic,
              onActionCompleted: onActionCompleted,
            ),
          ),
        ),
      ),
    );
  }

  test('initState does not start context-dependent board synchronization', () {
    final source = File(
      'lib/screens/tutor/tutor_screen.dart',
    ).readAsStringSync();
    final stateStart = source.indexOf('class _TeachingCanvasBoardState');
    final initStart = source.indexOf('void initState()', stateStart);
    final dependenciesStart = source.indexOf(
      'void didChangeDependencies()',
      initStart,
    );
    final initStateSource = source.substring(initStart, dependenciesStart);

    expect(initStateSource, isNot(contains('_syncActions')));
    expect(initStateSource, isNot(contains('_restoreSnapshot')));
  });

  testWidgets(
    'initial synchronization waits until inherited media is available',
    (tester) async {
      await tester.pumpWidget(board());
      await tester.pump();

      expect(
        find.byKey(const Key('teaching-board-action-lifecycle-step')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a reduced-motion dependency change does not replay or outlive the board',
    (tester) async {
      final narrated = <String>[];
      Future<void> narrate(VisualTutorBoardActionEntity action) async {
        narrated.add(action.id);
      }

      await tester.pumpWidget(board(onNarrate: narrate));
      await tester.pump(const Duration(milliseconds: 50));
      expect(narrated, ['lifecycle-step']);

      await tester.pumpWidget(
        board(disableAnimations: true, onNarrate: narrate),
      );
      await tester.pump();

      expect(narrated, ['lifecycle-step']);
      expect(
        find.byKey(const Key('teaching-board-action-lifecycle-step')),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'explicit then inherited reduced motion does not resync a finished action',
    (tester) async {
      final narrated = <String>[];
      final completed = <String>[];
      final visible = <String>[];

      Future<void> narrate(VisualTutorBoardActionEntity action) async {
        narrated.add(action.id);
      }

      void diagnose(BoardActionDiagnostic diagnostic) {
        if (diagnostic.lifecycle == BoardActionLifecycle.visible) {
          visible.add(diagnostic.actionId);
        }
      }

      Widget configuredBoard({
        bool reducedMotion = false,
        bool disableAnimations = false,
      }) {
        return board(
          reducedMotion: reducedMotion,
          disableAnimations: disableAnimations,
          onNarrate: narrate,
          onActionDiagnostic: diagnose,
          onActionCompleted: completed.add,
        );
      }

      await tester.pumpWidget(configuredBoard());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      expect(narrated, ['lifecycle-step']);
      expect(completed, ['lifecycle-step']);
      expect(visible, ['lifecycle-step']);

      await tester.pumpWidget(configuredBoard(reducedMotion: true));
      await tester.pump();
      await tester.pumpWidget(
        configuredBoard(reducedMotion: true, disableAnimations: true),
      );
      await tester.pump();

      expect(narrated, ['lifecycle-step']);
      expect(completed, ['lifecycle-step']);
      expect(visible, ['lifecycle-step']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a non-content resync does not replay a completed marker', (
    tester,
  ) async {
    const marker = VisualTutorBoardActionEntity(
      id: 'lifecycle-pause',
      type: 'pause_marker',
      sequenceIndex: 0,
      durationMs: 200,
    );
    const step = VisualTutorBoardActionEntity(
      id: 'lifecycle-after-pause',
      type: 'write_text',
      text: 'Continue once.',
      sequenceIndex: 1,
      durationMs: 100,
    );
    final queued = <String>[];
    final completed = <String>[];

    void diagnose(BoardActionDiagnostic diagnostic) {
      if (diagnostic.lifecycle == BoardActionLifecycle.queued) {
        queued.add(diagnostic.actionId);
      }
    }

    Widget configuredBoard(double viewportHeight) {
      return board(
        actions: const [marker, step],
        pageViewportHeight: viewportHeight,
        onActionDiagnostic: diagnose,
        onActionCompleted: completed.add,
      );
    }

    await tester.pumpWidget(configuredBoard(320));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump();

    expect(completed, ['lifecycle-after-pause']);
    expect(queued.where((id) => id == marker.id), hasLength(1));

    await tester.pumpWidget(configuredBoard(300));
    await tester.pump();

    expect(completed, ['lifecycle-after-pause']);
    expect(queued.where((id) => id == marker.id), hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
