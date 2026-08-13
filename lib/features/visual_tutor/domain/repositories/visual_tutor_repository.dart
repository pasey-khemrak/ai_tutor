import '../entities/visual_tutor_entities.dart';

abstract class VisualTutorRepository {
  Future<VisualTutorSessionEntity> createSession(
    VisualTutorSessionCreateRequestEntity request,
  );

  Future<VisualTutorSessionEntity> restoreSession(String sessionId);

  Future<VisualTutorTurnResponseEntity> sendTurn(
    VisualTutorTurnRequestEntity request,
  );
}
