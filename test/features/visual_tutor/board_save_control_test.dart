// The Save control on the whiteboard.
//
// Saving is only meaningful once a solution has finished, so the control has to
// be absent the rest of the time rather than present and doing nothing.
import 'package:ai_tutor/core/localization/app_localizations.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _actions = [
  VisualTutorBoardActionEntity(
    id: 'ws-step-step1-0',
    type: 'write_text',
    sequenceIndex: 0,
    text: 'Step 1 · Subtract 7 from both sides.',
  ),
  VisualTutorBoardActionEntity(
    id: 'ws-answer-1',
    type: 'write_text',
    sequenceIndex: 1,
    text: 'Answer · x = 5',
  ),
];

Widget _board({
  VoidCallback? onSaveSolution,
  bool alreadySaved = false,
  Locale locale = const Locale('en'),
}) => MaterialApp(
  theme: AppTheme.dark(),
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(
    body: SizedBox(
      width: 420,
      height: 320,
      child: TeachingCanvasBoard(
        actions: _actions,
        finalAnswerLocked: false,
        reducedMotion: true,
        onSaveSolution: onSaveSolution,
        alreadySaved: alreadySaved,
      ),
    ),
  ),
);

void main() {
  final saveButton = find.byKey(const Key('visual-tutor-board-save'));

  testWidgets('no Save control when there is nothing worth keeping', (
    tester,
  ) async {
    await tester.pumpWidget(_board());
    await tester.pumpAndSettle();
    expect(saveButton, findsNothing);
  });

  testWidgets('a finished solution offers Save', (tester) async {
    var saved = 0;
    await tester.pumpWidget(_board(onSaveSolution: () => saved++));
    await tester.pumpAndSettle();

    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    expect(saved, 1);
  });

  testWidgets('an already-saved solution cannot be saved twice', (tester) async {
    var saved = 0;
    await tester.pumpWidget(
      _board(onSaveSolution: () => saved++, alreadySaved: true),
    );
    await tester.pumpAndSettle();

    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton, warnIfMissed: false);
    expect(saved, 0, reason: 'the control reads Saved and is disabled');
  });

  testWidgets('the Save control is labelled in Khmer', (tester) async {
    await tester.pumpWidget(
      _board(onSaveSolution: () {}, locale: const Locale('km')),
    );
    await tester.pumpAndSettle();

    final button = tester.widget<IconButton>(saveButton);
    expect(button.tooltip, 'រក្សាទុក');
  });
}
