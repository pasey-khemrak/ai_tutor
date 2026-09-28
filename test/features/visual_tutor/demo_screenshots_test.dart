/// Renders the real whiteboard from real server responses and writes PNGs, for
/// use in a presentation.
///
/// The turns in `fixtures/demo/` were captured from the running gateway, so these
/// are the boards a student actually sees — not mock-ups. Signing in is not
/// required, which is why this exists as a test rather than a browser session.
///
/// Run:    flutter test test/features/visual_tutor/demo_screenshots_test.dart
/// Output: build/demo_shots/*.png
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ai_tutor/core/localization/app_localizations.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/data/models/visual_tutor_models.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Slide-friendly board: large enough to read when projected.
const Size _boardSize = Size(1000, 680);
const double _pixelRatio = 2.0;

class _Shot {
  const _Shot(this.fixture, this.name, {this.locale = 'en'});
  final String fixture;
  final String name;
  final String locale;
}

const _shots = <_Shot>[
  _Shot('demo_limits_en', '01-limits-english'),
  _Shot('demo_limits_km', '02-limits-khmer', locale: 'km'),
  _Shot('demo_physics_fbd', '03-physics-free-body-diagram'),
  _Shot('demo_chemistry', '04-chemistry-reaction'),
  _Shot('demo_quadratic', '05-quadratic'),
  _Shot('demo_topic_lock', '06-topic-lock-refusal'),
];

void main() {
  final shotKey = GlobalKey();

  VisualTutorTurnResponseModel loadTurn(String fixture) {
    final file = File(
      'test/features/visual_tutor/fixtures/demo/$fixture.json',
    );
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

  Future<void> shoot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final boundary =
          shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: _pixelRatio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('build/demo_shots')
        ..createSync(recursive: true);
      File('${directory.path}/$name.png')
        ..createSync()
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  setUpAll(() async {
    // Flutter's test font paints every glyph as a filled box, so real faces are
    // loaded under the families the board asks for. Khmer needs its own face or
    // the Khmer board captures as rows of rectangles.
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
    const khmer = [
      '/Library/Fonts/NotoSansKhmer-Regular.ttf',
      '/System/Library/Fonts/Supplemental/Khmer Sangam MN.ttf',
    ];
    for (final family in ['Roboto', 'Arial']) {
      await load(family, latin);
    }
    for (final family in ['Noto Sans Khmer', 'Kantumruy Pro']) {
      await load(family, khmer);
    }

    // Icons, or every chip and control paints as a filled box.
    await load('MaterialIcons', const [
      '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]);

    // The equation renderer ships its own KaTeX faces as package assets, which a
    // widget test does not bundle. Without them every formula paints as boxes.
    final katex = Directory(
      '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
      'flutter_math_fork-0.7.4/lib/katex_fonts/fonts',
    );
    if (katex.existsSync()) {
      for (final file in katex.listSync().whereType<File>()) {
        if (!file.path.endsWith('.ttf')) continue;
        // KaTeX_Main-Regular.ttf -> family "KaTeX_Main". A package font is also
        // addressed as `packages/<package>/<family>`, which is how the renderer
        // asks for it, so register both spellings.
        final family = file.uri.pathSegments.last.split('-').first;
        final bytes = file.readAsBytesSync().buffer.asByteData();
        for (final name in [
          family,
          'packages/flutter_math_fork/$family',
        ]) {
          final loader = FontLoader(name)..addFont(Future.value(bytes));
          await loader.load();
        }
      }
    }
  });

  for (final shot in _shots) {
    testWidgets('capture ${shot.name}', (tester) async {
      tester.view.physicalSize = _boardSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final turn = loadTurn(shot.fixture);
      final actions = turn.boardActions;
      expect(
        actions,
        isNotEmpty,
        reason: '${shot.fixture} carried no board actions to render',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          locale: Locale(shot.locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: RepaintBoundary(
              key: shotKey,
              child: SizedBox(
                width: _boardSize.width,
                height: _boardSize.height,
                child: TeachingCanvasBoard(
                  variant: 'speaking_writing',
                  actions: actions,
                  // The captured turns have their answer revealed, and the board
                  // is complete, so nothing is withheld or mid-animation.
                  finalAnswerLocked: false,
                  verification: turn.verification,
                  reducedMotion: true,
                  restored: true,
                  useLogicalCanvasScale: true,
                  pageViewportHeight: _boardSize.height,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      await shoot(tester, shot.name);
      expect(
        File('build/demo_shots/${shot.name}.png').lengthSync(),
        greaterThan(10000),
        reason: 'the capture looks empty',
      );
    });
  }
}
