/// Renders the real board from a captured server response and writes PNGs,
/// so the board can be inspected without signing in to the app.
///
/// Run: flutter test test/features/visual_tutor/board_screenshot_test.dart
/// Output: build/board_shots/*.png
library;
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/data/models/visual_tutor_models.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/board_pagination.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The board area on the phone layout the student was testing with.
  const boardSize = Size(430, 460);
  final shotKey = GlobalKey();

  List<VisualTutorBoardActionEntity> liveActions() {
    final turn = VisualTutorTurnResponseModel.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
              File(
                'test/features/visual_tutor/fixtures/worked_solution_turn.json',
              ).readAsStringSync(),
            )
            as Map,
      ),
    );
    return turn.boardActions;
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final boundary =
          shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('build/board_shots')
        ..createSync(recursive: true);
      File('${directory.path}/$name.png')
        ..createSync()
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  setUpAll(() async {
    // Flutter's test font paints every glyph as a filled box. Load a real
    // system face under the families the board asks for so the captured
    // images show the words a student reads.
    for (final path in [
      '/System/Library/Fonts/Supplemental/Arial.ttf',
      '/System/Library/Fonts/Helvetica.ttc',
    ]) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final bytes = file.readAsBytesSync().buffer.asByteData();
      for (final family in ['Roboto', 'Noto Sans Khmer', 'Kantumruy Pro', 'Arial']) {
        final loader = FontLoader(family)..addFont(Future.value(bytes));
        await loader.load();
      }
      break;
    }
  });

  testWidgets('capture the board a student sees', (tester) async {
    tester.view.physicalSize = boardSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final actions = liveActions();
    final pages = paginateBoardActions(
      actions: actions,
      viewportHeight: boardSize.height - boardTabsHeight,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: RepaintBoundary(
            key: shotKey,
            child: SizedBox(
              width: boardSize.width,
              height: boardSize.height,
              child: TeachingCanvasBoard(
                variant: 'speaking_writing',
                actions: actions,
                finalAnswerLocked: false,
                reducedMotion: true,
                restored: true,
                useLogicalCanvasScale: true,
                pageViewportHeight: boardSize.height,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await shoot(tester, 'board-1');

    for (var index = 1; index < pages.length && index < 4; index++) {
      await tester.tap(find.byKey(const Key('visual-tutor-board-next')));
      await tester.pump(const Duration(milliseconds: 400));
      await shoot(tester, 'board-${index + 1}');
    }

    // ignore: avoid_print
    print('SHOTS boards=${pages.length} written to build/board_shots');
  });
}
