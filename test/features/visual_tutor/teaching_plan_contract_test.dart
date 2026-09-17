import 'package:ai_tutor/features/visual_tutor/domain/entities/teaching_plan_contract.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> plan() => {
  'schema_version': 1,
  'representation': 'equation_transformation',
  'learning_objective': 'Use inverse operations.',
  'teaching_message': 'Keep both sides balanced.',
  'board_actions': [
    {
      'id': 'equation',
      'type': 'write_equation',
      'sequence_index': 0,
      'latex': '2x + 10 = 20',
    },
    {
      'id': 'task',
      'type': 'student_task',
      'sequence_index': 1,
      'text': 'What operation removes +10?',
      'requires_student_response': true,
    },
  ],
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
};

void main() {
  test('accepts a safe versioned teaching plan', () {
    expect(VisualTutorTeachingPlan.tryParse(plan()), isNotNull);
  });

  test('accepts safe schema-v2 action identities', () {
    final identified = plan()
      ..['board_actions'] = (plan()['board_actions'] as List)
          .cast<Map<String, dynamic>>()
          .map(
            (action) => {
              ...action,
              'problem_instance_id': 'problem-1',
              'active_step_id': 'lesson-1:step-0:task',
              'action_id': action['id'],
              'board_version': 1,
              'base_board_version': 0,
            },
          )
          .toList();
    expect(VisualTutorTeachingPlan.tryParse(identified), isNotNull);
  });

  test('accepts a complete live timeline and rejects an incomplete one', () {
    final timeline = plan()
      ..['board_actions'] = [
        {
          'id': 'speak',
          'type': 'speak_marker',
          'sequence_index': 0,
          'duration_ms': 0,
        },
        {
          'id': 'current',
          'type': 'write_equation',
          'sequence_index': 1,
          'duration_ms': 420,
          'latex': '2x + 10 = 20',
          'wait_for_speech_marker': true,
        },
        {
          'id': 'focus',
          'type': 'highlight',
          'sequence_index': 2,
          'duration_ms': 220,
          'target_id': 'current',
        },
        {
          'id': 'pause',
          'type': 'pause_marker',
          'sequence_index': 3,
          'duration_ms': 650,
        },
        {
          'id': 'task',
          'type': 'student_task',
          'sequence_index': 4,
          'text': 'What operation removes +10?',
          'requires_student_response': true,
        },
      ];
    expect(VisualTutorTeachingPlan.tryParse(timeline), isNotNull);
    final incomplete = Map<String, dynamic>.from(timeline)
      ..['board_actions'] = (timeline['board_actions'] as List)
          .where((action) => (action as Map)['id'] != 'pause')
          .toList();
    expect(VisualTutorTeachingPlan.tryParse(incomplete), isNull);
  });

  test('rejects UI code, unknown actions, and unapproved reveals', () {
    final unsafe = plan()..['teaching_message'] = '<script>alert(1)</script>';
    expect(VisualTutorTeachingPlan.tryParse(unsafe), isNull);
    final unknown = plan()
      ..['board_actions'] = [
        {'id': 'bad', 'type': 'custom_widget', 'text': 'No'},
        ...plan()['board_actions'] as List,
      ];
    expect(VisualTutorTeachingPlan.tryParse(unknown), isNull);
    final reveal = plan()
      ..['board_actions'] = [
        {'id': 'reveal', 'type': 'final_answer_reveal', 'text': 'x = 5'},
        ...plan()['board_actions'] as List,
      ];
    expect(VisualTutorTeachingPlan.tryParse(reveal), isNull);
  });

  test('recovers one invalid public action without hiding valid siblings', () {
    final publicPlan = plan()
      ..['board_actions'] = [
        plan()['board_actions'][0],
        {
          'id': 'unsafe-widget',
          'type': 'custom_widget',
          'sequence_index': 1,
          'widget_code': 'Text(\"do not run this\")',
        },
        {
          ...plan()['board_actions'][1] as Map<String, dynamic>,
          // This verifier-only field is deliberately ignored by the client.
          'accepted_answer_forms': ['subtract five'],
        },
      ];

    final recovered = VisualTutorTeachingPlan.recoverPublicPlan(publicPlan);
    final parsed = VisualTutorTeachingPlan.tryParse(recovered);

    expect(parsed, isNotNull);
    expect(
      parsed!.boardActions.map((action) => action['id']),
      contains('equation'),
    );
    expect(
      parsed.boardActions.map((action) => action['type']),
      contains('show_feedback'),
    );
    expect(
      parsed.boardActions.where((action) => action['type'] == 'student_task'),
      hasLength(1),
    );
  });

  test('rejects overlapping explicit board rectangles', () {
    final overlapping = plan()
      ..['board_actions'] = [
        {
          ...plan()['board_actions'][0] as Map<String, dynamic>,
          'x': 40,
          'y': 40,
          'width': 300,
          'height': 80,
        },
        {
          'id': 'overlap',
          'type': 'write_text',
          'sequence_index': 1,
          'text': 'Overlapping note',
          'x': 100,
          'y': 70,
          'width': 300,
          'height': 80,
        },
      ];
    expect(VisualTutorTeachingPlan.tryParse(overlapping), isNull);
  });
}
