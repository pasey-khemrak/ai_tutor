import 'dart:convert';
import 'dart:io';

import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/data/models/visual_tutor_models.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  VisualTutorTurnResponseModel loadTurn() {
    return VisualTutorTurnResponseModel.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
              File(
                'test/features/visual_tutor/fixtures/demo/demo_limits_en.json',
              ).readAsStringSync(),
            )
            as Map,
      ),
    );
  }

  Widget board(Size size) => MaterialApp(
    locale: const Locale('en'),
    theme: AppTheme.dark(),
    home: Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: TeachingCanvasBoard(
          actions: loadTurn().boardActions,
          finalAnswerLocked: false,
          reducedMotion: true,
          restored: true,
          useLogicalCanvasScale: true,
          pageViewportHeight: size.height,
        ),
      ),
    ),
  );

  Future<void> pumpAt(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(board(Size(width, 640)));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('previous and next expose exactly one semantic button each', (
    tester,
  ) async {
    await pumpAt(tester, 375);

    final semanticButtons = find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.button == true,
      description: 'Semantics widgets with the button role',
    );
    for (final (key, label) in const [
      ('visual-tutor-board-previous', 'Previous board'),
      ('visual-tutor-board-next', 'Next board'),
    ]) {
      final control = find.byKey(Key(key));
      final ancestors = find
          .ancestor(of: control, matching: semanticButtons)
          .evaluate()
          .length;
      final descendants = find
          .descendant(of: control, matching: semanticButtons)
          .evaluate()
          .length;
      expect(
        ancestors + descendants,
        1,
        reason: '$label must not expose nested duplicate button roles',
      );
    }
  });

  testWidgets('page position is announced once without visible-label echo', (
    tester,
  ) async {
    await pumpAt(tester, 375);

    final label = tester
        .getSemantics(find.byKey(const Key('visual-tutor-board-pages')))
        .label;
    expect(label, matches(RegExp(r'^Board \d+ of \d+$')));
  });

  testWidgets('reduced motion exposes play/pause as disabled', (tester) async {
    await pumpAt(tester, 375);

    final playPause = find.byKey(const Key('visual-tutor-board-play-pause'));
    final semanticAncestor = find.ancestor(
      of: playPause,
      matching: find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.button == true,
      ),
    );
    expect(semanticAncestor, findsOneWidget);
    final semantics = tester.widget<Semantics>(semanticAncestor);
    expect(semantics.properties.enabled, isFalse);
  });

  for (final width in <double>[320, 344, 375]) {
    testWidgets(
      '${width.toInt()}px keeps every critical whiteboard control usable',
      (tester) async {
        await pumpAt(tester, width);

        const controlKeys = <String>[
          'visual-tutor-board-previous',
          'visual-tutor-board-next',
          'visual-tutor-board-replay',
          'visual-tutor-board-jump-current',
          'visual-tutor-board-play-pause',
          'visual-tutor-board-reset-fit',
          'student-ink-pen',
          'student-ink-erase',
          'student-ink-undo',
          'student-ink-redo',
          'student-ink-clear',
        ];
        final surface = Rect.fromLTWH(0, 0, width, 640);
        for (final key in controlKeys) {
          final finder = find.byKey(Key(key));
          expect(finder, findsOneWidget, reason: '$key must remain available');
          final rect = tester.getRect(finder);
          expect(rect.width, greaterThanOrEqualTo(44), reason: '$key width');
          expect(rect.height, greaterThanOrEqualTo(44), reason: '$key height');
          expect(
            surface.contains(rect.topLeft) &&
                surface.contains(rect.bottomRight - const Offset(.01, .01)),
            isTrue,
            reason:
                '$key must stay inside the ${width.toInt()}px surface: $rect',
          );
        }

        final pager = tester.getRect(
          find.byKey(const Key('visual-tutor-board-pages')),
        );
        final playback = Rect.fromPoints(
          tester
              .getRect(find.byKey(const Key('visual-tutor-board-replay')))
              .topLeft,
          tester
              .getRect(find.byKey(const Key('visual-tutor-board-play-pause')))
              .bottomRight,
        );
        expect(
          pager.overlaps(playback),
          isFalse,
          reason:
              'pager $pager and playback $playback overlap at ${width.toInt()}px',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
