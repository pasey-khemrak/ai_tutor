import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/app/tutor_shell.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/domain/repositories/visual_tutor_repository.dart';
import 'package:ai_tutor/screens/learning_selection/learning_selection_repository.dart';
import 'package:ai_tutor/screens/lessons/student_lessons_repository.dart';
import 'package:ai_tutor/screens/lessons/local_mvp_limits_scope.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const limitsLessonId = 'math.g12.lesson1.limits-of-functions';
  const limitsMomentId =
      'math.g12.lesson1.limits-of-functions.finite-at-point.01';

  test(
    'Grade 12 Limits catalogue lesson carries an explicit scoped context',
    () {
      final lesson = demoStudentLessons.singleWhere(
        (lesson) => lesson.lessonId == limitsLessonId,
      );
      final context = LearningContext(
        grade: lesson.grade,
        subject: lesson.subject,
        topic: lesson.topic,
        gradeLevelId: lesson.gradeLevelId,
        subjectId: lesson.subjectId,
        topicId: lesson.topicId,
        lessonId: lesson.lessonId,
        curriculumVersionId: lesson.curriculumVersionId,
        teachingMomentId: lesson.teachingMomentId,
        languageMode: lesson.languageMode,
      );

      expect(context.isCurriculumScoped, isTrue);
      expect(context.grade, 12);
      expect(context.subject, 'Mathematics');
      expect(context.topic, 'Limits of Functions');
      expect(context.lessonId, limitsLessonId);
      expect(
        context.curriculumVersionId,
        'local-g12-math-limits-2025-10-01-v1',
      );
      expect(context.teachingMomentId, limitsMomentId);
      expect(context.languageMode, 'khmer');
    },
  );

  test(
    'the real selected-lesson handoff preserves every Limits context field',
    () {
      final lesson = demoStudentLessons.single;
      final context = learningContextForLesson(lesson);

      expect(context.grade, localMvpGrade);
      expect(context.subject, localMvpSubject);
      expect(context.topic, localMvpTopic);
      expect(context.gradeLevelId, 'grade-12');
      expect(context.subjectId, localMvpSubjectId);
      expect(context.topicId, localMvpTopicId);
      expect(context.lessonId, localMvpLessonId);
      expect(context.curriculumVersionId, localMvpCurriculumVersionId);
      expect(context.languageMode, 'khmer');
      expect(context.teachingMomentId, localMvpTeachingMomentId);
    },
  );

  test('Ask a question context is intentionally unscoped', () {
    const context = LearningContext.askQuestion();

    expect(context.isCurriculumScoped, isFalse);
    expect(context.grade, 0);
    expect(context.subject, 'General');
    expect(context.topic, 'Ask a question');
    expect(context.gradeLevelId, isNull);
    expect(context.subjectId, isNull);
    expect(context.topicId, isNull);
    expect(context.lessonId, isNull);
    expect(context.curriculumVersionId, isNull);
    expect(context.teachingMomentId, isNull);
    expect(context.languageMode, 'english');
  });

  testWidgets(
    'dashboard, scan, and voice entry requests remain unscoped instead of relabelling a question as a lesson',
    (tester) async {
      const entryPoints = <String, VisualTutorStudentSubmission>{
        'dashboard_ask_anything': VisualTutorStudentSubmission(
          message: 'What is a statement?',
          intent: 'new_problem',
          action: 'submit_problem',
          inputType: 'text',
          metadata: {'entry_point': 'dashboard_ask_anything'},
        ),
        'scan_problem': VisualTutorStudentSubmission(
          message: '៥ ជាចំនួនបឋម។',
          intent: 'new_problem',
          action: 'submit_problem',
          inputType: 'image',
          metadata: {'entry_point': 'scan_problem'},
        ),
        'voice_question': VisualTutorStudentSubmission(
          message: 'Explain a statement',
          intent: 'new_problem',
          action: 'submit_problem',
          inputType: 'voice',
          metadata: {'entry_point': 'voice_question'},
        ),
      };

      for (final entry in entryPoints.entries) {
        final repository = _CapturingTutorRepository();
        await tester.pumpWidget(
          _wrap(
            TutorScreen(
              context: const LearningContext.askQuestion(),
              repository: repository,
              initialSubmission: entry.value,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final request = repository.createdSessions.single;
        expect(request.subject, 'General', reason: entry.key);
        expect(request.topic, isNull, reason: entry.key);
        expect(
          request.metadata['is_curriculum_scoped'],
          isFalse,
          reason: entry.key,
        );
        for (final field in const [
          'grade_level_id',
          'subject_id',
          'topic_id',
          'lesson_id',
          'curriculum_version_id',
          'teaching_moment_id',
        ]) {
          expect(
            request.metadata.containsKey(field),
            isFalse,
            reason: entry.key,
          );
        }
        final turn = repository.sentTurns.single;
        expect(turn.subject, 'General', reason: entry.key);
        expect(turn.topic, isNull, reason: entry.key);
        expect(turn.languageMode, 'english', reason: entry.key);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    },
  );

  testWidgets(
    'selected Grade 12 Limits lesson sends its exact curriculum scope and Khmer mode on the tutor turn',
    (tester) async {
      final repository = _CapturingTutorRepository();
      const context = LearningContext(
        grade: 12,
        subject: 'Mathematics',
        topic: 'Limits of Functions',
        gradeLevelId: 'grade-12',
        subjectId: 'math',
        topicId: 'math-g12-limits-of-functions',
        lessonId: limitsLessonId,
        curriculumVersionId: 'local-g12-math-limits-2025-10-01-v1',
        teachingMomentId: limitsMomentId,
        languageMode: 'khmer',
      );
      await tester.pumpWidget(
        _wrap(
          TutorScreen(
            context: context,
            repository: repository,
            initialSubmission: const VisualTutorStudentSubmission(
              message: 'ខ្ញុំចង់រៀនលីមីតនៃអនុគមន៍។',
              intent: 'new_problem',
              action: 'submit_problem',
              inputType: 'text',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final turn = repository.sentTurns.single;
      expect(turn.subject, 'Mathematics');
      expect(turn.topic, 'Limits of Functions');
      expect(turn.languageMode, 'khmer');
      expect(turn.metadata, containsPair('is_curriculum_scoped', true));
      expect(turn.metadata, containsPair('grade', 12));
      expect(turn.metadata, containsPair('grade_level_id', 'grade-12'));
      expect(turn.metadata, containsPair('subject_id', 'math'));
      expect(
        turn.metadata,
        containsPair('topic_id', 'math-g12-limits-of-functions'),
      );
      expect(turn.metadata, containsPair('lesson_id', limitsLessonId));
      expect(
        turn.metadata,
        containsPair(
          'curriculum_version_id',
          'local-g12-math-limits-2025-10-01-v1',
        ),
      );
      expect(turn.metadata, containsPair('teaching_moment_id', limitsMomentId));
    },
  );
}

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.dark(),
  home: Scaffold(body: child),
);

class _CapturingTutorRepository implements VisualTutorRepository {
  final createdSessions = <VisualTutorSessionCreateRequestEntity>[];
  final sentTurns = <VisualTutorTurnRequestEntity>[];

  @override
  Future<VisualTutorSessionEntity> createSession(
    VisualTutorSessionCreateRequestEntity request,
  ) async {
    createdSessions.add(request);
    return VisualTutorSessionEntity(
      sessionId: 'created-${createdSessions.length}',
      userId: request.userId,
      subject: request.subject,
      topic: request.topic,
      metadata: request.metadata,
    );
  }

  @override
  Future<VisualTutorSessionEntity> restoreSession(String sessionId) async =>
      throw UnsupportedError(
        'This focused routing fake never resumes a session.',
      );

  @override
  Future<VisualTutorTurnResponseEntity> sendTurn(
    VisualTutorTurnRequestEntity request,
  ) async {
    sentTurns.add(request);
    return VisualTutorTurnResponseEntity(
      sessionId: request.sessionId ?? 'created-session',
      turnId: 'turn-1',
      spokenText: 'Let us take one step.',
      displayText: 'Let us take one step.',
      teachingMode: 'guided_question',
      finalAnswerLocked: true,
      studentTask: 'What would you try next?',
      board: const VisualTutorBoardEntity(type: 'teaching_stage'),
    );
  }
}
