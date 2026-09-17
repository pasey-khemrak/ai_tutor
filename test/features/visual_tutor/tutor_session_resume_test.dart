import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/domain/repositories/visual_tutor_repository.dart';
import 'package:ai_tutor/screens/learning_selection/learning_selection_repository.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'restores the requested persisted tutor session without creating another',
    (tester) async {
      final repository = _ResumingTutorRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: TutorScreen(
              context: const LearningContext(
                grade: 12,
                subject: 'Mathematics',
                topic: 'Limits of Functions',
                gradeLevelId: 'grade-12',
                subjectId: 'math',
                topicId: 'math-g12-limits-of-functions',
                lessonId: 'math.g12.lesson1.limits-of-functions',
                curriculumVersionId: 'local-g12-math-limits-2025-10-01-v1',
                teachingMomentId:
                    'math.g12.lesson1.limits-of-functions.finite-at-point.01',
                languageMode: 'khmer',
              ),
              initialSessionId: 'persisted-session-1',
              repository: repository,
              userId: 'student-1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.restoredSessionIds, ['persisted-session-1']);
      expect(repository.createdSessions, isEmpty);
    },
  );

  testWidgets(
    'an explicit resume session wins over a stale locally saved session',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'active_tutor_session_id': 'stale-device-session',
      });
      addTearDown(() => SharedPreferences.setMockInitialValues({}));
      final repository = _ResumingTutorRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: TutorScreen(
              context: const LearningContext(
                grade: 12,
                subject: 'Mathematics',
                topic: 'Limits of Functions',
                gradeLevelId: 'grade-12',
                subjectId: 'math',
                topicId: 'math-g12-limits-of-functions',
                lessonId: 'math.g12.lesson1.limits-of-functions',
                curriculumVersionId: 'local-g12-math-limits-2025-10-01-v1',
                teachingMomentId:
                    'math.g12.lesson1.limits-of-functions.finite-at-point.01',
                languageMode: 'khmer',
              ),
              initialSessionId: 'persisted-session-1',
              repository: repository,
              userId: 'student-1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.restoredSessionIds, ['persisted-session-1']);
      expect(repository.createdSessions, isEmpty);
    },
  );
}

class _ResumingTutorRepository implements VisualTutorRepository {
  final restoredSessionIds = <String>[];
  final createdSessions = <VisualTutorSessionCreateRequestEntity>[];

  @override
  Future<VisualTutorSessionEntity> createSession(
    VisualTutorSessionCreateRequestEntity request,
  ) async {
    createdSessions.add(request);
    return const VisualTutorSessionEntity(
      sessionId: 'new-session',
      userId: 'student-1',
      subject: 'Mathematics',
    );
  }

  @override
  Future<VisualTutorSessionEntity> restoreSession(String sessionId) async {
    restoredSessionIds.add(sessionId);
    return const VisualTutorSessionEntity(
      sessionId: 'persisted-session-1',
      userId: 'student-1',
      subject: 'Mathematics',
      topic: 'Limits of Functions',
      problemText: 'Observe f(x) near 1.',
      normalizedProblem: 'Observe f(x) near 1.',
      currentStepIndex: 1,
      hintCount: 1,
      wrongAttempts: 1,
      metadata: {'board_version': 2},
    );
  }

  @override
  Future<VisualTutorTurnResponseEntity> sendTurn(
    VisualTutorTurnRequestEntity request,
  ) => throw UnimplementedError();
}
