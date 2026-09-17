import 'dart:convert';

import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/local_mvp_limits_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  VisualTutorTurnRequestEntity request(
    LocalMvpLimitsSession session, {
    String message = '',
    String action = 'student_message',
    String id = 'turn-1',
    int? version,
  }) => VisualTutorTurnRequestEntity(
    userId: session.userId,
    sessionId: LocalMvpLimitsSession.sessionId,
    action: action,
    message: message,
    idempotencyKey: id,
    metadata: {
      'client_board_version':
          version ?? session.currentTurn.metadata['board_version'],
    },
  );

  test(
    'offline opening is declarative, waiting, and final answer locked',
    () async {
      final local = await LocalMvpLimitsSession.open(userId: 'test');
      final turn = local.currentTurn;
      expect(turn.boardActions.map((action) => action.type), [
        'write_equation',
        'show_table',
        'student_task',
      ]);
      expect(turn.interaction!.inputEnabled, isTrue);
      expect(turn.finalAnswerLocked, isTrue);
      expect(
        turn.boardActions.where(
          (action) => action.type == 'final_answer_reveal',
        ),
        isEmpty,
      );
      expect(turn.displayText, isNot(contains('គឺ 5')));
    },
  );

  test('correct 5 advances exactly one moment without final answer', () async {
    final local = await LocalMvpLimitsSession.open(userId: 'test');
    final result = await local.turn(request(local, message: '5'));
    expect(local.session.currentStepIndex, 1);
    expect(result.displayText, 'ត្រឹមត្រូវ។ យើងបន្តមួយជំហានទៀត។');
    expect(result.boardActions.map((action) => action.type), [
      'transform_equation',
      'student_task',
    ]);
    expect(result.finalAnswerLocked, isTrue);
  });

  test(
    'wrong response reteaches one misconception without advancing',
    () async {
      final local = await LocalMvpLimitsSession.open(userId: 'test');
      final result = await local.turn(
        request(local, message: 'private-input-wrong'),
      );
      expect(local.session.currentStepIndex, 0);
      expect(
        result.displayText,
        'សង្កេតតម្លៃនៅជិត 1 មិនមែនតម្លៃត្រង់ x = 1 ទេ។',
      );
      expect(result.finalAnswerLocked, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().map(prefs.get).join(),
        isNot(contains('private-input-wrong')),
      );
    },
  );

  test(
    'hint and explain differently alternate approved representations',
    () async {
      final local = await LocalMvpLimitsSession.open(userId: 'test');
      final hint = await local.turn(request(local, action: 'request_hint'));
      expect(hint.metadata['representation'], 'symbolic');
      final explain = await local.turn(
        request(local, action: 'explain_differently', id: 'turn-2'),
      );
      expect(explain.metadata['representation'], 'table');
      expect(local.session.currentStepIndex, 0);
      expect(explain.finalAnswerLocked, isTrue);
    },
  );

  test(
    'refresh restores exact board and retry cannot double advance',
    () async {
      final local = await LocalMvpLimitsSession.open(userId: 'test');
      final originalRequest = request(local, message: '5');
      final advanced = await local.turn(originalRequest);
      final restored = await LocalMvpLimitsSession.open(userId: 'test');
      expect(restored.currentTurn.turnId, advanced.turnId);
      expect(
        restored.currentTurn.boardActions.first.latex,
        advanced.boardActions.first.latex,
      );
      final retried = await restored.turn(originalRequest);
      expect(retried.turnId, advanced.turnId);
      expect(restored.session.currentStepIndex, 1);
      final retry = await restored.turn(request(restored, action: 'retry'));
      expect(retry.turnId, advanced.turnId);
    },
  );

  test(
    'late stale action is rejected and cannot overwrite current board',
    () async {
      final local = await LocalMvpLimitsSession.open(userId: 'test');
      final stale = request(local, message: '2x+3', id: 'stale');
      final advanced = await local.turn(request(local, message: '5'));
      await expectLater(
        local.turn(stale),
        throwsA(isA<LocalLimitsSessionException>()),
      );
      expect(local.currentTurn.turnId, advanced.turnId);
      expect(local.session.currentStepIndex, 1);
    },
  );

  test('concurrent duplicate taps advance once', () async {
    final local = await LocalMvpLimitsSession.open(userId: 'test');
    final turn = request(local, message: '5');
    final results = await Future.wait([local.turn(turn), local.turn(turn)]);
    expect(results.first.turnId, results.last.turnId);
    expect(local.session.currentStepIndex, 1);
  });

  test(
    'policy reveals only after three approved progressive moments',
    () async {
      final local = await LocalMvpLimitsSession.open(userId: 'test');
      for (var index = 0; index < 3; index++) {
        final result = await local.turn(
          request(local, action: 'request_final_answer', id: 'reveal-$index'),
        );
        expect(result.finalAnswerLocked, index != 2);
        expect(
          result.boardActions.any(
            (action) => action.type == 'final_answer_reveal',
          ),
          index == 2,
        );
      }
    },
  );

  test(
    'account scope and corrupt snapshot safely recover locked opening',
    () async {
      final local = await LocalMvpLimitsSession.open(userId: 'test');
      await local.turn(request(local, message: '5'));
      final other = await LocalMvpLimitsSession.open(userId: 'other');
      expect(other.session.currentStepIndex, 0);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'local_limits_v1_${base64Url.encode(utf8.encode('test'))}',
        '{broken',
      );
      final restored = await LocalMvpLimitsSession.open(userId: 'test');
      expect(restored.session.currentStepIndex, 0);
      expect(restored.currentTurn.finalAnswerLocked, isTrue);
    },
  );
}
