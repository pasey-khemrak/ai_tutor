import 'dart:async';
import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../domain/repositories/visual_tutor_repository.dart';
import '../models/visual_tutor_models.dart';
import '../../presentation/live_board_state.dart';

class VisualTutorRemoteDataSource {
  const VisualTutorRemoteDataSource({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<VisualTutorSessionModel> createSession(
    VisualTutorSessionCreateRequestModel request,
  ) async {
    final json = await _apiClient.post(
      '/tutor/sessions',
      body: request.toJson(),
    );
    return VisualTutorSessionModel.fromJson(json);
  }

  Future<VisualTutorTurnResponseModel> sendTurn(
    VisualTutorTurnRequestModel request,
  ) async {
    final json = await _apiClient.post('/tutor/turn', body: request.toJson());
    return VisualTutorTurnResponseModel.fromJson(json);
  }

  Future<VisualTutorStepTurnResponseModel> submitStepResponse(
    VisualTutorStepTurnRequestModel request,
  ) async {
    final json = await _apiClient.post(
      '/tutor/turn/step',
      body: request.toJson(),
    );
    return VisualTutorStepTurnResponseModel.fromJson(json);
  }

  Stream<VisualTutorStreamEventEntity> streamTurn(
    VisualTutorTurnRequestModel request,
  ) async* {
    final seen = <String>{};
    String? lastEventId;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _apiClient.postStream(
          '/tutor/turn/stream',
          body: request.toJson(),
          lastEventId: lastEventId,
        );
        var buffer = '';
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          buffer += chunk;
          final frames = buffer.split(RegExp(r'\r?\n\r?\n'));
          buffer = frames.removeLast();
          for (final frame in frames) {
            final event = _parseStreamFrame(frame);
            if (event == null || !seen.add(event.eventId)) continue;
            lastEventId = event.eventId;
            yield event;
            if (event.type == VisualTutorStreamEventType.turnComplete ||
                event.type == VisualTutorStreamEventType.error) {
              return;
            }
          }
        }
        if (attempt == 0) continue;
        throw const FormatException(
          'Tutor stream ended before a final response.',
        );
      } on ApiException {
        rethrow;
      } catch (_) {
        if (attempt == 1) rethrow;
      }
    }
  }

  Future<VisualTutorSessionModel> restoreSession(String sessionId) async {
    final json = await _apiClient.get('/tutor/sessions/$sessionId');
    return VisualTutorSessionModel.fromJson(json);
  }
}

VisualTutorStreamEventEntity? _parseStreamFrame(String frame) {
  final dataLines = frame
      .split(RegExp(r'\r?\n'))
      .where((line) => line.startsWith('data:'))
      .map((line) => line.substring(5).trimLeft())
      .toList();
  if (dataLines.isEmpty) return null;
  final raw = jsonDecode(dataLines.join('\n'));
  if (raw is! Map) return null;
  final map = Map<String, dynamic>.from(raw);
  const allowed = {
    'schema_version',
    'stream_id',
    'event_id',
    'sequence',
    'type',
    'session_id',
    'turn_id',
    'board_version',
    'base_board_version',
    'emitted_at',
    'data',
  };
  if (map['schema_version'] != 1 ||
      map.keys.any((key) => !allowed.contains(key)) ||
      map['event_id'] is! String ||
      map['sequence'] is! int ||
      map['session_id'] is! String ||
      map['data'] is! Map) {
    return null;
  }
  final type = switch (map['type']) {
    'status' => VisualTutorStreamEventType.status,
    'speech_ready' => VisualTutorStreamEventType.speechReady,
    'board_action' => VisualTutorStreamEventType.boardAction,
    'board_patch' => VisualTutorStreamEventType.boardPatch,
    'turn_complete' => VisualTutorStreamEventType.turnComplete,
    'error' => VisualTutorStreamEventType.error,
    _ => null,
  };
  if (type == null) return null;
  final data = Map<String, dynamic>.from(map['data'] as Map);
  VisualTutorBoardActionModel? action;
  VisualTutorTurnResponseModel? response;
  if (type == VisualTutorStreamEventType.boardAction) {
    final rawAction = data['action'];
    if (rawAction is! Map ||
        map['board_version'] is! int ||
        map['base_board_version'] is! int) {
      return null;
    }
    if (rawAction['action_id'] != rawAction['id'] ||
        rawAction['board_version'] != map['board_version'] ||
        rawAction['base_board_version'] != map['base_board_version'] ||
        rawAction['problem_instance_id'] is! String ||
        rawAction['active_step_id'] is! String) {
      return null;
    }
    final actionMap = Map<String, dynamic>.from(rawAction);
    if (!_hasStrictActionTiming(actionMap)) return null;
    action = VisualTutorBoardActionModel.fromJson(actionMap);
    if (!isValidBoardAction(action)) return null;
  }
  if (type == VisualTutorStreamEventType.boardPatch) {
    final actions = data['actions'];
    if (map['board_version'] is! int ||
        map['base_board_version'] is! int ||
        data['board_update_mode'] != 'patch' ||
        actions is! List ||
        actions.length > 24) {
      return null;
    }
    for (final rawAction in actions) {
      if (rawAction is! Map) return null;
      final actionMap = Map<String, dynamic>.from(rawAction);
      if (actionMap['action_id'] != actionMap['id'] ||
          actionMap['board_version'] != map['board_version'] ||
          actionMap['base_board_version'] != map['base_board_version'] ||
          actionMap['problem_instance_id'] is! String ||
          actionMap['active_step_id'] is! String ||
          !_hasStrictActionTiming(actionMap) ||
          !isValidBoardAction(
            VisualTutorBoardActionModel.fromJson(actionMap),
          )) {
        return null;
      }
    }
  }
  if (type == VisualTutorStreamEventType.turnComplete) {
    final rawResponse = data['response'];
    if (rawResponse is! Map) return null;
    response = VisualTutorTurnResponseModel.fromJson(
      Map<String, dynamic>.from(rawResponse),
    );
  }
  return VisualTutorStreamEventEntity(
    eventId: map['event_id'] as String,
    sequence: map['sequence'] as int,
    type: type,
    sessionId: map['session_id'] as String,
    turnId: map['turn_id'] as String?,
    boardVersion: map['board_version'] as int?,
    baseBoardVersion: map['base_board_version'] as int?,
    data: data,
    boardAction: action,
    response: response,
  );
}

bool _hasStrictActionTiming(Map<String, dynamic> action) {
  final duration = action['duration_ms'];
  if (duration != null &&
      (duration is! int || duration < 0 || duration > 8000)) {
    return false;
  }
  final sequence = action['sequence_index'];
  if (sequence != null &&
      (sequence is! int || sequence < 0 || sequence > 10000)) {
    return false;
  }
  final type = action['type'];
  if (type == 'pause_marker' && (duration is! int || duration < 150)) {
    return false;
  }
  return type != 'speak_marker' || duration == null || duration == 0;
}
