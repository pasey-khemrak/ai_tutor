import '../../domain/entities/visual_tutor_entities.dart';
import '../../domain/repositories/visual_tutor_repository.dart';
import '../datasources/visual_tutor_remote_data_source.dart';
import '../models/visual_tutor_models.dart';

class VisualTutorRepositoryImpl implements VisualTutorRepository {
  const VisualTutorRepositoryImpl({required this.remote});

  final VisualTutorRemoteDataSource remote;

  @override
  Future<VisualTutorSessionEntity> createSession(
    VisualTutorSessionCreateRequestEntity request,
  ) {
    return remote.createSession(
      VisualTutorSessionCreateRequestModel(
        userId: request.userId,
        subject: request.subject,
        sessionMode: request.sessionMode,
        topic: request.topic,
        problemText: request.problemText,
        metadata: request.metadata,
      ),
    );
  }

  @override
  Future<VisualTutorSessionEntity> restoreSession(String sessionId) {
    return remote.restoreSession(sessionId);
  }

  @override
  Future<VisualTutorTurnResponseEntity> sendTurn(
    VisualTutorTurnRequestEntity request,
  ) {
    return remote.sendTurn(
      VisualTutorTurnRequestModel(
        userId: request.userId,
        sessionId: request.sessionId,
        subject: request.subject,
        topic: request.topic,
        message: request.message,
        inputType: request.inputType,
        locale: request.locale,
        action: request.action,
        studentIntent: request.studentIntent,
        currentState: request.currentState,
        hintCount: request.hintCount,
        studentSubmittedStep: request.studentSubmittedStep,
        allowFinalAnswer: request.allowFinalAnswer,
        idempotencyKey: request.idempotencyKey,
        metadata: request.metadata,
      ),
    );
  }
}
