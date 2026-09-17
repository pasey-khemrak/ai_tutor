import '../../screens/learning_selection/learning_selection_repository.dart';
import '../../screens/lessons/local_mvp_limits_scope.dart';
import 'domain/entities/visual_tutor_entities.dart';

/// Source-linked opening for the reviewed local MVP context.
/// The device-local session evaluator owns subsequent turns and restoration.
bool canUseLocalMvpLimitsOpeningFallback(LearningContext? context) =>
    context != null &&
    isLocalMvpLimitsScope(
      grade: context.grade,
      subject: context.subject,
      topic: context.topic,
      lessonId: context.lessonId ?? '',
      curriculumVersionId: context.curriculumVersionId ?? '',
      teachingMomentId: context.teachingMomentId,
    );

VisualTutorSessionEntity localMvpLimitsFallbackSession({
  required String userId,
}) => VisualTutorSessionEntity(
  sessionId: 'device-local:grade12-limits:v1',
  userId: userId,
  subject: localMvpSubject,
  topic: localMvpTopic,
  metadata: const {'local_curriculum_demo': true},
);

VisualTutorTurnResponseEntity buildLocalMvpLimitsOpeningFallback({
  required String sessionId,
}) => VisualTutorTurnResponseEntity(
  sessionId: sessionId,
  turnId: 'local-limits-moment-01',
  screenState: 'asking_question',
  tutorStatus: 'Waiting for you',
  spokenText:
      'លីមីតនៃអនុគមន៍៖ សង្កេតតារាងនៅពេល x ខិតជិត 1។ '
      'តើ f(x) ខិតជិតលេខណា នៅពេល x ខិតជិត 1?',
  displayText: 'លីមីតនៃអនុគមន៍៖ សង្កេតតារាងនៅពេល x ខិតជិត 1។',
  teachingMode: 'guided_question',
  finalAnswerLocked: true,
  studentTask: 'តើ f(x) ខិតជិតលេខណា នៅពេល x ខិតជិត 1?',
  board: VisualTutorBoardEntity(
    type: 'formula_card',
    title: 'លីមីតនៃអនុគមន៍',
    metadata: {'local_curriculum_demo': true},
  ),
  boardActions: [
    VisualTutorBoardActionEntity(
      id: 'limits-equation',
      type: 'write_equation',
      sequenceIndex: 0,
      durationMs: 500,
      layoutZone: 'problem',
      layoutFlow: 'vertical',
      latex: 'f(x) = (2x² + x − 3) / (x − 1)',
    ),
    VisualTutorBoardActionEntity(
      id: 'limits-source-table',
      type: 'show_table',
      sequenceIndex: 1,
      durationMs: 700,
      layoutZone: 'visual',
      layoutFlow: 'vertical',
      metadata: {
        'columns': ['x', 'f(x)'],
        'rows': [
          ['0.9', '4.8'],
          ['0.99', '4.98'],
          ['1.001', '5.002'],
          ['1.1', '5.2'],
        ],
      },
    ),
    VisualTutorBoardActionEntity(
      id: 'limits-student-task',
      type: 'student_task',
      sequenceIndex: 2,
      layoutZone: 'student_task',
      layoutFlow: 'vertical',
      text: 'តើ f(x) ខិតជិតលេខណា នៅពេល x ខិតជិត 1?',
      requiresStudentResponse: true,
    ),
  ],
  interaction: VisualTutorInteractionEntity(
    type: 'text_response',
    prompt: 'តើ f(x) ខិតជិតលេខណា នៅពេល x ខិតជិត 1?',
    expectedAnswerLocked: true,
    inputEnabled: true,
    submitLabel: 'បញ្ជូន',
  ),
  allowedActions: [
    'submit_answer',
    'request_hint',
    'explain_differently',
    'stuck',
    'request_answer',
  ],
  quickActions: ['submit_answer', 'request_hint'],
  metadata: {
    'local_curriculum_demo': true,
    'local_demo_label': 'Local curriculum demo',
    'lesson_id': localMvpLessonId,
    'curriculum_version_id': localMvpCurriculumVersionId,
    'source_id': 'provided-pdf-2025-10-01-00007213',
    'source_page': 1,
    'waiting_for_student_input': true,
    'board_update_mode': 'replace',
  },
);
