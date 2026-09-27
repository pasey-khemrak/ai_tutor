import 'dart:convert';
import 'dart:io';

import 'package:ai_tutor/core/localization/app_localizations.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/data/models/visual_tutor_models.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/widgets/live_teaching_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  VisualTutorTurnResponseModel loadTurnFixture({
    required bool verified,
    required String status,
    required bool finalAnswerLocked,
  }) {
    final file = File(
      'test/features/visual_tutor/fixtures/worked_solution_turn.json',
    );
    final map = Map<String, dynamic>.from(
      jsonDecode(file.readAsStringSync()) as Map,
    );
    final lessonState = Map<String, dynamic>.from(map['lesson_state'] as Map);
    lessonState['final_answer_locked'] = finalAnswerLocked;
    map['lesson_state'] = lessonState;

    final teachingPlan = Map<String, dynamic>.from(map['teaching_plan'] as Map);
    final hiddenPolicy =
        Map<String, dynamic>.from(teachingPlan['hidden_answer_policy'] as Map);
    hiddenPolicy['deterministic_policy_permits_final_reveal'] =
        !finalAnswerLocked;
    teachingPlan['hidden_answer_policy'] = hiddenPolicy;
    map['teaching_plan'] = teachingPlan;

    map['verification'] = {
      'status': status,
      'verified': verified,
      'concise_evidence': 'SymPy evaluation',
      'student_facing_feedback': 'Verification details',
    };
    return VisualTutorTurnResponseModel.fromJson(map);
  }

  Widget buildTestBoard({
    required List<VisualTutorBoardActionEntity> actions,
    required VisualTutorVerificationEntity? verification,
    required bool finalAnswerLocked,
    Locale locale = const Locale('en'),
    Size size = const Size(900, 2400),
  }) {
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.dark(),
      home: Scaffold(
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: LiveTeachingBoard(
            variant: 'speaking_writing',
            actions: actions,
            finalAnswerLocked: finalAnswerLocked,
            verification: verification,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'turn with verification.verified == true renders visible "Verified" chip on board',
    (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final turn = loadTurnFixture(
        verified: true,
        status: 'correct',
        finalAnswerLocked: false,
      );

      await tester.pumpWidget(
        buildTestBoard(
          actions: turn.boardActions,
          verification: turn.verification,
          finalAnswerLocked: turn.finalAnswerLocked,
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Verified'), findsOneWidget);
      expect(
        find.byKey(const Key('visual-tutor-verified-chip')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('visual-tutor-unverified-chip')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'turn with status == "cannot_verify" renders distinct "AI answer — not machine-checked" chip',
    (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final turn = loadTurnFixture(
        verified: false,
        status: 'cannot_verify',
        finalAnswerLocked: false,
      );

      await tester.pumpWidget(
        buildTestBoard(
          actions: turn.boardActions,
          verification: turn.verification,
          finalAnswerLocked: turn.finalAnswerLocked,
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('AI answer — not machine-checked'), findsOneWidget);
      expect(
        find.byKey(const Key('visual-tutor-unverified-chip')),
        findsOneWidget,
      );
      expect(find.text('Verified'), findsNothing);
      expect(
        find.byKey(const Key('visual-tutor-verified-chip')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'respects answer lock: when final_answer_locked is true, neither chip is shown',
    (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final turn = loadTurnFixture(
        verified: true,
        status: 'correct',
        finalAnswerLocked: true,
      );

      await tester.pumpWidget(
        buildTestBoard(
          actions: turn.boardActions,
          verification: turn.verification,
          finalAnswerLocked: turn.finalAnswerLocked,
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Verified'), findsNothing);
      expect(find.text('AI answer — not machine-checked'), findsNothing);
      expect(
        find.byKey(const Key('visual-tutor-verified-chip')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('visual-tutor-unverified-chip')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'localizes verification chips into Khmer correctly',
    (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final verifiedTurn = loadTurnFixture(
        verified: true,
        status: 'correct',
        finalAnswerLocked: false,
      );

      await tester.pumpWidget(
        buildTestBoard(
          actions: verifiedTurn.boardActions,
          verification: verifiedTurn.verification,
          finalAnswerLocked: verifiedTurn.finalAnswerLocked,
          locale: const Locale('km'),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('បានផ្ទៀងផ្ទាត់'), findsOneWidget);

      final unverifiedTurn = loadTurnFixture(
        verified: false,
        status: 'cannot_verify',
        finalAnswerLocked: false,
      );

      await tester.pumpWidget(
        buildTestBoard(
          actions: unverifiedTurn.boardActions,
          verification: unverifiedTurn.verification,
          finalAnswerLocked: unverifiedTurn.finalAnswerLocked,
          locale: const Locale('km'),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('ចម្លើយ AI — មិនបានផ្ទៀងផ្ទាត់ម៉ាស៊ីន'), findsOneWidget);
    },
  );
}
