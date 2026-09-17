import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../screens/lessons/local_mvp_limits_scope.dart';
import 'domain/entities/visual_tutor_entities.dart';
import 'local_mvp_limits_fallback.dart';

/// An explicitly device-local evaluator for the single reviewed Limits lesson.
/// No request, student text, answer, credential, or learner history is persisted.
/// The snapshot contains only the approved current board and navigation state.
class LocalMvpLimitsSession {
  LocalMvpLimitsSession._(this._preferences, this._key, this.userId);

  static const sessionId = 'device-local:grade12-limits:v1';
  final SharedPreferences _preferences;
  final String _key;
  final String userId;
  int _step = 0;
  int _version = 1;
  String _representation = 'table';
  String _feedback = 'opening';
  final List<String> _requestIds = [];
  Future<void> _pending = Future<void>.value();

  static Future<LocalMvpLimitsSession> open({required String userId}) async {
    final preferences = await SharedPreferences.getInstance();
    // Namespace by the current account. The key is not sent to any service.
    final key = 'local_limits_v1_${base64Url.encode(utf8.encode(userId))}';
    final result = LocalMvpLimitsSession._(preferences, key, userId);
    try {
      final raw = preferences.getString(key);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final step = data['step'];
        final version = data['version'];
        final representation = data['representation'];
        final feedback = data['feedback'];
        final ids = data['request_ids'];
        if (data['schema'] == 1 &&
            step is int &&
            step >= 0 &&
            step <= 3 &&
            version is int &&
            version > 0 &&
            ['table', 'symbolic'].contains(representation) &&
            [
              'opening',
              'correct',
              'reteach',
              'hint',
              'progress',
              'final',
            ].contains(feedback) &&
            (step == 3) == (feedback == 'final') &&
            ids is List &&
            ids.length <= 32 &&
            ids.every((id) => id is String && _validRequestId(id))) {
          result._step = step;
          result._version = version;
          result._representation = representation as String;
          result._feedback = feedback as String;
          result._requestIds.addAll(ids.cast<String>());
        }
      }
    } catch (_) {
      // A damaged local snapshot recovers to the safe, locked opening.
    }
    await result._save();
    return result;
  }

  VisualTutorSessionEntity get session => VisualTutorSessionEntity(
    sessionId: sessionId,
    userId: userId,
    subject: localMvpSubject,
    topic: localMvpTopic,
    currentStepIndex: _step,
    finalAnswerRevealed: _step == 3,
    metadata: {
      'local_curriculum_demo': true,
      'device_local_session': true,
      'board_version': _version,
      'base_board_version': _version - 1,
    },
  );

  VisualTutorTurnResponseEntity get currentTurn => _buildTurn();

  /// Serialize taps. Retrying a known ID restores the newest board and never
  /// re-evaluates the answer. Older evicted IDs are rejected by board version.
  Future<VisualTutorTurnResponseEntity> turn(
    VisualTutorTurnRequestEntity request,
  ) {
    final result = _pending.then((_) => _apply(request));
    _pending = result.then<void>((_) {}, onError: (Object error, StackTrace stack) {});
    return result;
  }

  Future<VisualTutorTurnResponseEntity> _apply(
    VisualTutorTurnRequestEntity request,
  ) async {
    if (request.userId != userId || request.sessionId != sessionId) {
      throw const LocalLimitsSessionException('local_session_mismatch');
    }
    if (['start', 'retry', 'restore'].contains(request.action)) {
      return currentTurn;
    }
    final id = request.idempotencyKey;
    if (id == null || !_validRequestId(id)) {
      throw const LocalLimitsSessionException('local_request_id_required');
    }
    if (_requestIds.contains(id)) return currentTurn;
    if (request.metadata['client_board_version'] != _version) {
      throw const LocalLimitsSessionException('stale_board_version');
    }
    if (_step == 3) return currentTurn;
    final action = request.action;
    if ([
      'request_hint',
      'explain_differently',
      'stuck',
      'request_stuck_help',
    ].contains(action)) {
      _representation = _representation == 'table' ? 'symbolic' : 'table';
      _feedback = 'hint';
    } else if (['request_final_answer', 'request_answer'].contains(action)) {
      // The approved policy permits only one progressive reveal per request.
      _step++;
      _representation = 'symbolic';
      _feedback = _step == 3 ? 'final' : 'progress';
    } else if ([
      'submit_answer',
      'student_message',
      'submit_step',
      'submit',
      'continue',
    ].contains(action)) {
      final value = request.message.trim().toLowerCase().replaceAll(
        RegExp(r'\s+'),
        '',
      );
      final correct = _step == 1
          ? ['2x+3', '3+2x'].contains(value)
          : ['5', '៥', 'five'].contains(value);
      if (correct) {
        _step++;
        _representation = 'symbolic';
        _feedback = _step == 3 ? 'final' : 'correct';
      } else {
        _feedback = 'reteach';
      }
    } else {
      throw const LocalLimitsSessionException('unsupported_local_action');
    }
    _version++;
    _requestIds.add(id);
    if (_requestIds.length > 32) _requestIds.removeAt(0);
    await _save();
    return currentTurn;
  }

  static bool _validRequestId(String value) =>
      RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(value);

  Future<void> _save() async {
    await _preferences.setString(
      _key,
      jsonEncode({
        'schema': 1,
        'step': _step,
        'version': _version,
        'representation': _representation,
        'feedback': _feedback,
        'request_ids': _requestIds,
      }),
    );
  }

  VisualTutorTurnResponseEntity _buildTurn() {
    final opening = buildLocalMvpLimitsOpeningFallback(sessionId: sessionId);
    const tasks = [
      'តើ f(x) ខិតជិតលេខណា នៅពេល x ខិតជិត 1?',
      'ចំពោះ x ≠ 1 តើ f(x) សម្រួលបានជា​អ្វី?',
      'នៅពេល x ខិតជិត 1 តើ 2x + 3 ខិតជិតលេខណា?',
      '',
    ];
    final task = tasks[_step];
    final message = switch (_feedback) {
      'correct' => 'ត្រឹមត្រូវ។ យើងបន្តមួយជំហានទៀត។',
      'reteach' =>
        _step == 0
            ? 'សង្កេតតម្លៃនៅជិត 1 មិនមែនតម្លៃត្រង់ x = 1 ទេ។'
            : 'ចំពោះ x ≠ 1 អាចសម្រួលកត្តា x − 1 បាន។',
      'hint' =>
        _representation == 'table'
            ? 'សង្កេតតារាងនៅពេល x ខិតជិត 1។'
            : 'ចំពោះ x ≠ 1 អាចសម្រួលកន្សោមនេះបាន។',
      'progress' => 'ឥឡូវសង្កេតកន្សោមដែលសម្រួលរួច។',
      'final' => 'ត្រឹមត្រូវ។ លីមីតនៃអនុគមន៍នេះគឺ 5។',
      _ => opening.displayText,
    };
    final actions = <VisualTutorBoardActionEntity>[];
    if (_step == 3) {
      actions.add(
        VisualTutorBoardActionEntity(
          id: 'limits-final-feedback',
          type: 'final_answer_reveal',
          layoutZone: 'feedback',
          layoutFlow: 'vertical',
          text: message,
        ),
      );
    } else {
      if (_representation == 'table') {
        actions.addAll(opening.boardActions.take(2));
      } else {
        actions.add(
          VisualTutorBoardActionEntity(
            id: 'limits-symbolic-equation',
            type: 'transform_equation',
            durationMs: 650,
            layoutZone: 'working',
            layoutFlow: 'vertical',
            latex: _step == 2
                ? 'f(x) = 2x + 3, x ≠ 1'
                : 'f(x) = ((2x + 3)(x − 1))/(x − 1) = 2x + 3, x ≠ 1',
          ),
        );
      }
      actions.add(
        VisualTutorBoardActionEntity(
          id: 'limits-student-task',
          type: 'student_task',
          sequenceIndex: actions.length,
          layoutZone: 'student_task',
          layoutFlow: 'vertical',
          text: task,
          requiresStudentResponse: true,
        ),
      );
    }
    return VisualTutorTurnResponseEntity(
      sessionId: sessionId,
      turnId: 'device-local-limits-$_version',
      spokenText: _step == 3 ? message : '$message $task',
      displayText: message,
      teachingMode: 'guided_question',
      screenState: _step == 3 ? 'speaking_writing' : 'asking_question',
      tutorStatus: _step == 3 ? 'Ready' : 'Waiting for you',
      finalAnswerLocked: _step != 3,
      studentTask: task,
      board: opening.board,
      boardActions: actions,
      interaction: VisualTutorInteractionEntity(
        type: 'text_response',
        prompt: task,
        expectedAnswerLocked: _step != 3,
        inputEnabled: _step != 3,
        submitLabel: 'បញ្ជូន',
      ),
      allowedActions: _step == 3 ? const [] : opening.allowedActions,
      quickActions: _step == 3 ? const [] : opening.quickActions,
      masterySignal: _step == 0 ? 'exploring' : 'ready_for_next_step',
      metadata: {
        ...opening.metadata,
        'device_local_session': true,
        'board_version': _version,
        'base_board_version': _version - 1,
        'current_step_index': _step,
        'waiting_for_student_input': _step != 3,
        'representation': _representation,
        'authoritative_lesson_state': {
          'lesson_id': localMvpLessonId,
          'active_step_id': 'limits-moment-$_step',
          'current_step_index': _step,
          'final_answer_locked': _step != 3,
        },
      },
    );
  }
}

/// Only fixed public codes are exposed; request content never enters errors.
class LocalLimitsSessionException implements Exception {
  const LocalLimitsSessionException(this.code);
  final String code;
  @override
  String toString() => code;
}
