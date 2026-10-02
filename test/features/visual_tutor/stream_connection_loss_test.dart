// What the tutor stream does when a Cambodian mobile connection misbehaves.
//
// A dropped SSE stream is the normal case here, not the edge case, so each
// failure mode gets a pinned behaviour: resume where the board left off,
// surface an honest state, and never replay a solution the student already
// watched being drawn.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ai_tutor/core/config/app_config.dart';
import 'package:ai_tutor/core/network/api_client.dart';
import 'package:ai_tutor/features/visual_tutor/data/datasources/visual_tutor_remote_data_source.dart';
import 'package:ai_tutor/features/visual_tutor/data/models/visual_tutor_models.dart';
import 'package:ai_tutor/features/visual_tutor/domain/repositories/visual_tutor_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const _config = AppConfig(
  environment: AppEnvironment.production,
  backendBaseUrl: 'http://localhost:4000/api/v1',
  aiServiceBaseUrl: 'http://localhost:8001/api/v1',
  useDemoAuth: false,
  useDemoTutorData: false,
);

String _frame({
  required String eventId,
  required int sequence,
  required String type,
  Map<String, dynamic> data = const {},
  int boardVersion = 1,
  int baseBoardVersion = 0,
}) {
  final payload = <String, dynamic>{
    'schema_version': 1,
    'stream_id': 'stream-1',
    'event_id': eventId,
    'sequence': sequence,
    'type': type,
    'session_id': 'session-1',
    'turn_id': 'turn-1',
    'board_version': boardVersion,
    'base_board_version': baseBoardVersion,
    'emitted_at': '2026-09-27T00:00:00.000Z',
    'data': data,
  };
  return 'event: visual_tutor\ndata: ${jsonEncode(payload)}\n\n';
}

/// `turn_complete` carries the authoritative turn, so the parser requires one.
Map<String, dynamic> _turnComplete() => {
  'response': jsonDecode(
    File(
      'test/features/visual_tutor/fixtures/worked_solution_turn.json',
    ).readAsStringSync(),
  ),
};

Map<String, dynamic> _boardAction(String id, int sequence) => {
  'action': {
    'id': id,
    'action_id': id,
    'type': 'write_text',
    'text': 'Step $sequence',
    'sequence_index': sequence,
    'duration_ms': 0,
    'problem_instance_id': 'problem-1',
    'active_step_id': 'step-1',
    'board_version': 1,
    'base_board_version': 0,
  },
};

/// An SSE body that ends mid-turn, as a dropped connection does.
http.StreamedResponse _truncatedStream(List<String> frames) {
  final controller = StreamController<List<int>>();
  for (final frame in frames) {
    controller.add(utf8.encode(frame));
  }
  controller.close();
  return http.StreamedResponse(controller.stream, 200);
}

void main() {
  late List<String?> sentLastEventIds;

  VisualTutorRemoteDataSource dataSourceWith(
    List<http.StreamedResponse Function()> responses,
  ) {
    sentLastEventIds = [];
    var call = 0;
    final client = _RecordingApiClient(
      config: _config,
      onStream: (lastEventId) {
        sentLastEventIds.add(lastEventId);
        final index = call < responses.length ? call : responses.length - 1;
        call++;
        return responses[index]();
      },
    );
    return VisualTutorRemoteDataSource(apiClient: client);
  }

  group('a connection lost mid-turn', () {
    test('resumes from the last event instead of restarting the board', () async {
      final first = [
        _frame(eventId: 'e1', sequence: 1, type: 'board_action', data: _boardAction('a1', 1)),
        _frame(eventId: 'e2', sequence: 2, type: 'board_action', data: _boardAction('a2', 2)),
      ];
      final second = [
        _frame(eventId: 'e3', sequence: 3, type: 'board_action', data: _boardAction('a3', 3)),
        _frame(eventId: 'e4', sequence: 4, type: 'turn_complete', data: _turnComplete()),
      ];

      final source = dataSourceWith([
        () => _truncatedStream(first),
        () => _truncatedStream(second),
      ]);

      final events = await _serverEventIds(source.streamTurn(_request()));

      // The second attempt tells the server where the board got to, so the
      // student does not watch the first two steps drawn again.
      expect(sentLastEventIds, [null, 'e2']);
      expect(events, ['e1', 'e2', 'e3', 'e4']);
    });

    test('never yields an event the board already drew', () async {
      // A server that replays the whole turn on resume must not repaint it.
      final all = [
        _frame(eventId: 'e1', sequence: 1, type: 'board_action', data: _boardAction('a1', 1)),
        _frame(eventId: 'e2', sequence: 2, type: 'board_action', data: _boardAction('a2', 2)),
      ];
      final replay = [
        ...all,
        _frame(eventId: 'e3', sequence: 3, type: 'turn_complete', data: _turnComplete()),
      ];

      final source = dataSourceWith([
        () => _truncatedStream(all),
        () => _truncatedStream(replay),
      ]);

      final events = await _serverEventIds(source.streamTurn(_request()));

      expect(events, ['e1', 'e2', 'e3']);
    });
  });

  group('a connection that never delivers', () {
    test('surfaces the failure so the caller can fall back', () async {
      final source = dataSourceWith([
        () => throw const ApiException(
          message: 'Connection timed out. Please check your internet connection.',
          statusCode: 408,
        ),
      ]);

      await expectLater(
        source.streamTurn(_request()).toList(),
        throwsA(isA<ApiException>()),
      );
    });

    test('retries a transport failure before giving up', () async {
      var attempts = 0;
      final source = dataSourceWith([
        () {
          attempts++;
          throw const SocketExceptionStub();
        },
      ]);

      await expectLater(
        source.streamTurn(_request()).toList(),
        throwsA(isA<SocketExceptionStub>()),
      );
      expect(attempts, greaterThan(1), reason: 'a flaky link deserves a retry');
    });
  });

  group('a timeout, the most likely failure on mobile data', () {
    test('retries with the last event id rather than restarting the turn', () async {
      // postStream raises a 408 ApiException on timeout. That is a dropped
      // link, not a rejected request, so it must resume like any other drop.
      var attempts = 0;
      final source = dataSourceWith([
        () {
          attempts++;
          if (attempts == 1) {
            return _truncatedStream([
              _frame(eventId: 'e1', sequence: 1, type: 'board_action', data: _boardAction('a1', 1)),
            ]);
          }
          if (attempts == 2) {
            throw const ApiException(
              message: 'Connection timed out. Please check your internet connection.',
              statusCode: 408,
            );
          }
          return _truncatedStream([
            _frame(eventId: 'e2', sequence: 2, type: 'turn_complete', data: _turnComplete()),
          ]);
        },
      ]);

      final events = await _serverEventIds(source.streamTurn(_request()));

      expect(events, ['e1', 'e2']);
      expect(sentLastEventIds.last, 'e1');
    });

    test('does not retry a request the server refused', () async {
      // 401/403/409 are verdicts, not dropped links. Retrying them wastes the
      // student's data and hides the real problem.
      var attempts = 0;
      final source = dataSourceWith([
        () {
          attempts++;
          throw const ApiException(message: 'Board conflict', statusCode: 409);
        },
      ]);

      await expectLater(
        source.streamTurn(_request()).toList(),
        throwsA(isA<ApiException>()),
      );
      expect(attempts, 1);
    });
  });

  test('a drop tells the student the board is resuming, not stalled', () async {
    final source = dataSourceWith([
      () => _truncatedStream([
        _frame(eventId: 'e1', sequence: 1, type: 'board_action', data: _boardAction('a1', 1)),
      ]),
      () => _truncatedStream([
        _frame(eventId: 'e2', sequence: 2, type: 'turn_complete', data: _turnComplete()),
      ]),
    ]);

    final events = await source.streamTurn(_request()).toList();
    final reconnecting = events.where(
      (event) =>
          event.type == VisualTutorStreamEventType.status &&
          event.data['state'] == reconnectingStreamState,
    );

    expect(
      reconnecting,
      isNotEmpty,
      reason: 'a still board with no explanation reads as a broken app',
    );
  });

  test('a stream that ends with no events at all still fails loudly', () async {
    final source = dataSourceWith([() => _truncatedStream(const [])]);

    await expectLater(source.streamTurn(_request()).toList(), throwsA(anything));
  });
}

/// Event ids the server sent, excluding the client's own reconnect notices.
Future<List<String>> _serverEventIds(
  Stream<VisualTutorStreamEventEntity> stream,
) async => stream
    .where((event) => event.data['state'] != reconnectingStreamState)
    .map((event) => event.eventId)
    .toList();

VisualTutorTurnRequestModel _request() => const VisualTutorTurnRequestModel(
  userId: 'student-1',
  sessionId: 'session-1',
  subject: 'Mathematics',
  message: 'Solve 3x + 7 = 22',
  action: 'submit_problem',
);

class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient({required super.config, required this.onStream})
    : super(tokenProvider: _noToken);

  final http.StreamedResponse Function(String? lastEventId) onStream;

  static Future<String?> _noToken() async => 'token';

  @override
  Future<http.StreamedResponse> postStream(
    String path, {
    Object? body,
    String? lastEventId,
  }) async => onStream(lastEventId);
}
