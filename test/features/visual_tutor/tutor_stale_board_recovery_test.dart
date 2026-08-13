import 'package:ai_tutor/core/network/api_client.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/domain/repositories/visual_tutor_repository.dart';
import 'package:ai_tutor/screens/learning_selection/learning_selection_repository.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('refreshes the persisted session after a stale board conflict', (
    tester,
  ) async {
    final repository = _StaleBoardRepository();

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
            repository: repository,
            userId: 'student-1',
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('tutor-message-field')),
      '2x + 5 = 15',
    );
    await tester.tap(find.byKey(const Key('tutor-send-button')));
    await tester.pumpAndSettle();

    expect(repository.created, hasLength(1));
    expect(repository.restoredSessionIds, ['session-1']);
    expect(find.byKey(const Key('visual-tutor-api-error')), findsOneWidget);
    expect(find.textContaining('board was refreshed'), findsOneWidget);
  });
}

class _StaleBoardRepository implements VisualTutorRepository {
  final created = <VisualTutorSessionCreateRequestEntity>[];
  final restoredSessionIds = <String>[];

  @override
  Future<VisualTutorSessionEntity> createSession(
    VisualTutorSessionCreateRequestEntity request,
  ) async {
    created.add(request);
    return const VisualTutorSessionEntity(
      sessionId: 'session-1',
      userId: 'student-1',
      subject: 'Mathematics',
      topic: 'Linear Equations',
    );
  }

  @override
  Future<VisualTutorSessionEntity> restoreSession(String sessionId) async {
    restoredSessionIds.add(sessionId);
    return const VisualTutorSessionEntity(
      sessionId: 'session-1',
      userId: 'student-1',
      subject: 'Mathematics',
      topic: 'Linear Equations',
      problemText: '2x + 5 = 15',
      currentStepIndex: 1,
      metadata: {'board_version': 1},
    );
  }

  @override
  Future<VisualTutorTurnResponseEntity> sendTurn(
    VisualTutorTurnRequestEntity request,
  ) {
    throw const ApiException(
      message: 'Stale client board version. Please refresh or retry.',
      statusCode: 409,
    );
  }
}
