import '../../domain/entities/visual_tutor_entities.dart';
import '../../domain/entities/teaching_plan_contract.dart';

class VisualTutorSessionCreateRequestModel
    extends VisualTutorSessionCreateRequestEntity {
  const VisualTutorSessionCreateRequestModel({
    required super.userId,
    super.subject,
    super.sessionMode,
    super.topic,
    super.problemText,
    super.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'session_mode': sessionMode,
      'subject': subject,
      if (topic != null) 'topic': topic,
      if (problemText != null) 'problem_text': problemText,
      'metadata': metadata,
    };
  }
}

class VisualTutorTurnRequestModel extends VisualTutorTurnRequestEntity {
  const VisualTutorTurnRequestModel({
    required super.userId,
    super.sessionId,
    super.subject,
    super.topic,
    super.message,
    super.inputType,
    super.locale,
    super.languageMode,
    super.action,
    super.studentIntent,
    super.currentState,
    super.hintCount,
    super.studentSubmittedStep,
    super.allowFinalAnswer,
    super.idempotencyKey,
    super.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      if (sessionId != null) 'session_id': sessionId,
      'subject': subject,
      if (topic != null) 'topic': topic,
      'message': message,
      'input_type': inputType,
      if (locale != null) 'locale': locale,
      'language_mode': languageMode,
      'action': action,
      if (studentIntent != null) 'student_intent': studentIntent,
      'current_state': VisualTutorTurnStateModel.fromEntity(
        currentState,
      ).toJson(),
      if (hintCount != null) 'hint_count': hintCount,
      if (studentSubmittedStep != null)
        'student_submitted_step': studentSubmittedStep,
      'allow_final_answer': allowFinalAnswer,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (metadata['client_board_version'] is int)
        'client_board_version': metadata['client_board_version'],
      if (metadata['client_base_board_version'] is int)
        'client_base_board_version': metadata['client_base_board_version'],
      'metadata': {...metadata, 'public_contract_version': 1},
    };
  }
}

class VisualTutorStepTurnRequestModel extends VisualTutorStepTurnRequestEntity {
  const VisualTutorStepTurnRequestModel({
    required super.userId,
    required super.sessionId,
    required super.subject,
    super.stepId,
    super.message,
    super.action,
    super.metadata,
  });

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'subject': subject,
    if (stepId != null) 'step_id': stepId,
    'message': message,
    'action': action,
    'metadata': metadata,
  };
}

class VisualTutorStepTurnResponseModel
    extends VisualTutorStepTurnResponseEntity {
  const VisualTutorStepTurnResponseModel({
    required super.sessionId,
    required super.subject,
    required super.currentStepIndex,
    required super.totalSteps,
    required super.currentStep,
    required super.teachingSequence,
    required super.recommendedAction,
    super.evaluation,
  });

  factory VisualTutorStepTurnResponseModel.fromJson(Map<String, dynamic> json) {
    final sequence = (json['teaching_sequence'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => _stepFromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    final rawCurrent = Map<String, dynamic>.from(json['current_step'] as Map);
    return VisualTutorStepTurnResponseModel(
      sessionId: json['session_id'] as String,
      subject: json['subject'] as String,
      currentStepIndex: json['current_step_index'] as int,
      totalSteps: json['total_steps'] as int,
      currentStep: _stepFromJson(rawCurrent),
      teachingSequence: sequence,
      recommendedAction: json['recommended_action'] as String,
      evaluation: json['evaluation'] is Map
          ? Map<String, dynamic>.from(json['evaluation'] as Map)
          : null,
    );
  }
}

VisualTutorStepEntity _stepFromJson(Map<String, dynamic> json) =>
    VisualTutorStepEntity(
      stepId: json['step_id'] as String,
      visualizationType: json['visualization_type'] as String? ?? 'diagram',
      content: json['content'] is Map
          ? Map<String, dynamic>.from(json['content'] as Map)
          : const {},
      studentQuestion: json['student_question'] as String? ?? '',
      studentQuestionKhmer: json['student_question_khmer'] as String? ?? '',
      expectedResponseType: json['expected_response_type'] as String? ?? 'text',
    );

class VisualTutorTurnStateModel extends VisualTutorTurnStateEntity {
  const VisualTutorTurnStateModel({
    super.problemInstanceId,
    super.lessonId,
    super.activeStepId,
    super.expectedStudentActionId,
    super.problemText,
    super.normalizedProblem,
    super.currentStepIndex,
    super.hintCount,
    super.wrongAttempts,
    super.finalAnswerRevealed,
    super.studentSubmittedStep,
  });

  factory VisualTutorTurnStateModel.fromEntity(
    VisualTutorTurnStateEntity entity,
  ) {
    return VisualTutorTurnStateModel(
      problemInstanceId: entity.problemInstanceId,
      lessonId: entity.lessonId,
      activeStepId: entity.activeStepId,
      expectedStudentActionId: entity.expectedStudentActionId,
      problemText: entity.problemText,
      normalizedProblem: entity.normalizedProblem,
      currentStepIndex: entity.currentStepIndex,
      hintCount: entity.hintCount,
      wrongAttempts: entity.wrongAttempts,
      finalAnswerRevealed: entity.finalAnswerRevealed,
      studentSubmittedStep: entity.studentSubmittedStep,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (problemInstanceId != null) 'problem_instance_id': problemInstanceId,
      if (lessonId != null) 'lesson_id': lessonId,
      if (activeStepId != null) 'active_step_id': activeStepId,
      if (expectedStudentActionId != null)
        'expected_student_action_id': expectedStudentActionId,
      if (problemText != null) 'problem_text': problemText,
      if (normalizedProblem != null) 'normalized_problem': normalizedProblem,
      'current_step_index': currentStepIndex,
      'hint_count': hintCount,
      'wrong_attempts': wrongAttempts,
      'final_answer_revealed': finalAnswerRevealed,
      'student_submitted_step': studentSubmittedStep,
    };
  }
}

class VisualTutorSessionModel extends VisualTutorSessionEntity {
  const VisualTutorSessionModel({
    required super.sessionId,
    required super.userId,
    required super.subject,
    super.gradeLevel,
    super.topic,
    super.skillTags,
    super.difficulty,
    super.problemText,
    super.normalizedProblem,
    super.problemType,
    super.currentStepIndex,
    super.hintCount,
    super.wrongAttempts,
    super.finalAnswerRevealed,
    super.teachingBoard,
    super.visibleBoardElements,
    super.playedActionIds,
    super.interaction,
    super.validationHistory,
    super.replaySnapshots,
    super.status,
    super.metadata,
  });

  factory VisualTutorSessionModel.fromJson(Map<String, dynamic> json) {
    return VisualTutorSessionModel(
      sessionId: _string(json['session_id']),
      userId: _string(json['user_id']),
      subject: _string(json['subject'], fallback: 'Mathematics'),
      gradeLevel: _nullableString(json['grade_level']),
      topic: _nullableString(json['topic']),
      skillTags: _stringList(json['skill_tags']),
      difficulty: _nullableString(json['difficulty']),
      problemText: _nullableString(json['problem_text']),
      normalizedProblem: _nullableString(json['normalized_problem']),
      problemType: _nullableString(json['problem_type']),
      currentStepIndex: _int(json['current_step_index']),
      hintCount: _int(json['hint_count']),
      wrongAttempts: _int(json['wrong_attempts']),
      finalAnswerRevealed: _bool(json['final_answer_revealed']),
      teachingBoard: json['teaching_board_state'] is Map
          ? VisualTutorTeachingBoardModel.fromJson(
              _map(json['teaching_board_state']),
            )
          : null,
      visibleBoardElements: _listOfMaps(json['visible_board_elements']),
      playedActionIds: _stringList(json['played_action_ids']),
      interaction: json['pending_interaction'] is Map
          ? VisualTutorInteractionModel.fromJson(
              _map(json['pending_interaction']),
            )
          : null,
      validationHistory: _listOfMaps(json['validation_history']),
      replaySnapshots: _listOfMaps(json['replay_snapshots']),
      status: _string(json['status'], fallback: 'active'),
      metadata: {
        ..._map(json['metadata']),
        if (json['board_version'] is num)
          'board_version': (json['board_version'] as num).toInt(),
        if (json['board_schema_version'] is num)
          'board_schema_version': (json['board_schema_version'] as num).toInt(),
      },
    );
  }
}

class VisualTutorTurnResponseModel extends VisualTutorTurnResponseEntity {
  const VisualTutorTurnResponseModel({
    required super.sessionId,
    required super.turnId,
    required super.spokenText,
    required super.displayText,
    required super.teachingMode,
    required super.finalAnswerLocked,
    required super.studentTask,
    required super.board,
    super.screenState,
    super.tutorStatus,
    super.studentIntent,
    super.speech,
    super.teachingStage,
    super.canvas,
    super.canvasActions,
    super.boardActions,
    super.teachingBoard,
    super.interaction,
    super.allowedActions,
    super.quickActions,
    super.visualFocus,
    super.nextStudentAction,
    super.tutorBehavior,
    super.masterySignal,
    super.curriculumMetadata,
    super.verification,
    super.metadata,
  });

  factory VisualTutorTurnResponseModel.fromJson(Map<String, dynamic> json) {
    // Production turns expose one compact student-safe teaching plan at the
    // top level. Legacy parsing is deliberately limited to an explicit
    // temporary compatibility response; production never falls back to it.
    final publicPlan = _map(json['teaching_plan']);
    final isPublicTurn = publicPlan.isNotEmpty;
    final isLegacyCompatibilityTurn = json['api_compatibility_version'] == 0;
    if (!isPublicTurn && !isLegacyCompatibilityTurn) {
      throw const FormatException(
        'Visual Tutor requires public tutor-turn contract version 1.',
      );
    }
    if (isPublicTurn) {
      const allowedTopLevel = {
        'schema_version',
        'session_id',
        'turn_id',
        'board_version',
        'base_board_version',
        'board_update_mode',
        'lesson_state',
        'tutor_status',
        'teaching_plan',
        'verification',
        'recovery',
      };
      if (!<int>{1, 2}.contains(json['schema_version']) ||
          json.keys.any((key) => !allowedTopLevel.contains(key)) ||
          !_validPublicVerification(_map(json['verification'])) ||
          (json['schema_version'] == 2 &&
              !_validPublicTurnEnvelope(json, publicPlan))) {
        throw const FormatException(
          'Visual Tutor public tutor-turn is invalid.',
        );
      }
    }
    final verificationMap = _map(json['verification']);
    final metadata = isPublicTurn
        ? {
            'board_version': json['board_version'],
            'base_board_version': json['base_board_version'],
            'board_update_mode': json['board_update_mode'] ?? 'replace',
            'authoritative_lesson_state': _map(json['lesson_state']),
            'verified': verificationMap['verified'],
          }
        : _map(json['metadata']);
    final planPayload = publicPlan.isNotEmpty
        ? {
            'schema_version': publicPlan['schema_version'],
            'representation': publicPlan['representation'],
            'learning_objective': publicPlan['learning_objective'],
            'teaching_message': publicPlan['teaching_message'],
            'allowed_student_actions': publicPlan['allowed_student_actions'],
            'hidden_answer_policy': publicPlan['hidden_answer_policy'],
            'next_state_policy': publicPlan['next_state_policy'],
            'board_actions': [
              ..._listOfMaps(publicPlan['visible_board_actions']),
              if (publicPlan['active_student_task'] is Map)
                _map(publicPlan['active_student_task']),
            ],
          }
        : _map(metadata['teaching_plan']);
    final teachingPlan = isPublicTurn
        ? VisualTutorTeachingPlan.tryParse(
            VisualTutorTeachingPlan.recoverPublicPlan(planPayload),
          )
        : VisualTutorTeachingPlan.tryParse(planPayload);
    if (isPublicTurn && teachingPlan == null) {
      throw const FormatException('Visual Tutor teaching plan is invalid.');
    }
    final board = VisualTutorBoardModel.fromJson(
      publicPlan.isNotEmpty
          ? const {'type': 'equation', 'items': []}
          : _map(json['board']),
    );
    final teachingStage = json['teaching_stage'] is Map
        ? VisualTutorTeachingStageModel.fromJson(_map(json['teaching_stage']))
        : null;
    final allowedActions = _stringList(json['allowed_actions']);
    final quickActions = _stringList(json['quick_actions']);
    return VisualTutorTurnResponseModel(
      sessionId: _string(json['session_id']),
      turnId: _string(json['turn_id']),
      spokenText: isPublicTurn
          ? _string(publicPlan['teaching_message'])
          : _string(json['spoken_text']),
      displayText: isPublicTurn
          ? _string(publicPlan['teaching_message'])
          : _string(json['display_text']),
      teachingMode: isPublicTurn
          ? _string(publicPlan['representation'], fallback: 'guided_question')
          : _string(json['teaching_mode']),
      screenState: isPublicTurn
          ? 'speaking_writing'
          : _resolveScreenState(json, metadata, board),
      tutorStatus: isPublicTurn
          ? _string(json['tutor_status'], fallback: 'Waiting for you')
          : _resolveTutorStatus(json, metadata, teachingStage),
      studentIntent: isPublicTurn
          ? 'unknown'
          : _string(json['student_intent'], fallback: 'unknown'),
      finalAnswerLocked: publicPlan.isNotEmpty
          ? !_bool(
              _map(
                publicPlan['hidden_answer_policy'],
              )["deterministic_policy_permits_final_reveal"],
            )
          : _bool(json['final_answer_locked']),
      studentTask: isPublicTurn
          ? _string(_map(publicPlan['active_student_task'])['text'])
          : _string(json['student_task']),
      board: board,
      canvas: !isPublicTurn && json['canvas'] is Map
          ? VisualTutorCanvasStateModel.fromJson(_map(json['canvas']))
          : null,
      canvasActions: publicPlan.isNotEmpty
          ? const []
          : _listOfMaps(
              json['canvas_actions'],
            ).map(VisualTutorBoardActionModel.fromJson).toList(),
      speech: !isPublicTurn && json['speech'] is Map
          ? VisualTutorSpeechModel.fromJson(_map(json['speech']))
          : null,
      teachingStage: isPublicTurn ? null : teachingStage,
      // The teaching plan is already strictly validated by the AI service and
      // revalidated locally. Prefer it over legacy board_actions so a screen
      // state can never replace the AI-selected current teaching block.
      boardActions:
          (teachingPlan?.boardActions ?? _listOfMaps(json['board_actions']))
              .map(VisualTutorBoardActionModel.fromJson)
              .toList(),
      teachingBoard: !isPublicTurn && json['teaching_board'] is Map
          ? VisualTutorTeachingBoardModel.fromJson(_map(json['teaching_board']))
          : null,
      interaction: !isPublicTurn && json['interaction'] is Map
          ? VisualTutorInteractionModel.fromJson(_map(json['interaction']))
          : null,
      allowedActions: publicPlan.isNotEmpty
          ? _stringList(publicPlan['allowed_student_actions'])
          : allowedActions,
      quickActions: isPublicTurn
          ? _stringList(publicPlan['allowed_student_actions'])
          : quickActions.isNotEmpty
          ? quickActions
          : allowedActions,
      visualFocus: !isPublicTurn && json['visual_focus'] is Map
          ? _map(json['visual_focus'])
          : null,
      nextStudentAction: !isPublicTurn && json['next_student_action'] is Map
          ? _map(json['next_student_action'])
          : null,
      tutorBehavior: !isPublicTurn && json['tutor_behavior'] is Map
          ? _map(json['tutor_behavior'])
          : null,
      masterySignal: isPublicTurn
          ? 'exploring'
          : _string(json['mastery_signal'], fallback: 'exploring'),
      curriculumMetadata: isPublicTurn
          ? const VisualTutorCurriculumMetadata()
          : VisualTutorCurriculumMetadataModel.fromJson(json, metadata),
      verification: json['verification'] is Map
          ? VisualTutorVerificationModel.fromJson(_map(json['verification']))
          : metadata['verification'] is Map
          ? VisualTutorVerificationModel.fromJson(
              _map(metadata['verification']),
            )
          : null,
      // Keep only the compact, student-safe state assembled above. The tutor
      // screen needs these identities for its *next* request; dropping them
      // would make every subsequent turn look like Step 0.
      metadata: metadata,
    );
  }

  static bool _validPublicVerification(Map<String, dynamic> value) {
    const allowed = {
      'status',
      'verified',
      'concise_evidence',
      'student_facing_feedback',
    };
    const statuses = {
      'correct',
      'mathematically_valid_but_inefficient',
      'invalid',
      'incomplete',
      'cannot_verify',
    };
    return value.keys.every(allowed.contains) &&
        statuses.contains(value['status']) &&
        value['verified'] is bool &&
        _string(value['concise_evidence']).trim().isNotEmpty &&
        _string(value['student_facing_feedback']).trim().isNotEmpty;
  }
}

class VisualTutorVerificationModel extends VisualTutorVerificationEntity {
  const VisualTutorVerificationModel({
    required super.status,
    required super.verified,
    required super.studentMessage,
    super.normalizedExpression,
    super.solution,
    super.evidence,
  });

  factory VisualTutorVerificationModel.fromJson(Map<String, dynamic> json) {
    return VisualTutorVerificationModel(
      status: _string(json['status'], fallback: 'cannot_verify'),
      verified: _bool(json['verified']),
      studentMessage: _string(
        json['student_message'],
        fallback: _string(
          json['student_facing_feedback'],
          fallback: _string(
            json['concise_evidence'],
            fallback: 'I could not verify this step.',
          ),
        ),
      ),
      normalizedExpression: _nullableString(json['normalized_expression']),
      solution: _nullableString(json['solution']),
      evidence: _map(json['evidence']),
    );
  }
}

class VisualTutorSpeechModel extends VisualTutorSpeechEntity {
  const VisualTutorSpeechModel({
    required super.text,
    super.language,
    super.voiceId,
    super.ttsStatus,
    super.speakAfterActionId,
    super.pauseAfterMs,
    super.metadata,
  });

  factory VisualTutorSpeechModel.fromJson(Map<String, dynamic> json) {
    return VisualTutorSpeechModel(
      text: _string(json['text']),
      language: _string(json['language'], fallback: 'en'),
      voiceId: _nullableString(json['voice_id']),
      ttsStatus: _string(json['tts_status'], fallback: 'not_requested'),
      speakAfterActionId: _nullableString(json['speak_after_action_id']),
      pauseAfterMs: _int(json['pause_after_ms']),
      metadata: _map(json['metadata']),
    );
  }
}

class VisualTutorTeachingStageModel extends VisualTutorTeachingStageEntity {
  const VisualTutorTeachingStageModel({
    super.stageState,
    super.lessonState,
    super.currentFocus,
    super.turnGoal,
    super.maxActionsBeforeWait,
    super.metadata,
  });

  factory VisualTutorTeachingStageModel.fromJson(Map<String, dynamic> json) {
    return VisualTutorTeachingStageModel(
      stageState: _string(json['stage_state'], fallback: 'waiting_for_student'),
      lessonState: _string(json['lesson_state'], fallback: 'ask'),
      currentFocus: _nullableString(json['current_focus']),
      turnGoal: _nullableString(json['turn_goal']),
      maxActionsBeforeWait: _int(json['max_actions_before_wait'], fallback: 1),
      metadata: _map(json['metadata']),
    );
  }
}

class VisualTutorBoardModel extends VisualTutorBoardEntity {
  const VisualTutorBoardModel({
    required super.type,
    super.title,
    super.items,
    super.metadata,
  });

  factory VisualTutorBoardModel.fromJson(Map<String, dynamic> json) {
    return VisualTutorBoardModel(
      type: _string(json['type'], fallback: 'equation'),
      title: _nullableString(json['title']),
      items: _listOfMaps(
        json['items'],
      ).map(VisualTutorBoardItemModel.fromJson).toList(),
      metadata: _map(json['metadata']),
    );
  }
}

class VisualTutorBoardItemModel extends VisualTutorBoardItemEntity {
  const VisualTutorBoardItemModel({
    required super.label,
    required super.content,
    super.status,
    super.metadata,
  });

  factory VisualTutorBoardItemModel.fromJson(Map<String, dynamic> json) {
    return VisualTutorBoardItemModel(
      label: _string(json['label']),
      content: _string(json['content']),
      status: _string(json['status'], fallback: 'active'),
      metadata: _map(json['metadata']),
    );
  }
}

class VisualTutorBoardActionModel extends VisualTutorBoardActionEntity {
  const VisualTutorBoardActionModel({
    required super.id,
    required super.type,
    super.sequenceIndex,
    super.durationMs,
    super.waitForSpeechMarker,
    super.requiresStudentResponse,
    super.groupId,
    super.sectionId,
    super.layoutZone,
    super.layoutFlow,
    super.x,
    super.y,
    super.width,
    super.height,
    super.text,
    super.latex,
    super.points,
    super.graph,
    super.targetId,
    super.style,
    super.locked,
    super.hidden,
    super.revealPolicy,
    super.metadata,
  });

  factory VisualTutorBoardActionModel.fromJson(Map<String, dynamic> json) {
    // New visual primitives are declared in the public action contract. The
    // renderer keeps its legacy entity shape, so copy only the small
    // allow-listed values it already knows how to paint into metadata. This is
    // data normalization, never dynamic widget configuration.
    final metadata = Map<String, dynamic>.from(_map(json['metadata']));
    final label = _nullableString(json['label']);
    if (label != null) metadata['label'] = label;
    final numberLine = json['number_line'] is Map
        ? _map(json['number_line'])
        : null;
    final sourceGraph = json['graph'] is Map ? _map(json['graph']) : null;
    Map<String, dynamic>? graph = sourceGraph;
    if (numberLine != null) {
      metadata['number_line'] = numberLine;
      graph ??= {
        'x_min': numberLine['min'],
        'x_max': numberLine['max'],
        // The number-line painter only uses x. These keep the graph-shaped
        // legacy payload well-formed for callers that inspect it.
        'y_min': -1,
        'y_max': 1,
      };
    }
    final table = json['table'] is Map ? _map(json['table']) : null;
    if (table != null) {
      metadata['table'] = table;
      metadata['columns'] = table['columns'];
      metadata['rows'] = table['rows'];
    }
    // Strict public primitive fields become renderer-local data. They remain
    // declarative data; this compatibility entity never instantiates code.
    for (final key in <String>[
      'forces',
      'molecule_bonds',
      'atom_model',
      'particle_diagram',
      'circuit_diagram',
      'reaction_layout',
    ]) {
      final value = json[key];
      if (value is Map || value is List) metadata[key] = value;
    }
    if (json['type'] == 'draw_molecule' && json['points'] is List) {
      // The strict molecule contract uses bounded points. Convert them to the
      // legacy painter's atom list without accepting an arbitrary diagram.
      metadata['atoms'] = _listOfMaps(json['points'])
          .map(
            (point) => <String, dynamic>{
              'symbol': point['label'] ?? 'X',
              'x': point['x'],
              'y': point['y'],
            },
          )
          .toList(growable: false);
      if (json['molecule_bonds'] is List) {
        metadata['bonds'] = (json['molecule_bonds'] as List)
            .whereType<Map>()
            .map(
              (bond) => <String, dynamic>{
                'from': bond['from_index'],
                'to': bond['to_index'],
                'order': bond['order'],
              },
            )
            .toList(growable: false);
      }
    }
    return VisualTutorBoardActionModel(
      id: _string(json['id']),
      type: _string(json['type'], fallback: 'write_text'),
      sequenceIndex: _int(json['sequence_index']),
      durationMs: _int(json['duration_ms']),
      waitForSpeechMarker: _bool(json['wait_for_speech_marker']),
      requiresStudentResponse: _bool(json['requires_student_response']),
      groupId: _nullableString(json['group_id']),
      sectionId: _nullableString(json['section_id']),
      layoutZone: _nullableString(json['layout_zone']),
      layoutFlow: _nullableString(json['layout_flow']),
      x: _double(json['x']),
      y: _double(json['y']),
      width: _double(json['width']),
      height: _double(json['height']),
      text: _nullableString(json['text']),
      latex: _nullableString(json['latex']),
      points: _listOfMaps(json['points']),
      graph: graph,
      targetId: _nullableString(json['target_id']),
      style: _map(json['style']),
      locked: _bool(json['locked']),
      hidden: _bool(json['hidden']),
      revealPolicy: _nullableString(json['reveal_policy']),
      metadata: metadata,
    );
  }
}

class VisualTutorCanvasStateModel extends VisualTutorCanvasStateEntity {
  const VisualTutorCanvasStateModel({
    super.viewport,
    super.elements,
    super.focusElementId,
    super.lockedElementIds,
    super.revealedElementIds,
    super.metadata,
  });

  factory VisualTutorCanvasStateModel.fromJson(Map<String, dynamic> json) {
    return VisualTutorCanvasStateModel(
      viewport: _map(json['viewport']),
      elements: _listOfMaps(json['elements']),
      focusElementId: _nullableString(json['focus_element_id']),
      lockedElementIds: _stringList(json['locked_element_ids']),
      revealedElementIds: _stringList(json['revealed_element_ids']),
      metadata: _map(json['metadata']),
    );
  }
}

class VisualTutorTeachingBoardModel extends VisualTutorTeachingBoardEntity {
  const VisualTutorTeachingBoardModel({
    super.id,
    super.viewport,
    super.elements,
    super.groups,
    super.sections,
    super.actions,
    super.focusElementId,
    super.activeSectionId,
    super.lockedElementIds,
    super.hiddenElementIds,
    super.fadedElementIds,
    super.metadata,
  });

  factory VisualTutorTeachingBoardModel.fromJson(Map<String, dynamic> json) {
    return VisualTutorTeachingBoardModel(
      id: _string(json['id'], fallback: 'teaching-board'),
      viewport: _map(json['viewport']),
      elements: _listOfMaps(json['elements']),
      groups: _listOfMaps(json['groups']),
      sections: _listOfMaps(json['sections']),
      actions: _listOfMaps(json['actions']),
      focusElementId: _nullableString(json['focus_element_id']),
      activeSectionId: _nullableString(json['active_section_id']),
      lockedElementIds: _stringList(json['locked_element_ids']),
      hiddenElementIds: _stringList(json['hidden_element_ids']),
      fadedElementIds: _stringList(json['faded_element_ids']),
      metadata: _map(json['metadata']),
    );
  }
}

class VisualTutorInteractionModel extends VisualTutorInteractionEntity {
  const VisualTutorInteractionModel({
    required super.type,
    required super.prompt,
    super.expectedAnswerLocked,
    super.validationStrategy,
    super.choices,
    super.inputEnabled,
    super.submitLabel,
    super.metadata,
  });

  factory VisualTutorInteractionModel.fromJson(Map<String, dynamic> json) {
    return VisualTutorInteractionModel(
      type: _string(json['type'], fallback: 'text_response'),
      prompt: _string(json['prompt']),
      expectedAnswerLocked: _bool(
        json['expected_answer_locked'],
        fallback: true,
      ),
      validationStrategy: _nullableString(json['validation_strategy']),
      choices: _listOfMaps(
        json['choices'],
      ).map(VisualTutorInteractionChoiceModel.fromJson).toList(),
      inputEnabled: _bool(json['input_enabled'], fallback: true),
      submitLabel: _string(json['submit_label'], fallback: 'Submit'),
      metadata: _map(json['metadata']),
    );
  }
}

class VisualTutorInteractionChoiceModel
    extends VisualTutorInteractionChoiceEntity {
  const VisualTutorInteractionChoiceModel({
    required super.id,
    required super.label,
    required super.value,
    super.metadata,
  });

  factory VisualTutorInteractionChoiceModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return VisualTutorInteractionChoiceModel(
      id: _string(json['id']),
      label: _string(json['label']),
      value: _string(json['value']),
      metadata: _map(json['metadata']),
    );
  }
}

class VisualTutorCurriculumMetadataModel extends VisualTutorCurriculumMetadata {
  const VisualTutorCurriculumMetadataModel({
    super.context,
    super.chunkIds,
    super.confidence,
    super.sources,
    super.prerequisites,
    super.formulas,
    super.commonMisconceptions,
    super.khmerTerms,
    super.glossarySets,
    super.glossaryGaps,
  });

  factory VisualTutorCurriculumMetadataModel.fromJson(
    Map<String, dynamic> root,
    Map<String, dynamic> metadata,
  ) {
    Object? read(String key) => root[key] ?? metadata[key];
    final glossary = read('reviewed_khmer_glossary');
    final glossaryMap = glossary is Map
        ? Map<String, dynamic>.from(glossary)
        : const <String, dynamic>{};
    return VisualTutorCurriculumMetadataModel(
      context: read('curriculum_context'),
      chunkIds: _stringList(read('curriculum_chunk_ids')),
      confidence: _double(read('curriculum_confidence')),
      sources: _objectList(read('curriculum_sources')),
      prerequisites: _stringList(read('prerequisites')),
      formulas: _stringList(read('formulas')),
      commonMisconceptions: _stringList(read('common_misconceptions')),
      khmerTerms: _stringMap(read('khmer_terms')),
      glossarySets: _objectList(glossaryMap['glossary_sets']),
      glossaryGaps: _stringList(
        glossaryMap['glossary_gaps'] ?? read('glossary_gaps'),
      ),
    );
  }
}

String _resolveScreenState(
  Map<String, dynamic> root,
  Map<String, dynamic> metadata,
  VisualTutorBoardEntity board,
) {
  final boardScreenState = board.metadata['screen_state'];
  final boardType = board.metadata['board_type'];
  final value =
      root['screen_state'] ??
      metadata['screen_state'] ??
      boardScreenState ??
      boardType;
  final screenState = _string(value);
  const supported = {
    'home',
    'speaking_writing',
    'asking_question',
    'graph_based',
    'check_my_work',
    'final_verified_answer',
    'unsupported_problem',
  };
  return supported.contains(screenState) ? screenState : 'speaking_writing';
}

String _resolveTutorStatus(
  Map<String, dynamic> root,
  Map<String, dynamic> metadata,
  VisualTutorTeachingStageEntity? teachingStage,
) {
  final explicit = _string(root['tutor_status'] ?? metadata['tutor_status']);
  if (explicit.isNotEmpty) {
    return explicit;
  }
  return switch (teachingStage?.stageState) {
    'speaking' || 'drawing' => 'Writing...',
    'analyzing' => 'Thinking...',
    'evaluating' => 'Checking',
    'waiting_for_student' => 'Waiting for you',
    _ => 'Waiting',
  };
}

String _string(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  if (value is String) {
    return value;
  }
  return value.toString();
}

String? _nullableString(Object? value) {
  if (value == null) {
    return null;
  }
  return _string(value);
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

double? _double(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

bool _bool(Object? value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return switch (value.toLowerCase()) {
      'true' || '1' || 'yes' => true,
      'false' || '0' || 'no' => false,
      _ => fallback,
    };
  }
  return fallback;
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

Map<String, String> _stringMap(Object? value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), _string(value)));
  }
  return const {};
}

List<Map<String, dynamic>> _listOfMaps(Object? value) {
  if (value is List) {
    return value.whereType<Map>().map(_map).toList();
  }
  return const [];
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.map(_string).where((item) => item.isNotEmpty).toList();
  }
  return const [];
}

List<Object> _objectList(Object? value) {
  if (value is List) {
    return value.cast<Object>();
  }
  return const [];
}

bool _validPublicTurnEnvelope(
  Map<String, dynamic> turn,
  Map<String, dynamic> plan,
) {
  final boardVersion = turn['board_version'];
  final baseBoardVersion = turn['base_board_version'];
  final mode = turn['board_update_mode'];
  final lesson = _map(turn['lesson_state']);
  if (boardVersion is! int ||
      boardVersion < 0 ||
      baseBoardVersion is! int ||
      baseBoardVersion < 0 ||
      !const {'replace', 'patch'}.contains(mode) ||
      lesson.isEmpty) {
    return false;
  }
  const requiredLessonFields = {
    'problem_instance_id',
    'active_step_id',
    'current_step_index',
    'expected_student_action_id',
    'board_version',
    'base_board_version',
  };
  if (requiredLessonFields.any((key) => !lesson.containsKey(key)) ||
      lesson['problem_instance_id'] is! String ||
      lesson['active_step_id'] is! String ||
      lesson['expected_student_action_id'] is! String ||
      lesson['current_step_index'] is! int ||
      lesson['board_version'] != boardVersion ||
      lesson['base_board_version'] != baseBoardVersion) {
    return false;
  }
  final actions = [
    ..._listOfMaps(plan['visible_board_actions']),
    if (plan['active_student_task'] is Map) _map(plan['active_student_task']),
  ];
  if (actions.isEmpty || actions.length > 24) return false;
  return actions.every(
    (action) =>
        action['id'] is String &&
        action['action_id'] == action['id'] &&
        action['problem_instance_id'] == lesson['problem_instance_id'] &&
        action['active_step_id'] == lesson['active_step_id'] &&
        action['board_version'] == boardVersion &&
        action['base_board_version'] == baseBoardVersion,
  );
}
