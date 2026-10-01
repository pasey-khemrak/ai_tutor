import 'package:ai_tutor/core/localization/app_localizations.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/screens/tutor/visual_tutor_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildScreen({
    Locale? locale,
  }) {
    return MaterialApp(
      theme: AppTheme.dark(),
      locale: locale,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: VisualTutorHomeScreen(),
      ),
    );
  }

  testWidgets(
      'renders whiteboard in ask_question mode with fresh board prompt in English',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('visual-tutor-home-screen')), findsOneWidget);
    expect(find.byKey(const Key('fresh-board-prompt')), findsOneWidget);
    expect(
      find.text(
          'Ask any math, physics, or chemistry problem. Type or speak below to begin.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('fresh-board-topic-limits')), findsOneWidget);
    expect(
        find.byKey(const Key('fresh-board-topic-complex-numbers')), findsOneWidget);
    expect(find.byKey(const Key('fresh-board-topic-kinematics')), findsOneWidget);
    expect(
        find.byKey(const Key('fresh-board-topic-stoichiometry')), findsOneWidget);
  });

  testWidgets('renders fresh board prompt in Khmer under km locale',
      (tester) async {
    await tester.pumpWidget(buildScreen(locale: const Locale('km')));
    await tester.pumpAndSettle();

    expect(
      find.text(
          'សួរសំណួរ ឬលំហាត់គណិតវិទ្យា រូបវិទ្យា ឬគីមីវិទ្យា។ សូមវាយអត្ថបទ ឬនិយាយដើម្បីចាប់ផ្តើម។'),
      findsOneWidget,
    );
    expect(find.textContaining('លីមីត'), findsOneWidget);
    expect(find.textContaining('ចំនួនកុំផ្លិច'), findsOneWidget);
    expect(find.textContaining('ស៊ីនេម៉ាទិច'), findsOneWidget);
    expect(find.textContaining('ស្តូស្យូមេទ្រី'), findsOneWidget);
  });

  testWidgets('tapping a suggested topic chip prefills problem into the input bar',
      (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('fresh-board-topic-limits')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('limit of (x^2 - 4)/(x - 2)'),
      findsOneWidget,
    );
  });

  testWidgets(
      'tapping complex numbers chip prefills complex numbers problem',
      (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('fresh-board-topic-complex-numbers')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('z^6'),
      findsOneWidget,
    );
  });

  testWidgets('visual tutor home renders on phone without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('fresh-board-prompt')), findsOneWidget);
  });
}
