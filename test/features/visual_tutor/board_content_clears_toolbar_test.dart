/// Board content must not be drawn underneath the floating toolbar.
///
/// The toolbar is a `Positioned` overlay while the board content is a
/// `Positioned.fill` beneath it, so anything laid out at the top of a board
/// renders under the buttons. It usually goes unnoticed because most boards
/// open on a step whose text starts lower down — but a board whose first item
/// sits at the top, which is what the answer page does, puts the answer itself
/// behind the toolbar. It was found while recording the Khmer demo clip: the
/// final frame showed "ចម្លើយ · លីមីតគឺ 4" half hidden behind the buttons.
library;

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

  /// The drawing toolbar's left-most button stands in for the toolbar band:
  /// the controls are a private widget, but this button is keyed and sits
  /// inside them, so its rect is within the area content must keep clear of.
  Rect toolbarRect(WidgetTester tester) =>
      tester.getRect(find.byKey(const Key('visual-tutor-board-reset-fit')));

  Future<void> pumpBoard(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: TeachingCanvasBoard(
              variant: 'speaking_writing',
              actions: loadTurn().boardActions,
              finalAnswerLocked: false,
              reducedMotion: true,
              restored: true,
              useLogicalCanvasScale: true,
              pageViewportHeight: size.height,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  /// Every piece of board text, as laid out on screen.
  List<Rect> contentRects(WidgetTester tester) {
    final rects = <Rect>[];
    for (final element in find.byType(Text).evaluate()) {
      final text = element.widget as Text;
      final value = text.data ?? '';
      // Skip the chrome: the pager label and any button labels are meant to
      // live up there.
      if (value.isEmpty) continue;
      if (value.contains('Board ') || value.contains('ក្តារ')) continue;
      final renderBox = element.renderObject as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) continue;
      final topLeft = renderBox.localToGlobal(Offset.zero);
      rects.add(topLeft & renderBox.size);
    }
    for (final element in find.byType(SelectableText).evaluate()) {
      final selectable = element.widget as SelectableText;
      final value = selectable.data ?? selectable.textSpan?.toPlainText() ?? '';
      if (value.isEmpty) continue;
      final renderBox = element.renderObject as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) continue;
      final topLeft = renderBox.localToGlobal(Offset.zero);
      rects.add(topLeft & renderBox.size);
    }
    return rects;
  }

  testWidgets('board text clears the toolbar on a desktop-width board', (
    tester,
  ) async {
    await pumpBoard(tester, const Size(1280, 720));

    final toolbar = toolbarRect(tester);
    final overlapping = contentRects(
      tester,
    ).where((rect) => rect.overlaps(toolbar)).toList();

    expect(
      overlapping,
      isEmpty,
      reason: 'board text is drawn under the toolbar at $toolbar: $overlapping',
    );
  });

  testWidgets('board text clears the toolbar on a phone-width board', (
    tester,
  ) async {
    await pumpBoard(tester, const Size(420, 780));

    final toolbar = toolbarRect(tester);
    final overlapping = contentRects(
      tester,
    ).where((rect) => rect.overlaps(toolbar)).toList();

    expect(
      overlapping,
      isEmpty,
      reason: 'board text is drawn under the toolbar at $toolbar: $overlapping',
    );
  });
}
