import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/screens/lessons/student_lessons_repository.dart';
import 'package:ai_tutor/screens/tutor/visual_tutor_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Tutor home opens curriculum topics and the free-form tutor', (tester) async {
    StudentLesson? opened;
    var asked = false;

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: VisualTutorHomeScreen(
          repository: const LocalDemoStudentLessonsRepository(),
          onOpenLesson: (lesson) => opened = lesson,
          onAskQuestion: (_) => asked = true,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final topic = find.byKey(Key('curriculum-topic-${demoStudentLessons.first.lessonId}'));
    await tester.ensureVisible(topic);
    await tester.tap(topic);
    final ask = find.byKey(const Key('curriculum-ask-own-button'));
    await tester.ensureVisible(ask);
    await tester.tap(ask);

    expect(opened?.lessonId, demoStudentLessons.first.lessonId);
    expect(asked, isTrue);
  });
}
