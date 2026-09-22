import 'dart:convert';
import 'package:ai_tutor/core/config/app_config.dart';
import 'package:ai_tutor/core/network/api_client.dart';
import 'package:ai_tutor/features/visual_tutor/data/datasources/visual_tutor_remote_data_source.dart';
import 'package:ai_tutor/features/visual_tutor/data/models/visual_tutor_models.dart';
import 'package:ai_tutor/features/visual_tutor/domain/repositories/visual_tutor_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('VisualTutorRemoteDataSource streaming', () {
    test(
      'accepts ordered safe events and deduplicates duplicate event IDs',
      () async {
        final client = _StreamClient([
          _sseResponse([
            _event('stream-1:0', 0, 'status', data: {'state': 'planning'}),
            _event('stream-1:0', 0, 'status', data: {'state': 'planning'}),
            _event(
              'stream-1:1',
              1,
              'error',
              data: {
                'code': 'STREAM_UNAVAILABLE',
                'message': 'Try again.',
                'recoverable': true,
              },
            ),
          ]),
        ]);
        final remote = _remote(client);

        final events = await remote.streamTurn(_request()).toList();

        expect(events.map((event) => event.eventId), [
          'stream-1:0',
          'stream-1:1',
        ]);
        expect(events.map((event) => event.type), [
          VisualTutorStreamEventType.status,
          VisualTutorStreamEventType.error,
        ]);
        expect(client.requests.single.url.path, '/api/v1/tutor/turn/stream');
      },
    );

    test(
      'rejects a malformed streamed board action before it reaches the board',
      () async {
        final client = _StreamClient([
          _sseResponse([
            _event('stream-1:0', 0, 'status', data: {'state': 'planning'}),
            _event(
              'stream-1:1',
              1,
              'board_action',
              boardVersion: 1,
              baseBoardVersion: 0,
              data: {
                'provisional': true,
                'action': {
                  'id': 'out-of-bounds',
                  'type': 'write_text',
                  'sequence_index': 0,
                  'x': 20001,
                  'text': 'A safe-looking action with unsafe geometry.',
                },
              },
            ),
            _event(
              'stream-1:2',
              2,
              'error',
              data: {
                'code': 'STREAM_UNAVAILABLE',
                'message': 'Try again.',
                'recoverable': true,
              },
            ),
          ]),
        ]);

        final events = await _remote(client).streamTurn(_request()).toList();

        expect(events.map((event) => event.type), [
          VisualTutorStreamEventType.status,
          VisualTutorStreamEventType.error,
        ]);
      },
    );

    test(
      'rejects a patch with cross-step identity or an unbounded pause',
      () async {
        final client = _StreamClient([
          _sseResponse([
            _event(
              'stream-1:0',
              0,
              'board_patch',
              boardVersion: 2,
              baseBoardVersion: 1,
              data: {
                'board_update_mode': 'patch',
                'actions': [
                  {
                    'id': 'pause',
                    'action_id': 'pause',
                    'type': 'pause_marker',
                    'sequence_index': 0,
                    'duration_ms': 999999,
                    'problem_instance_id': 'problem-a',
                    'active_step_id': 'different-step',
                    'board_version': 2,
                    'base_board_version': 1,
                  },
                ],
              },
            ),
            _event(
              'stream-1:1',
              1,
              'error',
              data: {
                'code': 'STREAM_UNAVAILABLE',
                'message': 'Try again.',
                'recoverable': true,
              },
            ),
          ]),
        ]);

        final events = await _remote(client).streamTurn(_request()).toList();
        expect(events.map((event) => event.type), [
          VisualTutorStreamEventType.error,
        ]);
      },
    );

    test('reconnects with Last-Event-ID after a partial stream', () async {
      final client = _StreamClient([
        _sseResponse([
          _event('stream-1:0', 0, 'status', data: {'state': 'planning'}),
        ]),
        _sseResponse([
          _event(
            'stream-1:1',
            1,
            'error',
            data: {
              'code': 'TIMEOUT',
              'message': 'Try again.',
              'recoverable': true,
            },
          ),
        ]),
      ]);

      final events = await _remote(client).streamTurn(_request()).toList();

      expect(events.map((event) => event.eventId), [
        'stream-1:0',
        'stream-1:1',
      ]);
      expect(client.requests, hasLength(2));
      expect(client.requests[1].headers['last-event-id'], 'stream-1:0');
    });

    test(
      'parses turn_complete into the existing public turn response entity',
      () async {
        final publicTurn = _publicTurn();
        final client = _StreamClient([
          _sseResponse([
            _event(
              'stream-1:0',
              0,
              'turn_complete',
              boardVersion: 4,
              baseBoardVersion: 3,
              data: {'response': publicTurn},
            ),
          ]),
        ]);

        final events = await _remote(client).streamTurn(_request()).toList();

        expect(events, hasLength(1));
        expect(events.single.type, VisualTutorStreamEventType.turnComplete);
        expect(events.single.response?.sessionId, 'session-public');
        expect(events.single.response?.boardActions, hasLength(2));
        expect(
          events.single.response?.studentTask,
          'What operation cancels -5?',
        );
      },
    );

    test(
      'recovers an invalid turn_complete sibling without exposing verifier fields',
      () async {
        final publicTurn = _publicTurn();
        final teachingPlan = Map<String, dynamic>.from(
          publicTurn['teaching_plan'] as Map,
        );
        teachingPlan['visible_board_actions'] = [
          ...(teachingPlan['visible_board_actions'] as List),
          {
            'id': 'unsafe-widget',
            'type': 'write_text',
            'sequence_index': 1,
            'text': 'This action must not reach the renderer.',
            'widget_code': 'Text("unsafe")',
          },
        ];
        teachingPlan['active_student_task'] = {
          ...Map<String, dynamic>.from(
            teachingPlan['active_student_task'] as Map,
          ),
          'accepted_answer_forms': ['subtract five'],
        };
        publicTurn['teaching_plan'] = teachingPlan;
        final client = _StreamClient([
          _sseResponse([
            _event(
              'stream-1:0',
              0,
              'turn_complete',
              boardVersion: 4,
              baseBoardVersion: 3,
              data: {'response': publicTurn},
            ),
          ]),
        ]);

        final event = (await _remote(
          client,
        ).streamTurn(_request()).toList()).single;
        final actions = event.response!.boardActions;

        expect(actions.map((action) => action.id), contains('equation'));
        expect(actions.map((action) => action.type), contains('show_feedback'));
        expect(
          actions.where((action) => action.type == 'student_task'),
          hasLength(1),
        );
        expect(
          actions.any(
            (action) => action.metadata.containsKey('accepted_answer_forms'),
          ),
          isFalse,
        );
      },
    );

    test('falls through as an ApiException when opening SSE fails', () async {
      final client = _StreamClient([
        http.StreamedResponse(
          http.ByteStream.fromBytes(utf8.encode('{"message":"offline"}')),
          503,
        ),
      ]);

      expect(
        _remote(client).streamTurn(_request()).toList(),
        throwsA(isA<ApiException>()),
      );
    });
  });
}

VisualTutorRemoteDataSource _remote(http.Client client) =>
    VisualTutorRemoteDataSource(
      apiClient: ApiClient(
        config: const AppConfig(
          environment: AppEnvironment.development,
          backendBaseUrl: 'http://example.test/api/v1',
          aiServiceBaseUrl: 'http://example.test/api/v1',
          useDemoAuth: false,
        ),
        httpClient: client,
      ),
    );

const _requestValue = VisualTutorTurnRequestModel(
  userId: 'student-1',
  sessionId: 'session-1',
  subject: 'Mathematics',
  topic: 'Linear Equations',
  message: '2x + 5 = 15',
  inputType: 'text',
  action: 'student_message',
  currentState: VisualTutorTurnStateModel(),
  allowFinalAnswer: false,
  idempotencyKey: 'stream-key-1',
  metadata: {'client_board_version': 0, 'client_base_board_version': 0},
);

VisualTutorTurnRequestModel _request() => _requestValue;

http.StreamedResponse _sseResponse(List<Map<String, dynamic>> events) {
  final payload = events.map((event) {
    return 'id: ${event['event_id']}\n'
        'event: visual_tutor\n'
        'data: ${jsonEncode(event)}\n\n';
  }).join();
  return http.StreamedResponse(
    http.ByteStream.fromBytes(utf8.encode(payload)),
    200,
    headers: const {'content-type': 'text/event-stream'},
  );
}

Map<String, dynamic> _event(
  String eventId,
  int sequence,
  String type, {
  int? boardVersion,
  int? baseBoardVersion,
  required Map<String, dynamic> data,
}) => {
  'schema_version': 1,
  'stream_id': 'stream-1',
  'event_id': eventId,
  'sequence': sequence,
  'type': type,
  'session_id': 'session-1',
  'turn_id': null,
  'board_version': boardVersion,
  'base_board_version': baseBoardVersion,
  'emitted_at': '2026-08-24T00:00:00Z',
  'data': data,
};

Map<String, dynamic> _publicTurn() => {
  'schema_version': 1,
  'session_id': 'session-public',
  'turn_id': 'turn-public',
  'board_version': 4,
  'tutor_status': 'Waiting for you',
  'teaching_plan': {
    'schema_version': 1,
    'representation': 'equation_transformation',
    'learning_objective': 'Use an inverse operation.',
    'teaching_message': 'Balance both sides.',
    'visible_board_actions': [
      {
        'id': 'equation',
        'type': 'write_equation',
        'sequence_index': 0,
        'latex': '2x - 5 = 20',
      },
    ],
    'active_student_task': {
      'id': 'task',
      'type': 'student_task',
      'sequence_index': 1,
      'text': 'What operation cancels -5?',
      'requires_student_response': true,
      'task_type': 'conceptual_operation',
      'accepted_answer_forms': ['operation words'],
    },
    'allowed_student_actions': ['submit_answer', 'request_hint'],
    'hidden_answer_policy': {
      'mode': 'hidden',
      'deterministic_policy_permits_final_reveal': false,
    },
    'next_state_policy': {
      'correct': 'continue',
      'invalid': 'reteach',
      'incomplete': 'ask_for_work',
      'stuck': 'reteach',
      'hint': 'ask_for_work',
      'explain_differently': 'reteach',
    },
  },
  'verification': {
    'status': 'cannot_verify',
    'verified': false,
    'concise_evidence': 'No submitted step yet.',
    'student_facing_feedback': 'Submit your next step.',
  },
  'recovery': {'state': 'ready'},
};

class _StreamClient extends http.BaseClient {
  _StreamClient(this._responses);

  final List<http.StreamedResponse> _responses;
  final List<http.BaseRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    if (_responses.isEmpty) {
      throw StateError('No fake stream response configured');
    }
    return _responses.removeAt(0);
  }
}
