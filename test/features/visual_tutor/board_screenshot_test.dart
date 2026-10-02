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
import 'package:ai_tutor/features/visual_tutor/presentation/semantic_board_layout.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/widgets/live_teaching_board.dart';
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
    // system face for Latin plus the bundled Kantumruy Pro faces for Khmer
    // so captured images match what a student reads on the board.
    for (final path in [
      '/System/Library/Fonts/Supplemental/Arial.ttf',
      '/System/Library/Fonts/Helvetica.ttc',
    ]) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final bytes = file.readAsBytesSync().buffer.asByteData();
      for (final family in [
        'Roboto',
        'Arial',
        'KaTeX_Main',
        'KaTeX_Math',
        'KaTeX_Size1',
        'KaTeX_Size2',
        'KaTeX_Size3',
        'KaTeX_Size4',
        'KaTeX_AMS',
        'KaTeX_Caligraphic',
        'KaTeX_Fraktur',
        'KaTeX_SansSerif',
        'KaTeX_Script',
        'KaTeX_Typewriter',
      ]) {
        final loader = FontLoader(family)..addFont(Future.value(bytes));
        await loader.load();
      }
      break;
    }

    // MaterialIcons, or toolbar and switcher controls paint as filled boxes.
    for (final path in [
      '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]) {
      final file = File(path);
      if (file.existsSync()) {
        final loader = FontLoader('MaterialIcons')
          ..addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
        await loader.load();
      }
    }

    // KaTeX faces shipped with flutter_math_fork so LaTeX equations render real math.
    final katex = Directory(
      '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
      'flutter_math_fork-0.7.4/lib/katex_fonts/fonts',
    );
    if (katex.existsSync()) {
      for (final file in katex.listSync().whereType<File>()) {
        if (!file.path.endsWith('.ttf')) continue;
        final family = file.uri.pathSegments.last.split('-').first;
        final bytes = file.readAsBytesSync().buffer.asByteData();
        for (final name in [family, 'packages/flutter_math_fork/$family']) {
          final loader = FontLoader(name)..addFont(Future.value(bytes));
          await loader.load();
        }
      }
    }

    final khmerFiles = [
      File('assets/fonts/Kantumruy-Light.ttf'),
      File('assets/fonts/Kantumruy-Regular.ttf'),
      File('assets/fonts/Kantumruy-Bold.ttf'),
    ].where((f) => f.existsSync()).toList();
    if (khmerFiles.isNotEmpty) {
      for (final family in ['Kantumruy Pro', 'Noto Sans Khmer']) {
        final loader = FontLoader(family);
        for (final f in khmerFiles) {
          loader.addFont(Future.value(f.readAsBytesSync().buffer.asByteData()));
        }
        await loader.load();
      }
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

  testWidgets('capture Khmer limit worked solution boards', (tester) async {
    const khmerPath =
        '/Users/macbookpro/.gemini/antigravity/brain/e5cff947-9764-430b-9926-25037738d796/scratch/khmer_limit_turn1.json';
    final file = File(khmerPath);
    if (!file.existsSync()) return;

    tester.view.physicalSize = boardSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final turn = VisualTutorTurnResponseModel.fromJson(
      Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map),
    );
    final actions = turn.boardActions;
    final pages = paginateBoardActions(
      actions: actions,
      viewportHeight: boardSize.height - boardTabsHeight - 116.0,
      viewportWidth: boardSize.width,
    );

    for (var i = 0; i < pages.length; i++) {
      final resolved = SemanticBoardLayout.resolve(
        actions: pages[i].actions,
        viewport: Size(boardSize.width, boardSize.height - boardTabsHeight - 116.0),
        textDirection: TextDirection.ltr,
      );
      // ignore: avoid_print
      print('=== PAGE $i (actions=${resolved.length}) ===');
      for (final a in resolved) {
        final bottom = (a.y ?? 0) + (a.height ?? 0);
        // ignore: avoid_print
        print('  ${a.id} (${a.type}): y=${a.y}, h=${a.height}, bottom=$bottom');
      }
    }

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

    await shoot(tester, 'khmer-board-1');

    for (var index = 1; index < pages.length; index++) {
      await tester.tap(find.byKey(const Key('visual-tutor-board-next')));
      await tester.pump(const Duration(milliseconds: 400));
      final boardActions = tester
          .widget<LiveTeachingBoard>(find.byType(LiveTeachingBoard))
          .actions;
      // ignore: avoid_print
      print('=== SHOT board-${index + 1}: LiveTeachingBoard actions=${boardActions.length} ===');
      for (final a in boardActions) {
        // ignore: avoid_print
        print('  ${a.id} (${a.type}): x=${a.x}, y=${a.y}, w=${a.width}, h=${a.height}, hidden=${a.hidden}');
      }
      await shoot(tester, 'khmer-board-${index + 1}');
    }

    // ignore: avoid_print
    print('KHMER SHOTS boards=${pages.length} written to build/board_shots');
  });

  testWidgets('capture Khmer DeepSeek follow-up board', (tester) async {
    const khmerFollowupPath =
        '/Users/macbookpro/.gemini/antigravity/brain/e5cff947-9764-430b-9926-25037738d796/scratch/khmer_limit_turn2.json';
    final file = File(khmerFollowupPath);
    if (!file.existsSync()) return;

    tester.view.physicalSize = boardSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final turn = VisualTutorTurnResponseModel.fromJson(
      Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map),
    );
    final actions = turn.boardActions;
    final pages = paginateBoardActions(
      actions: actions,
      viewportHeight: boardSize.height - boardTabsHeight - 116.0,
      viewportWidth: boardSize.width,
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

    await shoot(tester, 'khmer-followup-board-1');

    for (var index = 1; index < pages.length; index++) {
      await tester.tap(find.byKey(const Key('visual-tutor-board-next')));
      await tester.pump(const Duration(milliseconds: 400));
      await shoot(tester, 'khmer-followup-board-${index + 1}');
    }

    // ignore: avoid_print
    print('KHMER FOLLOWUP SHOTS boards=${pages.length} written to build/board_shots');
  });
}
