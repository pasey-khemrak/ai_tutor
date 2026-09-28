import 'package:ai_tutor/core/localization/app_localizations.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/saved_solutions/saved_solution.dart';
import 'package:ai_tutor/features/saved_solutions/saved_solutions_repository.dart';
import 'package:ai_tutor/screens/saved/saved_solution_view_screen.dart';
import 'package:ai_tutor/screens/saved/saved_solutions_screen.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

SavedSolution _saved({
  String id = 'saved-1',
  bool verified = true,
  String status = 'correct',
}) => SavedSolution(
  id: id,
  problemText: 'Solve 3x + 7 = 22',
  subject: 'Mathematics',
  topic: 'Linear Equations',
  answerSummary: 'x = 5',
  verificationStatus: status,
  verified: verified,
  savedAt: DateTime.utc(2026, 9, 27, 10),
  boardActions: _actions,
);

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  theme: AppTheme.dark(),
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: child,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Clipboard is a platform channel; without a handler the copy throws and the
  // confirmation never shows.
  final copied = <String>[];
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    copied.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add('${(call.arguments as Map)['text']}');
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('the saved list shows what a student kept', (tester) async {
    final repository = SavedSolutionsRepository();
    await repository.save(_saved());

    await tester.pumpWidget(
      _wrap(SavedSolutionsScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('saved-solution-saved-1')), findsOneWidget);
    expect(find.text('Solve 3x + 7 = 22'), findsOneWidget);
    expect(find.textContaining('Linear Equations'), findsOneWidget);
  });

  testWidgets('the saved list tells a verified solution from an unverified one', (
    tester,
  ) async {
    final repository = SavedSolutionsRepository();
    await repository.save(_saved());
    await repository.save(
      _saved(id: 'saved-2', verified: false, status: 'cannot_verify'),
    );

    await tester.pumpWidget(
      _wrap(SavedSolutionsScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('AI answer — not machine-checked'), findsOneWidget);
  });

  testWidgets('empty state routes into the tutor', (tester) async {
    var started = false;
    await tester.pumpWidget(
      _wrap(
        SavedSolutionsScreen(
          repository: SavedSolutionsRepository(),
          onStartLearning: () => started = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('saved-empty')), findsOneWidget);
    await tester.tap(find.byKey(const Key('saved-empty-start-button')));
    expect(started, isTrue);
  });

  testWidgets('a student can remove a saved solution', (tester) async {
    final repository = SavedSolutionsRepository();
    await repository.save(_saved());

    await tester.pumpWidget(
      _wrap(SavedSolutionsScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('saved-remove-saved-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saved-remove-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('saved-solution-saved-1')), findsNothing);
    expect(await repository.loadAll(), isEmpty);
  });

  testWidgets('reopening paints the saved board, fully drawn', (tester) async {
    await tester.pumpWidget(
      _wrap(SavedSolutionViewScreen(solution: _saved())),
    );
    await tester.pumpAndSettle();

    // Every saved action is on the board, with no animation left to run.
    expect(find.textContaining('Step 1 · Subtract 7'), findsOneWidget);
    expect(find.textContaining('Answer · x = 5'), findsOneWidget);
  });

  testWidgets('a reopened solution offers its text for export', (tester) async {
    await tester.pumpWidget(
      _wrap(SavedSolutionViewScreen(solution: _saved())),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('saved-export-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('saved-export-button')));
    await tester.pumpAndSettle();

    // The solution really reached the clipboard, and the student is told so —
    // a silent copy leaves them unsure whether it worked.
    expect(copied, hasLength(1));
    expect(copied.single, contains('Solve 3x + 7 = 22'));
    expect(copied.single, contains('Answer · x = 5'));
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('the saved list renders in Khmer', (tester) async {
    final repository = SavedSolutionsRepository();
    await repository.save(_saved());

    await tester.pumpWidget(
      _wrap(
        SavedSolutionsScreen(repository: repository),
        locale: const Locale('km'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ដំណោះស្រាយដែលបានរក្សាទុក'), findsOneWidget);
    expect(find.text('Saved solutions'), findsNothing);
  });

  testWidgets('the saved list fits a 360px phone in Khmer', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = SavedSolutionsRepository();
    await repository.save(_saved());

    for (final theme in [AppTheme.dark(), AppTheme.light()]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          locale: const Locale('km'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: SavedSolutionsScreen(repository: repository),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
