import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/widgets/live_teaching_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const longKhmerInstruction =
      'សូមមើលសមីការនេះដោយប្រុងប្រយ័ត្ន រក្សាតម្លៃទាំងសងខាងឱ្យស្មើគ្នា ហើយសាកល្បងសរសេរជំហានបន្ទាប់ដោយខ្លួនឯង មុនពេលគ្រូបន្ត។';

  Widget board({required double textScale}) => MaterialApp(
    theme: AppTheme.dark(),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: const Scaffold(
        body: SizedBox(
          width: 360,
          height: 640,
          child: LiveTeachingBoard(
            variant: 'speaking_writing',
            actions: [
              VisualTutorBoardActionEntity(
                id: 'khmer-long-text',
                type: 'write_text',
                text: longKhmerInstruction,
                layoutZone: 'working',
                layoutFlow: 'vertical',
              ),
              VisualTutorBoardActionEntity(
                id: 'khmer-task',
                type: 'student_task',
                text: 'តើអ្នកអាចសរសេរជំហានបន្ទាប់បានទេ?',
                sequenceIndex: 1,
                layoutZone: 'student_task',
                layoutFlow: 'vertical',
                requiresStudentResponse: true,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'long Khmer board text wraps and honours accessible text scaling',
    (tester) async {
      await tester.pumpWidget(board(textScale: 1));
      await tester.pumpAndSettle();
      final normalFontSize = tester
          .widget<Text>(find.text(longKhmerInstruction))
          .style!
          .fontSize!;

      await tester.pumpWidget(board(textScale: 1.7));
      await tester.pumpAndSettle();
      final scaledText = find.text(longKhmerInstruction);
      final scaledFontSize = tester.widget<Text>(scaledText).style!.fontSize!;
      final boardRect = tester.getRect(
        find.byKey(const Key('live-teaching-board-paper')),
      );

      expect(scaledText, findsOneWidget);
      expect(scaledFontSize, greaterThan(normalFontSize));
      expect(
        tester.getRect(scaledText).left,
        greaterThanOrEqualTo(boardRect.left),
      );
      expect(
        tester.getRect(scaledText).right,
        lessThanOrEqualTo(boardRect.right),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Khmer labels remain available to assistive technology', (
    tester,
  ) async {
    await tester.pumpWidget(board(textScale: 1.3));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(longKhmerInstruction), findsOneWidget);
    expect(
      find.bySemanticsLabel('តើអ្នកអាចសរសេរជំហានបន្ទាប់បានទេ?'),
      findsOneWidget,
    );
  });
}
