import '../../domain/entities/visual_tutor_entities.dart';

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
      'metadata': metadata,
    };
  }
}

class VisualTutorTurnStateModel extends VisualTutorTurnStateEntity {
  const VisualTutorTurnStateModel({
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
    final metadata = _map(json['metadata']);
    final board = VisualTutorBoardModel.fromJson(_map(json['board']));
    final teachingStage = json['teaching_stage'] is Map
        ? VisualTutorTeachingStageModel.fromJson(_map(json['teaching_stage']))
        : null;
    final allowedActions = _stringList(json['allowed_actions']);
    final quickActions = _stringList(json['quick_actions']);
    return VisualTutorTurnResponseModel(
      sessionId: _string(json['session_id']),
      turnId: _string(json['turn_id']),
      spokenText: _string(json['spoken_text']),
      displayText: _string(json['display_text']),
      teachingMode: _string(json['teaching_mode'], fallback: 'guided_question'),
      screenState: _resolveScreenState(json, metadata, board),
      tutorStatus: _resolveTutorStatus(json, metadata, teachingStage),
      studentIntent: _string(json['student_intent'], fallback: 'unknown'),
      finalAnswerLocked: _bool(json['final_answer_locked']),
      studentTask: _string(json['student_task']),
      board: board,
      canvas: json['canvas'] is Map
          ? VisualTutorCanvasStateModel.fromJson(_map(json['canvas']))
          : null,
      canvasActions: _listOfMaps(
        json['canvas_actions'],
      ).map(VisualTutorBoardActionModel.fromJson).toList(),
      speech: json['speech'] is Map
          ? VisualTutorSpeechModel.fromJson(_map(json['speech']))
          : null,
      teachingStage: teachingStage,
      boardActions: _listOfMaps(
        json['board_actions'],
      ).map(VisualTutorBoardActionModel.fromJson).toList(),
      teachingBoard: json['teaching_board'] is Map
          ? VisualTutorTeachingBoardModel.fromJson(_map(json['teaching_board']))
          : null,
      interaction: json['interaction'] is Map
          ? VisualTutorInteractionModel.fromJson(_map(json['interaction']))
          : null,
      allowedActions: allowedActions,
      quickActions: quickActions.isNotEmpty ? quickActions : allowedActions,
      visualFocus: json['visual_focus'] is Map
          ? _map(json['visual_focus'])
          : null,
      nextStudentAction: json['next_student_action'] is Map
          ? _map(json['next_student_action'])
          : null,
      tutorBehavior: json['tutor_behavior'] is Map
          ? _map(json['tutor_behavior'])
          : null,
      masterySignal: _string(json['mastery_signal'], fallback: 'exploring'),
      curriculumMetadata: VisualTutorCurriculumMetadataModel.fromJson(
        json,
        metadata,
      ),
      verification: metadata['verification'] is Map
          ? VisualTutorVerificationModel.fromJson(
              _map(metadata['verification']),
            )
          : null,
      metadata: metadata,
    );
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
        fallback: 'I could not verify this step.',
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
    return VisualTutorBoardActionModel(
      id: _string(json['id']),
      type: _string(json['type'], fallback: 'write_text'),
      sequenceIndex: _int(json['sequence_index']),
      durationMs: _int(json['duration_ms']),
      waitForSpeechMarker: _bool(json['wait_for_speech_marker']),
      requiresStudentResponse: _bool(json['requires_student_response']),
      groupId: _nullableString(json['group_id']),
      sectionId: _nullableString(json['section_id']),
      x: _double(json['x']),
      y: _double(json['y']),
      width: _double(json['width']),
      height: _double(json['height']),
      text: _nullableString(json['text']),
      latex: _nullableString(json['latex']),
      points: _listOfMaps(json['points']),
      graph: json['graph'] is Map ? _map(json['graph']) : null,
      targetId: _nullableString(json['target_id']),
      style: _map(json['style']),
      locked: _bool(json['locked']),
      hidden: _bool(json['hidden']),
      revealPolicy: _nullableString(json['reveal_policy']),
      metadata: _map(json['metadata']),
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
  });

  factory VisualTutorCurriculumMetadataModel.fromJson(
    Map<String, dynamic> root,
    Map<String, dynamic> metadata,
  ) {
    Object? read(String key) => root[key] ?? metadata[key];
    return VisualTutorCurriculumMetadataModel(
      context: read('curriculum_context'),
      chunkIds: _stringList(read('curriculum_chunk_ids')),
      confidence: _double(read('curriculum_confidence')),
      sources: _objectList(read('curriculum_sources')),
      prerequisites: _stringList(read('prerequisites')),
      formulas: _stringList(read('formulas')),
      commonMisconceptions: _stringList(read('common_misconceptions')),
      khmerTerms: _stringMap(read('khmer_terms')),
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
