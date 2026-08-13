import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/domain/repositories/visual_tutor_repository.dart';
import 'package:ai_tutor/screens/learning_selection/learning_selection_repository.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
                grade: 10,
                subject: 'Mathematics',
                topic: 'Linear Equations',
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
      topic: 'Linear Equations',
      problemText: '2x + 5 = 15',
      normalizedProblem: '2*x + 5 = 15',
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
