import 'package:ai_tutor/features/visual_tutor/data/models/visual_tutor_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'parses compact public tutor turns without legacy board or private metadata',
    () {
      final response = VisualTutorTurnResponseModel.fromJson({
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
          'status': 'correct',
          'verified': true,
          'concise_evidence': 'The operation keeps both sides equal.',
          'student_facing_feedback': 'Correct. Add 5 to both sides.',
        },
      });

      expect(response.boardActions, hasLength(2));
      expect(response.boardActions.first.latex, '2x - 5 = 20');
      expect(response.boardActions.last.text, 'What operation cancels -5?');
      expect(response.canvasActions, isEmpty);
      expect(response.verification?.status, 'correct');
      expect(response.metadata['solver_facts'], isNull);
    },
  );

  test('retains public schema-v2 lesson state for the next tutor turn', () {
    final valid = _compactPublicTurn();
    final lessonState = {
      'problem_instance_id': 'problem-1',
      'lesson_id': 'lesson-problem-1',
      'active_step_id': 'lesson-problem-1:step-1:task',
      'current_step_index': 1,
      'expected_student_action_id': 'task',
      'teaching_stage': 'waiting_for_student',
      'lesson_state': 'ask',
      'final_answer_locked': true,
      'board_version': 2,
      'base_board_version': 1,
    };
    final response = VisualTutorTurnResponseModel.fromJson({
      ...valid,
      'schema_version': 2,
      'board_version': 2,
      'base_board_version': 1,
      'board_update_mode': 'replace',
      'lesson_state': lessonState,
      'teaching_plan': {
        ...(valid['teaching_plan'] as Map<String, dynamic>),
        'visible_board_actions': [
          {
            ...(valid['teaching_plan']
                    as Map<String, dynamic>)['visible_board_actions'][0]
                as Map<String, dynamic>,
            'problem_instance_id': 'problem-1',
            'active_step_id': lessonState['active_step_id'],
            'action_id': 'equation',
            'board_version': 2,
            'base_board_version': 1,
          },
        ],
        'active_student_task': {
          ...(valid['teaching_plan']
                  as Map<String, dynamic>)['active_student_task']
              as Map<String, dynamic>,
          'problem_instance_id': 'problem-1',
          'active_step_id': lessonState['active_step_id'],
          'action_id': 'task',
          'board_version': 2,
          'base_board_version': 1,
        },
      },
    });

    final state =
        response.metadata['authoritative_lesson_state'] as Map<String, dynamic>;
    expect(state['current_step_index'], 1);
    expect(state['active_step_id'], lessonState['active_step_id']);
    expect(response.metadata['board_version'], 2);
    expect(response.metadata['base_board_version'], 1);
  });

  test(
    'production public response rejects legacy and private top-level fields',
    () {
      final valid = _compactPublicTurn();

      expect(
        () => VisualTutorTurnResponseModel.fromJson({
          ...valid,
          'board_actions': [
            {'id': 'legacy', 'type': 'write_text', 'text': 'Never render this'},
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => VisualTutorTurnResponseModel.fromJson({
          ...valid,
          'metadata': {
            'solver_facts': {'solution_set': 'x = 5'},
          },
        }),
        throwsFormatException,
      );
    },
  );

  test(
    'legacy response parsing requires explicit compatibility version zero',
    () {
      expect(
        () => VisualTutorTurnResponseModel.fromJson({
          'session_id': 'legacy-session',
          'turn_id': 'legacy-turn',
          'display_text': 'Old response',
          'spoken_text': 'Old response',
          'teaching_mode': 'guided_question',
          'board': {'type': 'equation'},
        }),
        throwsFormatException,
      );
    },
  );

  test(
    'production public response recovers an invalid action without discarding the turn',
    () {
      final valid = _compactPublicTurn();
      final plan = Map<String, dynamic>.from(valid['teaching_plan'] as Map);
      final actions = List<Map<String, dynamic>>.from(
        (plan['visible_board_actions'] as List).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
      actions[0]['arbitrary_widget'] = 'InjectedWidget()';
      plan['visible_board_actions'] = actions;

      final response = VisualTutorTurnResponseModel.fromJson({
        ...valid,
        'teaching_plan': plan,
      });
      expect(
        response.boardActions!.map((action) => action.type),
        contains('show_feedback'),
      );
      expect(
        response.boardActions!.where((action) => action.type == 'student_task'),
        hasLength(1),
      );
    },
  );

  test('VisualTutorTurnResponseModel parses structured live response JSON', () {
    final response = VisualTutorTurnResponseModel.fromJson({
      'api_compatibility_version': 0,
      'session_id': 'session-1',
      'turn_id': 'turn-1',
      'screen_state': 'speaking_writing',
      'tutor_status': 'Writing...',
      'spoken_text': 'Let us look at the first step.',
      'display_text': 'Let us look at the first step.',
      'teaching_mode': 'guided_question',
      'student_intent': 'new_problem',
      'final_answer_locked': true,
      'student_task': 'What should we remove first?',
      'board': {
        'type': 'equation_steps',
        'title': 'Linear Equation',
        'items': [
          {'label': 'Problem', 'content': '2x + 5 = 15', 'status': 'active'},
        ],
      },
      'speech': {
        'text': 'Let us look at the first step.',
        'language': 'en',
        'tts_status': 'pending',
      },
      'teaching_stage': {
        'stage_state': 'waiting_for_student',
        'lesson_state': 'ask',
        'turn_goal': 'Ask first operation',
      },
      'board_actions': [
        {
          'id': 'a1',
          'type': 'write_equation',
          'sequence_index': 0,
          'duration_ms': 400,
          'latex': '2x + 5 = 15',
        },
        {
          'id': 'a2',
          'type': 'highlight',
          'sequence_index': 1,
          'target_id': 'term-plus-5',
          'locked': true,
        },
      ],
      'canvas_actions': [
        {'id': 'legacy-canvas-action', 'type': 'write_text', 'text': 'Step 1'},
      ],
      'teaching_board': {
        'id': 'board-1',
        'elements': [
          {'id': 'e1', 'type': 'equation', 'latex': '2x + 5 = 15'},
        ],
        'locked_element_ids': ['answer-final'],
      },
      'interaction': {
        'type': 'text_response',
        'prompt': 'What operation removes +5?',
        'expected_answer_locked': true,
        'input_enabled': true,
        'submit_label': 'Submit',
      },
      'allowed_actions': ['submit_answer', 'request_hint', 'stuck'],
      'quick_actions': ['submit_answer', 'request_hint'],
      'mastery_signal': 'exploring',
      'metadata': {
        'problem_type': 'linear_equation_one_variable',
        'curriculum_chunk_ids': ['grade10-linear-equations'],
        'curriculum_confidence': 0.82,
        'curriculum_sources': [
          {'type': 'manual_seed', 'page': 1},
        ],
        'prerequisites': ['inverse operations'],
        'formulas': ['a = b means both sides stay balanced'],
        'common_misconceptions': ['changing only one side'],
        'khmer_terms': {'equation': 'សមីការ'},
        'response_source': 'hybrid',
        'solver_name': 'LinearEquationSolver',
        'llm_called': false,
        'llm_provider': null,
        'fallback_reason': null,
        'current_step_index': 0,
        'input_relevance': null,
        'validation_result': null,
        'verification': {
          'status': 'mathematically_valid_but_inefficient',
          'verified': true,
          'normalized_expression': 'x = 5',
          'student_message':
              'This is valid, but show the requested step first.',
          'evidence': {'reason': 'expected_step'},
        },
        'tutor_move': 'ask_guiding_question',
        'policy_decision': {'reason': 'first_problem_input'},
        'board_action_ids': ['a1', 'a2'],
      },
    });

    expect(response.sessionId, 'session-1');
    expect(response.turnId, 'turn-1');
    expect(response.screenState, 'speaking_writing');
    expect(response.tutorStatus, 'Writing...');
    expect(response.finalAnswerLocked, isTrue);
    expect(response.board.type, 'equation_steps');
    expect(response.board.items.single.content, '2x + 5 = 15');
    expect(response.speech?.ttsStatus, 'pending');
    expect(response.teachingStage?.stageState, 'waiting_for_student');
    expect(response.boardActions, hasLength(2));
    expect(response.boardActions.first.latex, '2x + 5 = 15');
    expect(response.boardActions.last.locked, isTrue);
    expect(response.canvasActions.single.text, 'Step 1');
    expect(response.teachingBoard?.lockedElementIds, ['answer-final']);
    expect(response.interaction?.prompt, 'What operation removes +5?');
    expect(response.allowedActions, contains('request_hint'));
    expect(response.quickActions, ['submit_answer', 'request_hint']);
    expect(response.curriculumMetadata.chunkIds, ['grade10-linear-equations']);
    expect(response.curriculumMetadata.confidence, .82);
    expect(response.curriculumMetadata.formulas.single, contains('balanced'));
    expect(response.curriculumMetadata.khmerTerms['equation'], 'សមីការ');
    expect(response.metadata['response_source'], 'hybrid');
    expect(response.metadata['solver_name'], 'LinearEquationSolver');
    expect(response.metadata['board_action_ids'], ['a1', 'a2']);
    expect(
      response.verification?.status,
      'mathematically_valid_but_inefficient',
    );
    expect(response.verification?.verified, isTrue);
    expect(response.verification?.normalizedExpression, 'x = 5');
  });

  test('target screen states parse safely from top-level response fields', () {
    const states = [
      'home',
      'speaking_writing',
      'asking_question',
      'graph_based',
      'check_my_work',
      'final_verified_answer',
      'unsupported_problem',
    ];

    for (final state in states) {
      final response = VisualTutorTurnResponseModel.fromJson({
        'api_compatibility_version': 0,
        'session_id': 'session-$state',
        'turn_id': 'turn-$state',
        'screen_state': state,
        'tutor_status': 'Waiting',
        'spoken_text': 'Tutor speech',
        'display_text': 'Tutor speech',
        'teaching_mode': 'guided_question',
        'final_answer_locked': true,
        'student_task': 'Try the next step.',
        'board': {
          'type': 'formula_card',
          'metadata': {'screen_state': state},
        },
        'speech': {'text': 'Tutor speech'},
        'interaction': {
          'type': 'text_response',
          'prompt': 'What should we try next?',
        },
        'allowed_actions': ['submit_answer'],
        'quick_actions': ['submit_answer', 'request_hint'],
        'mastery_signal': 'exploring',
        'metadata': {'screen_state': state},
      });

      expect(response.screenState, state);
      expect(response.tutorStatus, 'Waiting');
      expect(response.speech?.text, 'Tutor speech');
      expect(response.interaction?.type, 'text_response');
      expect(response.quickActions, ['submit_answer', 'request_hint']);
    }
  });

  test('missing optional fields are handled safely', () {
    final response = VisualTutorTurnResponseModel.fromJson({
      'api_compatibility_version': 0,
      'session_id': 'session-2',
      'turn_id': 'turn-2',
      'spoken_text': 'Try a hint.',
      'display_text': 'Try a hint.',
      'teaching_mode': 'hint',
      'final_answer_locked': false,
      'student_task': 'Write the next step.',
      'board': {'type': 'equation'},
      'mastery_signal': 'needs_hint',
    });

    expect(response.finalAnswerLocked, isFalse);
    expect(response.studentIntent, 'unknown');
    expect(response.board.items, isEmpty);
    expect(response.speech, isNull);
    expect(response.teachingStage, isNull);
    expect(response.boardActions, isEmpty);
    expect(response.canvasActions, isEmpty);
    expect(response.allowedActions, isEmpty);
    expect(response.curriculumMetadata.chunkIds, isEmpty);
    expect(response.metadata['response_source'], isNull);
  });

  test('request models serialize backend-compatible payloads', () {
    final sessionRequest = VisualTutorSessionCreateRequestModel(
      userId: 'user-1',
      subject: 'Mathematics',
      topic: 'Slope',
      metadata: const {'grade': 10},
    );

    expect(sessionRequest.toJson(), {
      'session_mode': 'draft',
      'subject': 'Mathematics',
      'topic': 'Slope',
      'metadata': {'grade': 10},
    });

    final turnRequest = VisualTutorTurnRequestModel(
      userId: 'user-1',
      sessionId: 'session-1',
      subject: 'Mathematics',
      topic: 'Linear Equations',
      message: '2x + 5 = 15',
      action: 'submit_problem',
      studentIntent: 'new_problem',
      currentState: const VisualTutorTurnStateModel(problemText: '2x + 5 = 15'),
      metadata: const {
        'grade': 10,
        'client_board_version': 4,
        'client_base_board_version': 3,
      },
    );

    final json = turnRequest.toJson();
    expect(json.containsKey('user_id'), isFalse);
    expect(json['session_id'], 'session-1');
    expect(json['current_state']['problem_text'], '2x + 5 = 15');
    expect(json['allow_final_answer'], isFalse);
    expect(json['client_board_version'], 4);
    expect(json['client_base_board_version'], 3);
  });

  test(
    'session restore retains durable tutor state without trusting client identity',
    () {
      final session = VisualTutorSessionModel.fromJson({
        'session_id': 'session-restore-1',
        'user_id': 'server-derived-user',
        'subject': 'Mathematics',
        'grade_level': '10',
        'topic': 'Linear Equations',
        'skill_tags': ['inverse-operations'],
        'difficulty': 'beginner',
        'problem_text': '2x + 5 = 15',
        'normalized_problem': '2*x + 5 = 15',
        'current_step_index': 2,
        'hint_count': 1,
        'wrong_attempts': 2,
        'final_answer_revealed': false,
        'board_version': 4,
        'validation_history': [
          {'validation_result': 'correct_step', 'verified_by': 'sympy'},
        ],
        'replay_snapshots': [
          {
            'board_version': 4,
            'turn_id': 'turn-4',
            'teaching_board_state': {'id': 'board-1', 'elements': []},
          },
        ],
        'status': 'active',
        'metadata': {'problem_type': 'linear_equation_one_variable'},
      });

      expect(session.userId, 'server-derived-user');
      expect(session.gradeLevel, '10');
      expect(session.skillTags, ['inverse-operations']);
      expect(session.difficulty, 'beginner');
      expect(session.normalizedProblem, '2*x + 5 = 15');
      expect(session.currentStepIndex, 2);
      expect(session.hintCount, 1);
      expect(session.wrongAttempts, 2);
      expect(session.validationHistory.single['verified_by'], 'sympy');
      expect(session.metadata['board_version'], 4);
      expect(session.replaySnapshots.single['board_version'], 4);
      expect(session.status, 'active');
    },
  );
}

Map<String, dynamic> _compactPublicTurn() => {
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
