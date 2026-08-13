class VisualTutorSessionEntity {
  const VisualTutorSessionEntity({
    required this.sessionId,
    required this.userId,
    required this.subject,
    this.gradeLevel,
    this.topic,
    this.skillTags = const [],
    this.difficulty,
    this.problemText,
    this.normalizedProblem,
    this.problemType,
    this.currentStepIndex = 0,
    this.hintCount = 0,
    this.wrongAttempts = 0,
    this.finalAnswerRevealed = false,
    this.teachingBoard,
    this.visibleBoardElements = const [],
    this.playedActionIds = const [],
    this.interaction,
    this.validationHistory = const [],
    this.replaySnapshots = const [],
    this.status = 'active',
    this.metadata = const {},
  });

  final String sessionId;
  final String userId;
  final String subject;
  final String? gradeLevel;
  final String? topic;
  final List<String> skillTags;
  final String? difficulty;
  final String? problemText;
  final String? normalizedProblem;
  final String? problemType;
  final int currentStepIndex;
  final int hintCount;
  final int wrongAttempts;
  final bool finalAnswerRevealed;
  final VisualTutorTeachingBoardEntity? teachingBoard;
  final List<Map<String, dynamic>> visibleBoardElements;
  final List<String> playedActionIds;
  final VisualTutorInteractionEntity? interaction;
  final List<Map<String, dynamic>> validationHistory;
  final List<Map<String, dynamic>> replaySnapshots;
  final String status;
  final Map<String, dynamic> metadata;
}

class VisualTutorTurnStateEntity {
  const VisualTutorTurnStateEntity({
    this.problemText,
    this.normalizedProblem,
    this.currentStepIndex = 0,
    this.hintCount = 0,
    this.wrongAttempts = 0,
    this.finalAnswerRevealed = false,
    this.studentSubmittedStep = false,
  });

  final String? problemText;
  final String? normalizedProblem;
  final int currentStepIndex;
  final int hintCount;
  final int wrongAttempts;
  final bool finalAnswerRevealed;
  final bool studentSubmittedStep;
}

class VisualTutorTurnRequestEntity {
  const VisualTutorTurnRequestEntity({
    required this.userId,
    this.sessionId,
    this.subject = 'Mathematics',
    this.topic,
    this.message = '',
    this.inputType = 'text',
    this.locale,
    this.action = 'submit_problem',
    this.studentIntent,
    this.currentState = const VisualTutorTurnStateEntity(),
    this.hintCount,
    this.studentSubmittedStep,
    this.allowFinalAnswer = false,
    this.idempotencyKey,
    this.metadata = const {},
  });

  final String userId;
  final String? sessionId;
  final String subject;
  final String? topic;
  final String message;
  final String inputType;
  final String? locale;
  final String action;
  final String? studentIntent;
  final VisualTutorTurnStateEntity currentState;
  final int? hintCount;
  final bool? studentSubmittedStep;
  final bool allowFinalAnswer;
  final String? idempotencyKey;
  final Map<String, dynamic> metadata;
}

class VisualTutorSessionCreateRequestEntity {
  const VisualTutorSessionCreateRequestEntity({
    required this.userId,
    this.subject = 'Mathematics',
    this.sessionMode = 'draft',
    this.topic,
    this.problemText,
    this.metadata = const {},
  });

  final String userId;
  final String subject;
  final String sessionMode;
  final String? topic;
  final String? problemText;
  final Map<String, dynamic> metadata;
}

class VisualTutorTurnResponseEntity {
  const VisualTutorTurnResponseEntity({
    required this.sessionId,
    required this.turnId,
    required this.spokenText,
    required this.displayText,
    required this.teachingMode,
    required this.finalAnswerLocked,
    required this.studentTask,
    required this.board,
    this.screenState = 'speaking_writing',
    this.tutorStatus = 'Waiting',
    this.studentIntent = 'unknown',
    this.speech,
    this.teachingStage,
    this.canvas,
    this.canvasActions = const [],
    this.boardActions = const [],
    this.teachingBoard,
    this.interaction,
    this.allowedActions = const [],
    this.quickActions = const [],
    this.visualFocus,
    this.nextStudentAction,
    this.tutorBehavior,
    this.masterySignal = 'exploring',
    this.curriculumMetadata = const VisualTutorCurriculumMetadata(),
    this.verification,
    this.metadata = const {},
  });

  final String sessionId;
  final String turnId;
  final String spokenText;
  final String displayText;
  final String teachingMode;
  final String screenState;
  final String tutorStatus;
  final String studentIntent;
  final bool finalAnswerLocked;
  final String studentTask;
  final VisualTutorBoardEntity board;
  final VisualTutorSpeechEntity? speech;
  final VisualTutorTeachingStageEntity? teachingStage;
  final VisualTutorCanvasStateEntity? canvas;
  final List<VisualTutorBoardActionEntity> canvasActions;
  final List<VisualTutorBoardActionEntity> boardActions;
  final VisualTutorTeachingBoardEntity? teachingBoard;
  final VisualTutorInteractionEntity? interaction;
  final List<String> allowedActions;
  final List<String> quickActions;
  final Map<String, dynamic>? visualFocus;
  final Map<String, dynamic>? nextStudentAction;
  final Map<String, dynamic>? tutorBehavior;
  final String masterySignal;
  final VisualTutorCurriculumMetadata curriculumMetadata;
  final VisualTutorVerificationEntity? verification;
  final Map<String, dynamic> metadata;
}

class VisualTutorVerificationEntity {
  const VisualTutorVerificationEntity({
    required this.status,
    required this.verified,
    required this.studentMessage,
    this.normalizedExpression,
    this.solution,
    this.evidence = const {},
  });

  final String status;
  final bool verified;
  final String studentMessage;
  final String? normalizedExpression;
  final String? solution;
  final Map<String, dynamic> evidence;
}

class VisualTutorSpeechEntity {
  const VisualTutorSpeechEntity({
    required this.text,
    this.language = 'en',
    this.voiceId,
    this.ttsStatus = 'not_requested',
    this.speakAfterActionId,
    this.pauseAfterMs = 0,
    this.metadata = const {},
  });

  final String text;
  final String language;
  final String? voiceId;
  final String ttsStatus;
  final String? speakAfterActionId;
  final int pauseAfterMs;
  final Map<String, dynamic> metadata;
}

class VisualTutorTeachingStageEntity {
  const VisualTutorTeachingStageEntity({
    this.stageState = 'waiting_for_student',
    this.lessonState = 'ask',
    this.currentFocus,
    this.turnGoal,
    this.maxActionsBeforeWait = 1,
    this.metadata = const {},
  });

  final String stageState;
  final String lessonState;
  final String? currentFocus;
  final String? turnGoal;
  final int maxActionsBeforeWait;
  final Map<String, dynamic> metadata;
}

class VisualTutorBoardEntity {
  const VisualTutorBoardEntity({
    required this.type,
    this.title,
    this.items = const [],
    this.metadata = const {},
  });

  final String type;
  final String? title;
  final List<VisualTutorBoardItemEntity> items;
  final Map<String, dynamic> metadata;
}

class VisualTutorBoardItemEntity {
  const VisualTutorBoardItemEntity({
    required this.label,
    required this.content,
    this.status = 'active',
    this.metadata = const {},
  });

  final String label;
  final String content;
  final String status;
  final Map<String, dynamic> metadata;
}

class VisualTutorBoardActionEntity {
  const VisualTutorBoardActionEntity({
    required this.id,
    required this.type,
    this.sequenceIndex = 0,
    this.durationMs = 0,
    this.waitForSpeechMarker = false,
    this.requiresStudentResponse = false,
    this.groupId,
    this.sectionId,
    this.x,
    this.y,
    this.width,
    this.height,
    this.text,
    this.latex,
    this.points = const [],
    this.graph,
    this.targetId,
    this.style = const {},
    this.locked = false,
    this.hidden = false,
    this.revealPolicy,
    this.metadata = const {},
  });

  final String id;
  final String type;
  final int sequenceIndex;
  final int durationMs;
  final bool waitForSpeechMarker;
  final bool requiresStudentResponse;
  final String? groupId;
  final String? sectionId;
  final double? x;
  final double? y;
  final double? width;
  final double? height;
  final String? text;
  final String? latex;
  final List<Map<String, dynamic>> points;

  /// Mathematical graph data (axes, domain, points and labels), never UI code.
  final Map<String, dynamic>? graph;
  final String? targetId;
  final Map<String, dynamic> style;
  final bool locked;
  final bool hidden;
  final String? revealPolicy;
  final Map<String, dynamic> metadata;

  VisualTutorBoardActionEntity copyWith({
    String? id,
    String? type,
    int? sequenceIndex,
    int? durationMs,
    bool? waitForSpeechMarker,
    bool? requiresStudentResponse,
    String? groupId,
    String? sectionId,
    double? x,
    double? y,
    double? width,
    double? height,
    String? text,
    String? latex,
    List<Map<String, dynamic>>? points,
    Map<String, dynamic>? graph,
    String? targetId,
    Map<String, dynamic>? style,
    bool? locked,
    bool? hidden,
    String? revealPolicy,
    Map<String, dynamic>? metadata,
  }) {
    return VisualTutorBoardActionEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      sequenceIndex: sequenceIndex ?? this.sequenceIndex,
      durationMs: durationMs ?? this.durationMs,
      waitForSpeechMarker: waitForSpeechMarker ?? this.waitForSpeechMarker,
      requiresStudentResponse:
          requiresStudentResponse ?? this.requiresStudentResponse,
      groupId: groupId ?? this.groupId,
      sectionId: sectionId ?? this.sectionId,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      text: text ?? this.text,
      latex: latex ?? this.latex,
      points: points ?? this.points,
      graph: graph ?? this.graph,
      targetId: targetId ?? this.targetId,
      style: style ?? this.style,
      locked: locked ?? this.locked,
      hidden: hidden ?? this.hidden,
      revealPolicy: revealPolicy ?? this.revealPolicy,
      metadata: metadata ?? this.metadata,
    );
  }
}

class VisualTutorCanvasStateEntity {
  const VisualTutorCanvasStateEntity({
    this.viewport = const {},
    this.elements = const [],
    this.focusElementId,
    this.lockedElementIds = const [],
    this.revealedElementIds = const [],
    this.metadata = const {},
  });

  final Map<String, dynamic> viewport;
  final List<Map<String, dynamic>> elements;
  final String? focusElementId;
  final List<String> lockedElementIds;
  final List<String> revealedElementIds;
  final Map<String, dynamic> metadata;
}

class VisualTutorTeachingBoardEntity {
  const VisualTutorTeachingBoardEntity({
    this.id = 'teaching-board',
    this.viewport = const {},
    this.elements = const [],
    this.groups = const [],
    this.sections = const [],
    this.actions = const [],
    this.focusElementId,
    this.activeSectionId,
    this.lockedElementIds = const [],
    this.hiddenElementIds = const [],
    this.fadedElementIds = const [],
    this.metadata = const {},
  });

  final String id;
  final Map<String, dynamic> viewport;
  final List<Map<String, dynamic>> elements;
  final List<Map<String, dynamic>> groups;
  final List<Map<String, dynamic>> sections;
  final List<Map<String, dynamic>> actions;
  final String? focusElementId;
  final String? activeSectionId;
  final List<String> lockedElementIds;
  final List<String> hiddenElementIds;
  final List<String> fadedElementIds;
  final Map<String, dynamic> metadata;
}

class VisualTutorInteractionEntity {
  const VisualTutorInteractionEntity({
    required this.type,
    required this.prompt,
    this.expectedAnswerLocked = true,
    this.validationStrategy,
    this.choices = const [],
    this.inputEnabled = true,
    this.submitLabel = 'Submit',
    this.metadata = const {},
  });

  final String type;
  final String prompt;
  final bool expectedAnswerLocked;
  final String? validationStrategy;
  final List<VisualTutorInteractionChoiceEntity> choices;
  final bool inputEnabled;
  final String submitLabel;
  final Map<String, dynamic> metadata;
}

class VisualTutorInteractionChoiceEntity {
  const VisualTutorInteractionChoiceEntity({
    required this.id,
    required this.label,
    required this.value,
    this.metadata = const {},
  });

  final String id;
  final String label;
  final String value;
  final Map<String, dynamic> metadata;
}

class VisualTutorCurriculumMetadata {
  const VisualTutorCurriculumMetadata({
    this.context,
    this.chunkIds = const [],
    this.confidence,
    this.sources = const [],
    this.prerequisites = const [],
    this.formulas = const [],
    this.commonMisconceptions = const [],
    this.khmerTerms = const {},
  });

  final Object? context;
  final List<String> chunkIds;
  final double? confidence;
  final List<Object> sources;
  final List<String> prerequisites;
  final List<String> formulas;
  final List<String> commonMisconceptions;
  final Map<String, String> khmerTerms;
}
