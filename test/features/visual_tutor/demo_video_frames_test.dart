/// Captures the whiteboard animating, frame by frame, for a presentation video.
///
/// This is the moving counterpart to `demo_screenshots_test.dart`. Both replay
/// turns captured from the running gateway through the real board widget, so
/// what comes out is the animation a student actually sees rather than a
/// re-creation of it: the same step order, the same per-action `duration_ms`,
/// the same LaTeX clip-reveal.
///
/// Frames are written as PNGs and encoded separately by `tool/make_demo_video.sh`,
/// because a widget test is the only place this board can be driven without a
/// signed-in browser, and ffmpeg is the only thing that should be encoding video.
///
/// Run:    flutter test test/features/visual_tutor/demo_video_frames_test.dart
/// Output: `build/demo_video/<name>/f_XXXX.png`
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ai_tutor/core/localization/app_localizations.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/data/models/visual_tutor_models.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1280x720 logical at 1.5x gives a 1920x1080 frame — slide and projector native.
///
/// The solution paginates across several boards at this size, and the clip shows
/// those page turns, because that is what a student actually sees. What it must
/// not show is the empty board the widget advances to once the last action is
/// written; `tool/make_demo_video.sh` trims that tail before encoding.
const Size _boardSize = Size(1280, 720);
const double _pixelRatio = 1.5;

/// 25fps. The board's own timings are in whole hundreds of milliseconds, so this
/// lands on them exactly and avoids sampling halfway through a reveal.
const Duration _frameStep = Duration(milliseconds: 40);

/// Held at the end so the finished board is readable before the clip cuts.
const Duration _holdAtEnd = Duration(milliseconds: 2600);

class _Clip {
  const _Clip(this.fixture, this.name, {this.locale = 'en'});
  final String fixture;
  final String name;
  final String locale;
}

const _clips = <_Clip>[
  _Clip('demo_limits_en', 'limits-english'),
  _Clip('demo_limits_km', 'limits-khmer', locale: 'km'),
];

void main() {
  final boardKey = GlobalKey();

  VisualTutorTurnResponseModel loadTurn(String fixture) {
    final file = File('test/features/visual_tutor/fixtures/demo/$fixture.json');
    if (!file.existsSync()) {
      throw StateError(
        'Missing $fixture.json. Capture the demo fixtures from a running '
        'gateway first — see e2e/README.md for bringing the stack up.',
      );
    }
    return VisualTutorTurnResponseModel.fromJson(
      Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map),
    );
  }

  setUpAll(() async {
    // Flutter's test font paints every glyph as a filled box, so real faces are
    // loaded under the families the board asks for. Khmer needs its own face or
    // the Khmer clip records as rows of rectangles.
    Future<void> load(String family, List<String> candidates) async {
      for (final path in candidates) {
        final file = File(path);
        if (!file.existsSync()) continue;
        final loader = FontLoader(family)
          ..addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
        await loader.load();
        return;
      }
    }

    const latin = [
      '/System/Library/Fonts/Supplemental/Arial.ttf',
      '/System/Library/Fonts/Helvetica.ttc',
    ];
    for (final family in ['Roboto', 'Arial']) {
      await load(family, latin);
    }
    // The app now bundles Kantumruy, so prefer the copy the student actually gets.
    const khmer = [
      'assets/fonts/Kantumruy-Regular.ttf',
      '/Library/Fonts/NotoSansKhmer-Regular.ttf',
      '/System/Library/Fonts/Supplemental/Khmer Sangam MN.ttf',
    ];
    for (final family in ['Kantumruy Pro', 'Noto Sans Khmer']) {
      await load(family, khmer);
    }

    await load('MaterialIcons', const [
      '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]);

    // The equation renderer ships KaTeX as package assets, which a widget test
    // does not bundle. Without them every formula records as boxes.
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
  });

  for (final clip in _clips) {
    testWidgets('capture frames for ${clip.name}', (tester) async {
      tester.view.physicalSize = _boardSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final turn = loadTurn(clip.fixture);
      // The closing "ws-next" prompt ("ask me about any step") is a call to
      // action, not part of the worked solution, and it spills onto a page of
      // its own -- so a clip that includes it ends by holding on an almost
      // empty board instead of on the answer.
      final actions = turn.boardActions
          .where((action) => !action.id.startsWith('ws-next'))
          .toList();
      expect(actions, isNotEmpty, reason: '${clip.fixture} carried no actions');
      expect(
        actions.length,
        lessThan(turn.boardActions.length),
        reason: 'expected a trailing ws-next action to drop',
      );

      final totalMs = actions.fold<int>(
        0,
        (sum, action) => sum + action.durationMs,
      );
      final runFor = Duration(milliseconds: totalMs) + _holdAtEnd;

      final directory = Directory('build/demo_video/${clip.name}');
      if (directory.existsSync()) directory.deleteSync(recursive: true);
      directory.createSync(recursive: true);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          locale: Locale(clip.locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: RepaintBoundary(
              key: boardKey,
              child: SizedBox(
                width: _boardSize.width,
                height: _boardSize.height,
                child: TeachingCanvasBoard(
                  variant: 'speaking_writing',
                  actions: actions,
                  finalAnswerLocked: false,
                  verification: turn.verification,
                  // The whole point is to record the animation, so neither of
                  // these may be set the way the still-capture harness sets them.
                  reducedMotion: false,
                  restored: false,
                  useLogicalCanvasScale: true,
                  pageViewportHeight: _boardSize.height,
                ),
              ),
            ),
          ),
        ),
      );

      // pumpWidget alone does not guarantee the boundary is mounted, and the
      // board schedules its first reveal on the frame after build.
      await tester.pump();

      var index = 0;
      var elapsed = Duration.zero;
      while (elapsed <= runFor) {
        final boundary = boardKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: _pixelRatio);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          File('${directory.path}/f_${index.toString().padLeft(4, '0')}.png')
            ..createSync()
            ..writeAsBytesSync(bytes!.buffer.asUint8List());
        });
        index++;
        await tester.pump(_frameStep);
        elapsed += _frameStep;
      }

      expect(
        index,
        greaterThan(100),
        reason: 'too few frames to make a clip out of',
      );
      // A board that never changed means the animation did not run, which would
      // record a still image dressed up as a video.
      final first = File('${directory.path}/f_0000.png').lengthSync();
      final last = File(
        '${directory.path}/f_${(index - 1).toString().padLeft(4, '0')}.png',
      ).lengthSync();
      expect(
        last,
        isNot(equals(first)),
        reason: 'the board did not animate — every frame is identical',
      );
    });
  }
}
