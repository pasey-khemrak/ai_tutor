import '../entities/visual_tutor_entities.dart';

enum VisualTutorStreamEventType {
  status,
  speechReady,
  boardAction,
  boardPatch,
  turnComplete,
  error,
}

class VisualTutorStreamEventEntity {
  const VisualTutorStreamEventEntity({
    required this.eventId,
    required this.sequence,
    required this.type,
    required this.sessionId,
    required this.turnId,
    required this.boardVersion,
    required this.baseBoardVersion,
    required this.data,
    this.boardAction,
    this.response,
  });

  final String eventId;
  final int sequence;
  final VisualTutorStreamEventType type;
  final String sessionId;
  final String? turnId;
  final int? boardVersion;
  final int? baseBoardVersion;
  final Map<String, dynamic> data;
  final VisualTutorBoardActionEntity? boardAction;
  final VisualTutorTurnResponseEntity? response;
}

abstract class VisualTutorRepository {
  Future<VisualTutorSessionEntity> createSession(
    VisualTutorSessionCreateRequestEntity request,
  );

  Future<VisualTutorSessionEntity> restoreSession(String sessionId);

  Future<VisualTutorTurnResponseEntity> sendTurn(
    VisualTutorTurnRequestEntity request,
  );
}

/// Optional additive capability. Existing repository fakes and the legacy
/// POST endpoint remain valid when a streaming implementation is unavailable.
abstract class VisualTutorStreamingRepository {
  Stream<VisualTutorStreamEventEntity> streamTurn(
    VisualTutorTurnRequestEntity request,
  );
}

/// Additive capability for expert-authored, persisted teaching steps.
abstract class VisualTutorStepRepository {
  Future<VisualTutorStepTurnResponseEntity> submitStepResponse(
    VisualTutorStepTurnRequestEntity request,
  );
}
