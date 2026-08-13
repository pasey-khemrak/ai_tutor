// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_service.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../features/visual_tutor/data/datasources/visual_tutor_remote_data_source.dart';
import '../../features/visual_tutor/data/voice_tutor_repository.dart';
import '../../features/visual_tutor/data/repositories/visual_tutor_repository_impl.dart';
import '../../features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import '../../features/visual_tutor/presentation/live_board_state.dart';
import '../../features/visual_tutor/domain/repositories/visual_tutor_repository.dart';
import '../../features/visual_tutor/presentation/visual_tutor_design.dart';
import '../../features/visual_tutor/presentation/widgets/live_teaching_board.dart';
import '../../features/visual_tutor/presentation/visual_tutor_voice.dart';
import '../../features/visual_tutor/presentation/visual_tutor_recorder.dart';
import '../../shared/rean_avatar.dart';
import '../learning_selection/learning_selection_repository.dart';

class TutorScreen extends StatefulWidget {
  const TutorScreen({
    super.key,
    this.context,
    this.repository,
    this.initialSessionId,
    this.initialSubmission,
    this.userId = '',
  });

  final LearningContext? context;
  final VisualTutorRepository? repository;
  final String? initialSessionId;
  final VisualTutorStudentSubmission? initialSubmission;
  final String userId;

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _boardVerticalController = ScrollController();
  final ScrollController _boardHorizontalController = ScrollController();
  final VisualTutorVoiceRuntime _voiceRuntime = VisualTutorVoiceRuntime();
  final VisualTutorRecorder _voiceRecorder = VisualTutorRecorder();
  final VoiceTutorRepository _voiceRepository = VoiceTutorRepository();
  final AudioPlayer _tutorAudioPlayer = AudioPlayer();
  late final VisualTutorRepository _repository;
  VisualTutorTurnResponseEntity _currentTurn = _initialGreetingTurn;
  VisualTutorSessionEntity? _session;
  VisualTutorTurnStateEntity _turnState = const VisualTutorTurnStateEntity();
  List<VisualTutorBoardActionEntity> _renderedBoardActions = const [];
  int _boardVersion = 0;
  int _baseBoardVersion = 0;
  String _boardStateId = 'local-greeting';
  bool _boardRestored = false;
  final List<_TutorHistoryMessage> _history = [
    const _TutorHistoryMessage(
      role: 'Tutor',
      text: 'What lesson or problem do you want to explore today?',
    ),
  ];
  bool _isLoading = false;
  bool _isSpeaking = false;
  Timer? _speechDelayTimer;
  bool _isListening = false;
  bool _isTranscribingVoice = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  int _activeTurnSerial = 0;
  String? _apiError;
  String? _voiceStatus;
  VisualTutorStudentSubmission? _lastFailedSubmission;
  String? _latestStudentMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? _buildDefaultRepository();
    if (widget.initialSessionId != null &&
        widget.initialSessionId!.isNotEmpty) {
      unawaited(_createOrRestoreSession());
    }
    final initialSubmission = widget.initialSubmission;
    if (initialSubmission != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_handleStudentSubmission(initialSubmission));
        }
      });
    }
  }

  @override
  void dispose() {
    _speechDelayTimer?.cancel();
    _activeTurnSerial++;
    _stopTutorSpeech(updateState: false);
    unawaited(_cancelVoiceRecording(updateState: false));
    _recordingTimer?.cancel();
    unawaited(_voiceRecorder.dispose());
    _voiceRuntime.dispose();
    _voiceRepository.close();
    unawaited(_tutorAudioPlayer.dispose());
    _boardVerticalController.dispose();
    _boardHorizontalController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  VisualTutorRepository _buildDefaultRepository() {
    final apiClient = ApiClient(
      config: AppConfig.current,
      tokenProvider: appAuthService.getAccessToken,
    );
    return VisualTutorRepositoryImpl(
      remote: VisualTutorRemoteDataSource(apiClient: apiClient),
    );
  }

  Future<void> _createOrRestoreSession() async {
    try {
      final existingSessionId = widget.initialSessionId;
      final session = existingSessionId == null || existingSessionId.isEmpty
          ? await _repository.createSession(
              VisualTutorSessionCreateRequestEntity(
                userId: widget.userId,
                subject: widget.context?.subject ?? 'Mathematics',
                sessionMode: 'draft',
                topic: widget.context?.topic,
                metadata: _contextMetadata(),
              ),
            )
          : await _repository.restoreSession(existingSessionId);
      if (!mounted) return;
      setState(() {
        _session = session;
        _turnState = VisualTutorTurnStateEntity(
          problemText: session.problemText,
          normalizedProblem: session.normalizedProblem,
          currentStepIndex: session.currentStepIndex,
          hintCount: session.hintCount,
          wrongAttempts: session.wrongAttempts,
          finalAnswerRevealed: session.finalAnswerRevealed,
        );
        _boardVersion = _intFromMap(session.metadata, 'board_version') ?? 0;
        _baseBoardVersion =
            _intFromMap(session.metadata, 'base_board_version') ?? 0;
        _renderedBoardActions = _actionsFromSession(session);
        _boardStateId =
            'session-${session.sessionId}-${session.problemText ?? 'empty'}-${session.currentStepIndex}-${session.playedActionIds.length}';
        _boardRestored = _renderedBoardActions.isNotEmpty;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _apiError = _friendlyError(error));
    }
  }

  Future<void> _handleStudentSubmission(
    VisualTutorStudentSubmission submission,
  ) async {
    if (_isLoading) return;
    final message = submission.message.trim();
    if (message.isEmpty) return;
    final clientTurnId = submission.clientTurnId ?? _newClientTurnId();
    final effectiveSubmission = submission.copyWith(clientTurnId: clientTurnId);
    final requestBoardVersion = _boardVersion;
    final turnSerial = ++_activeTurnSerial;
    String? activeSessionId;
    final appendStudentHistory =
        _lastFailedSubmission?.clientTurnId != clientTurnId;

    _messageController.clear();
    unawaited(_cancelVoiceRecording());
    _stopTutorSpeech();
    setState(() {
      _isLoading = true;
      _voiceStatus = null;
      _apiError = null;
      _lastFailedSubmission = null;
      _latestStudentMessage = message;
      if (appendStudentHistory) {
        _history.add(_TutorHistoryMessage(role: 'You', text: message));
      }
    });

    try {
      final session =
          _session ??
          await _repository.createSession(
            VisualTutorSessionCreateRequestEntity(
              userId: widget.userId,
              subject: widget.context?.subject ?? 'Mathematics',
              sessionMode: _isExplicitTutorAction(effectiveSubmission)
                  ? 'draft'
                  : 'confirmed_problem',
              topic: widget.context?.topic,
              problemText: _isExplicitTutorAction(effectiveSubmission)
                  ? null
                  : message,
              metadata: _contextMetadata(),
            ),
          );
      activeSessionId = session.sessionId;
      final response = await _repository.sendTurn(
        VisualTutorTurnRequestEntity(
          userId: widget.userId,
          sessionId: session.sessionId,
          subject: widget.context?.subject ?? session.subject,
          topic: widget.context?.topic ?? session.topic,
          message: message,
          inputType: _backendInputTypeFor(effectiveSubmission),
          action: _backendActionFor(effectiveSubmission),
          studentIntent: _backendIntentFor(effectiveSubmission),
          currentState: _turnState,
          hintCount: _turnState.hintCount,
          studentSubmittedStep: _isStepSubmission(effectiveSubmission),
          allowFinalAnswer: effectiveSubmission.intent == 'request_answer',
          idempotencyKey: clientTurnId,
          metadata: _requestMetadataFor(
            effectiveSubmission,
            session,
            clientTurnId: clientTurnId,
          ),
        ),
      );
      if (!mounted) return;
      if (turnSerial != _activeTurnSerial) return;
      final responseBaseBoardVersion = _intFromMap(
        response.metadata,
        'base_board_version',
      );
      if (responseBaseBoardVersion != null &&
          responseBaseBoardVersion != requestBoardVersion) {
        await _refreshSessionAfterBoardConflict(
          turnSerial,
          sessionId: session.sessionId,
        );
        if (!mounted || turnSerial != _activeTurnSerial) return;
        setState(() {
          _apiError =
              'Your tutor board was refreshed because another update arrived. Tap retry to send your answer again.';
          _lastFailedSubmission = effectiveSubmission;
        });
        return;
      }
      final responseBoardVersion = _intFromMap(
        response.metadata,
        'board_version',
      );
      if (responseBoardVersion != null &&
          responseBoardVersion < _boardVersion) {
        await _refreshSessionAfterBoardConflict(
          turnSerial,
          sessionId: session.sessionId,
        );
        if (!mounted || turnSerial != _activeTurnSerial) return;
        setState(() {
          _apiError =
              'Your tutor board was refreshed because that response was older than your current lesson. Tap retry to send your answer again.';
          _lastFailedSubmission = effectiveSubmission;
        });
        return;
      }
      final replaceBoard = _shouldReplaceBoardFor(
        effectiveSubmission,
        response,
      );
      final nextBoardActions = _nextRenderedBoardActions(
        response,
        replace: replaceBoard,
        submission: effectiveSubmission,
      );
      setState(() {
        _session = session;
        _currentTurn = response;
        final int previousBoardVersion = _boardVersion;
        _boardVersion =
            (response.metadata['board_version'] as int?) ?? (_boardVersion + 1);
        _baseBoardVersion =
            (response.metadata['base_board_version'] as int?) ??
            previousBoardVersion;
        _turnState = _stateFromResponse(response);
        _renderedBoardActions = nextBoardActions;
        _boardStateId = replaceBoard
            ? 'turn-${response.turnId}-v$_boardVersion'
            : 'board-v$previousBoardVersion-to-v$_boardVersion';
        _boardRestored = false;
        _history.add(
          _TutorHistoryMessage(
            role: 'Tutor',
            text: response.speech?.text ?? response.spokenText,
          ),
        );
      });
      _scrollBoardToLatestWriting();
      unawaited(_speakTutorTurn(response, turnSerial: turnSerial));
      unawaited(_recordProgressSafely(response));
    } catch (error) {
      if (!mounted) return;
      if (turnSerial != _activeTurnSerial) return;
      final recoveredConflict =
          _isBoardVersionConflict(error) &&
          await _refreshSessionAfterBoardConflict(
            turnSerial,
            sessionId: activeSessionId,
          );
      if (!mounted || turnSerial != _activeTurnSerial) return;
      setState(() {
        _apiError = recoveredConflict
            ? 'Your tutor board was refreshed because another update arrived. Tap retry to send your answer again.'
            : _friendlyError(error);
        _lastFailedSubmission = effectiveSubmission;
      });
    } finally {
      if (mounted && turnSerial == _activeTurnSerial) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isBoardVersionConflict(Object error) {
    return error is ApiException && error.statusCode == 409;
  }

  Future<bool> _refreshSessionAfterBoardConflict(
    int turnSerial, {
    String? sessionId,
  }) async {
    sessionId ??= _session?.sessionId;
    if (sessionId == null || sessionId.isEmpty) return false;
    try {
      final restored = await _repository.restoreSession(sessionId);
      if (!mounted || turnSerial != _activeTurnSerial) return false;
      setState(() {
        _session = restored;
        _turnState = VisualTutorTurnStateEntity(
          problemText: restored.problemText,
          normalizedProblem: restored.normalizedProblem,
          currentStepIndex: restored.currentStepIndex,
          hintCount: restored.hintCount,
          wrongAttempts: restored.wrongAttempts,
          finalAnswerRevealed: restored.finalAnswerRevealed,
        );
        _boardVersion = _intFromMap(restored.metadata, 'board_version') ?? 0;
        _baseBoardVersion =
            _intFromMap(restored.metadata, 'base_board_version') ?? 0;
        _renderedBoardActions = _actionsFromSession(restored);
        _boardStateId =
            'recovered-${restored.sessionId}-$_boardVersion-${restored.currentStepIndex}';
        _boardRestored = true;
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  void _cancelActiveTurn() {
    _activeTurnSerial++;
    unawaited(_cancelVoiceRecording());
    _stopTutorSpeech();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _voiceStatus = 'Stopped. You can ask again.';
    });
  }

  void _resetTutorState() {
    _messageController.clear();
    setState(() {
      _currentTurn = _initialGreetingTurn;
      _turnState = const VisualTutorTurnStateEntity();
      _renderedBoardActions = const [];
      _boardStateId = 'local-greeting-${DateTime.now().microsecondsSinceEpoch}';
      _boardRestored = false;
      _session = null;
      _apiError = null;
      _voiceStatus = null;
      _lastFailedSubmission = null;
      _latestStudentMessage = null;
      _history
        ..clear()
        ..add(
          const _TutorHistoryMessage(
            role: 'Tutor',
            text: 'What lesson or problem do you want to explore today?',
          ),
        );
    });
  }

  Duration _speechDelayFor(VisualTutorTurnResponseEntity response) {
    final speakAfterActionId = response.speech?.speakAfterActionId;
    if (speakAfterActionId != null && speakAfterActionId.isNotEmpty) {
      final actions = response.boardActions.isEmpty
          ? response.canvasActions
          : response.boardActions;
      final actionIndex = actions.indexWhere(
        (action) => action.id == speakAfterActionId,
      );
      if (actionIndex >= 0) {
        return Duration(milliseconds: 260 * (actionIndex + 1));
      }
    }
    final pauseAfterMs = response.speech?.pauseAfterMs ?? 0;
    if (pauseAfterMs > 0) return Duration(milliseconds: pauseAfterMs);
    return const Duration(milliseconds: 420);
  }

  Future<void> _speakTutorTurn(
    VisualTutorTurnResponseEntity response, {
    required int turnSerial,
  }) async {
    final text = (response.speech?.text ?? response.spokenText).trim();
    if (text.isEmpty) return;
    _speechDelayTimer?.cancel();
    _speechDelayTimer = Timer(_speechDelayFor(response), () {
      if (!mounted || turnSerial != _activeTurnSerial) return;
      _speakText(text);
    });
  }

  Future<void> _speakText(String text) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;
    _stopTutorSpeech(updateState: false);
    try {
      final audio = await _voiceRepository.synthesize(
        cleaned,
        language: _currentTurn.speech?.language ?? 'en',
      );
      if (!mounted) return;
      await _tutorAudioPlayer.play(BytesSource(audio));
      if (mounted)
        setState(() {
          _isSpeaking = true;
          _voiceStatus = null;
        });
    } catch (_) {
      // Browser synthesis is an explicitly optional fallback only when the
      // authenticated server-side TTS service cannot respond.
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _voiceStatus =
              'Tutor audio is unavailable. Browser speech may be used where supported.';
        });
      }
      if (!mounted) return;
      _voiceRuntime.speak(
        cleaned,
        languageCode: _currentTurn.speech?.language == 'km' ? 'km-KH' : 'en-US',
        onStart: () {
          if (mounted) setState(() => _isSpeaking = true);
        },
        onEnd: () {
          if (mounted) setState(() => _isSpeaking = false);
        },
      );
    }
  }

  void _stopTutorSpeech({bool updateState = true}) {
    _voiceRuntime.stop();
    unawaited(_tutorAudioPlayer.stop());
    if (updateState && mounted) {
      setState(() => _isSpeaking = false);
    } else {
      _isSpeaking = false;
    }
  }

  void _toggleListening() {
    if (_isListening) {
      unawaited(_finishVoiceRecording());
      return;
    }
    unawaited(_startListening());
  }

  Future<void> _startListening() async {
    if (_isLoading) return;
    try {
      if (!await _voiceRecorder.requestPermission()) {
        if (mounted)
          setState(
            () => _voiceStatus =
                'Microphone permission was denied. Allow it and try again.',
          );
        return;
      }
      await _voiceRecorder.start();
      _recordingTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _isListening = true;
        _recordingSeconds = 0;
        _voiceStatus = 'Recording… 0:00. Tap the microphone again to stop.';
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _isListening)
          setState(() {
            _recordingSeconds++;
            _voiceStatus =
                'Recording… ${_recordingSeconds ~/ 60}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}. Tap the microphone again to stop.';
          });
      });
    } catch (_) {
      if (mounted)
        setState(
          () => _voiceStatus =
              'Voice recording is unavailable on this platform. You can type your question instead.',
        );
    }
  }

  Future<void> _finishVoiceRecording() async {
    _recordingTimer?.cancel();
    setState(() {
      _isListening = false;
      _isTranscribingVoice = true;
      _voiceStatus = 'Transcribing your recording…';
    });
    try {
      final audio = await _voiceRecorder.stop();
      if (audio == null || audio.bytes.isEmpty)
        throw const ApiException(message: 'No recording was captured');
      final transcript = await _voiceRepository.transcribe(audio.bytes);
      if (mounted)
        setState(() {
          _messageController.text = transcript;
          _voiceStatus = 'Review and edit the transcript, then send it.';
        });
    } catch (_) {
      if (mounted)
        setState(
          () => _voiceStatus =
              'We could not transcribe that recording. Tap the microphone to retry.',
        );
    } finally {
      if (mounted) setState(() => _isTranscribingVoice = false);
    }
  }

  Future<void> _cancelVoiceRecording({bool updateState = true}) async {
    _recordingTimer?.cancel();
    await _voiceRecorder.cancel();
    if (updateState && mounted) {
      setState(() {
        _isListening = false;
        _voiceStatus = 'Recording cancelled. No audio was sent.';
      });
    } else {
      _isListening = false;
    }
  }

  Future<void> _retryLastSubmission() async {
    final submission = _lastFailedSubmission;
    if (submission != null) {
      await _handleStudentSubmission(submission);
    } else {
      await _createOrRestoreSession();
    }
  }

  Future<void> _recordProgressSafely(
    VisualTutorTurnResponseEntity response,
  ) async {
    final session = _session;
    if (session == null) return;

    final client = ApiClient(
      config: AppConfig.current,
      tokenProvider: appAuthService.getAccessToken,
    );
    final topicId = _topicId(widget.context?.topic ?? session.topic);
    final problem =
        _turnState.problemText ?? _latestStudentMessage ?? 'Tutor session';
    final problemType =
        _stringFromMap(response.board.metadata, 'problem_type') ??
        _stringFromMap(response.metadata, 'problem_type');
    final verification = response.verification;
    final isCorrect =
        verification?.verified == true &&
        (verification?.status == 'correct' ||
            verification?.status == 'mathematically_valid_but_inefficient');
    final tutorSessionPayload = <String, dynamic>{
      'tutor_session_id': session.sessionId,
      'subject_id': _subjectId(widget.context?.subject ?? session.subject),
      'topic_id': topicId,
      'original_question': problem,
      'mastery_signal': response.masterySignal,
      'status': response.masterySignal == 'mastered' ? 'completed' : 'active',
      'metadata': {
        'turn_id': response.turnId,
        'teaching_mode': response.teachingMode,
        'board_version': _boardVersion,
        'hint_count': _turnState.hintCount,
        'wrong_attempts': _turnState.wrongAttempts,
        'final_answer_locked': response.finalAnswerLocked,
        'pending_student_task': response.studentTask,
        'pending_interaction': response.interaction?.prompt,
      },
    };
    if (problemType != null) {
      tutorSessionPayload['detected_problem_type'] = problemType;
    }

    try {
      await client.post('/progress/tutor-sessions', body: tutorSessionPayload);

      // Progress calculations only receive deterministic verifier evidence;
      // an AI phrasing or mastery label cannot create a correct/incorrect fact.
      if ((_latestStudentMessage ?? '').isNotEmpty && verification != null) {
        await client.post(
          '/progress/answers',
          body: {
            'tutor_session_id': session.sessionId,
            'tutor_turn_id': response.turnId,
            'topic_id': topicId,
            'subject_id': _subjectId(
              widget.context?.subject ?? session.subject,
            ),
            'submitted_answer': _latestStudentMessage,
            'answer_format': 'text',
            'is_correct': isCorrect,
            'is_partially_correct':
                verification.status == 'mathematically_valid_but_inefficient',
            'score': isCorrect ? 1 : 0,
            'metadata': {
              'verification': _verificationToJson(verification),
              'verification_verified': verification.verified,
              'verification_status': verification.status,
              'mastery_signal': response.masterySignal,
            },
          },
        );
      }

      if (response.masterySignal == 'mastered' || !response.finalAnswerLocked) {
        await client.post(
          '/progress/lessons/complete',
          body: {
            'tutor_session_id': session.sessionId,
            'topic_id': topicId,
            'subject_id': _subjectId(
              widget.context?.subject ?? session.subject,
            ),
            'mastery_signal': response.masterySignal,
            'completion_status': 'completed',
            'metadata': {'turn_id': response.turnId},
          },
        );
      }
    } catch (_) {
      // Do not silently lose the failure: tutoring stays responsive, while the
      // visible retry affordance keeps the last tutor turn available to retry.
      if (mounted) {
        setState(() {
          _voiceStatus =
              'Learning progress could not sync. Your tutor work is still open; retry when you are online.';
        });
      }
    } finally {
      client.close();
    }
  }

  Map<String, dynamic> _verificationToJson(
    VisualTutorVerificationEntity? verification,
  ) {
    if (verification == null) {
      return const {'status': 'cannot_verify', 'verified': false};
    }
    return {
      'status': verification.status,
      'verified': verification.verified,
      'normalized_expression': verification.normalizedExpression,
      'student_message': verification.studentMessage,
      'solution': verification.solution,
      'evidence': verification.evidence,
    };
  }

  Map<String, dynamic> _contextMetadata() {
    return {
      if (widget.context != null) 'grade': widget.context!.grade,
      if (widget.context != null) 'subject': widget.context!.subject,
      if (widget.context != null) 'topic': widget.context!.topic,
    };
  }

  String _backendActionFor(VisualTutorStudentSubmission submission) {
    final intent = submission.intent.trim().toLowerCase();
    if (!_isExplicitTutorAction(submission)) {
      // Preserve the student's raw typed intent; the gateway maps this safely
      // to a new-problem or step action after considering persisted state.
      return 'student_message';
    }
    if (intent == 'new_problem') return 'submit_problem';
    if (intent == 'request_hint') return 'request_hint';
    if (intent == 'stuck') return 'request_stuck_help';
    if (intent == 'request_explain_differently') {
      return 'explain_differently';
    }
    if (intent == 'request_answer') return 'request_final_answer';
    if (intent == 'check_work') return 'submit_step';
    return 'submit_step';
  }

  String? _backendIntentFor(VisualTutorStudentSubmission submission) {
    final intent = submission.intent.trim().toLowerCase();
    if (!_isExplicitTutorAction(submission)) return null;
    if (intent == 'request_hint' ||
        intent == 'stuck' ||
        intent == 'request_explain_differently' ||
        intent == 'request_answer' ||
        intent == 'check_work') {
      return intent;
    }
    return null;
  }

  bool _isStepSubmission(VisualTutorStudentSubmission submission) {
    return _isExplicitTutorAction(submission) &&
        submission.intent.trim().toLowerCase() == 'check_work';
  }

  bool _isExplicitTutorAction(VisualTutorStudentSubmission submission) {
    return submission.inputType.trim().toLowerCase() == 'quick_action';
  }

  String _backendInputTypeFor(VisualTutorStudentSubmission submission) {
    final type = submission.inputType.trim().toLowerCase();
    if (type == 'voice' || type == 'voice_response') return 'voice';
    return 'text';
  }

  Map<String, dynamic> _requestMetadataFor(
    VisualTutorStudentSubmission submission,
    VisualTutorSessionEntity session, {
    required String clientTurnId,
  }) {
    return {
      ..._contextMetadata(),
      ...submission.metadata,
      'client_turn_id': clientTurnId,
      'idempotency_key': clientTurnId,
      'client_intent_hint': submission.intent,
      'client_action_hint': submission.action,
      'current_screen_state': _currentTurn.screenState,
      'current_tutor_status': _currentTurn.tutorStatus,
      'current_turn_id': _currentTurn.turnId,
      'session_id': session.sessionId,
      'client_board_version': _boardVersion,
      'client_base_board_version': _baseBoardVersion,
      'current_step_index': _turnState.currentStepIndex,
      'final_answer_revealed': _turnState.finalAnswerRevealed,
    };
  }

  String _newClientTurnId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final nonce = math.Random().nextInt(0x7fffffff);
    return 'client-turn-$timestamp-$nonce';
  }

  VisualTutorTurnStateEntity _stateFromResponse(
    VisualTutorTurnResponseEntity response,
  ) {
    final metadata = response.metadata;
    final boardMetadata = response.board.metadata;
    final problemText =
        _stringFromMap(boardMetadata, 'problem_text') ??
        _problemFromBoard(response.board) ??
        _turnState.problemText ??
        _latestStudentMessage;
    return VisualTutorTurnStateEntity(
      problemText: problemText,
      normalizedProblem:
          _stringFromMap(boardMetadata, 'normalized_problem') ??
          _stringFromMap(metadata, 'normalized_problem') ??
          _turnState.normalizedProblem,
      currentStepIndex:
          _intFromMap(boardMetadata, 'current_step_index') ??
          _intFromMap(metadata, 'current_step_index') ??
          _turnState.currentStepIndex,
      hintCount:
          _intFromMap(metadata, 'hint_count') ??
          (response.teachingMode == 'hint'
              ? _turnState.hintCount + 1
              : _turnState.hintCount),
      wrongAttempts:
          _intFromMap(metadata, 'wrong_attempts') ?? _turnState.wrongAttempts,
      finalAnswerRevealed: !response.finalAnswerLocked,
      studentSubmittedStep: false,
    );
  }

  List<VisualTutorBoardActionEntity> _nextRenderedBoardActions(
    VisualTutorTurnResponseEntity response, {
    required bool replace,
    required VisualTutorStudentSubmission submission,
  }) {
    final transcriptActions = _transcriptActionsForResponse(
      response,
      submission: submission,
      appendToCurrentBoard: !replace,
    );
    if (transcriptActions.isNotEmpty) {
      if (replace || _renderedBoardActions.isEmpty) return transcriptActions;
      return [..._renderedBoardActions, ...transcriptActions]
        ..sort((a, b) => a.sequenceIndex.compareTo(b.sequenceIndex));
    }

    final snapshotActions = _actionsFromTeachingBoard(response.teachingBoard);
    if (snapshotActions.isNotEmpty) {
      return snapshotActions;
    }

    final responseActions = response.boardActions.isEmpty
        ? response.canvasActions
        : response.boardActions;
    if (replace) {
      return responseActions;
    }

    final boardUpdateMode =
        response.metadata['board_update_mode']?.toString() ?? 'merge';
    if (boardUpdateMode == 'patch' && _renderedBoardActions.isNotEmpty) {
      return applyVisualTutorBoardPatch(_renderedBoardActions, responseActions);
    }

    final byId = <String, VisualTutorBoardActionEntity>{
      for (final action in _renderedBoardActions) action.id: action,
    };
    for (final action in responseActions) {
      byId[action.id] = action;
    }
    final actions = byId.values.toList()
      ..sort((a, b) => a.sequenceIndex.compareTo(b.sequenceIndex));
    return actions;
  }

  List<VisualTutorBoardActionEntity> _transcriptActionsForResponse(
    VisualTutorTurnResponseEntity response, {
    required VisualTutorStudentSubmission submission,
    required bool appendToCurrentBoard,
  }) {
    final metadata = response.board.metadata;
    final variant = _variantForResponse(response);
    final baseY = appendToCurrentBoard ? _nextTranscriptY() : 36.0;
    final baseSequence = appendToCurrentBoard
        ? _nextTranscriptSequenceIndex()
        : 0;
    final turnPrefix = 'turn-${response.turnId}';
    if (variant == 'asking_question') {
      final problem =
          _stringFromMap(metadata, 'problem') ??
          _problemFromBoard(response.board);
      final question = _stringFromMap(metadata, 'handwritten_question');
      final equation = _stringFromMap(metadata, 'equation_with_blank');
      final actions = <VisualTutorBoardActionEntity>[];
      if (problem != null && problem.trim().isNotEmpty) {
        actions.add(
          _transcriptAction(
            id: '$turnPrefix-problem',
            type: 'write_equation',
            sequenceIndex: baseSequence,
            y: baseY,
            text: problem,
            latex: problem,
            fontSize: 30,
          ),
        );
      }
      if (question != null && question.trim().isNotEmpty) {
        actions.add(
          _transcriptAction(
            id: '$turnPrefix-question',
            type: 'write_text',
            sequenceIndex: baseSequence + 1,
            y: baseY + 70,
            text: question,
            ink: 'blue',
            fontSize: 25,
          ),
        );
      }
      if (equation != null && equation.trim().isNotEmpty) {
        actions.add(
          _transcriptAction(
            id: '$turnPrefix-operation',
            type: 'write_text',
            sequenceIndex: baseSequence + 2,
            y: baseY + 118,
            x: 72,
            text: equation,
            ink: 'blue',
            fontSize: 24,
          ),
        );
        actions.add(
          _transcriptAction(
            id: '$turnPrefix-blank',
            type: 'create_blank',
            sequenceIndex: baseSequence + 3,
            y: baseY + 162,
            x: 96,
            width: 84,
            height: 58,
          ),
        );
      }
      return actions;
    }

    if (variant == 'check_my_work' ||
        response.teachingMode == 'misconception_fix') {
      final currentEquation =
          _boardActionText(response.boardActions, 'write_equation') ??
          _boardItemContent(response.board, 'Step 1');
      final prompt =
          _boardActionText(response.boardActions, 'write_text') ??
          _studentTaskQuestion(response.studentTask) ??
          response.displayText;
      final mistakeMessage =
          _stringFromMap(metadata, 'mistake_message') ??
          'Check your step here!';
      final actions = <VisualTutorBoardActionEntity>[
        _transcriptAction(
          id: '$turnPrefix-student-step',
          type: 'write_text',
          sequenceIndex: baseSequence,
          y: baseY,
          text: 'Student: ${submission.message}',
          fontSize: 21,
          metadata: const {'faded': true},
        ),
        _transcriptAction(
          id: '$turnPrefix-check-feedback',
          type: 'write_text',
          sequenceIndex: baseSequence + 1,
          y: baseY + 44,
          text: mistakeMessage,
          ink: 'red',
          fontSize: 22,
        ),
      ];
      if (currentEquation != null && currentEquation.trim().isNotEmpty) {
        actions.add(
          _transcriptAction(
            id: '$turnPrefix-current-equation',
            type: 'write_equation',
            sequenceIndex: baseSequence + 2,
            y: baseY + 96,
            text: currentEquation,
            latex: currentEquation,
            fontSize: 30,
            metadata: const {'highlighted': true},
          ),
        );
      }
      if (prompt.trim().isNotEmpty) {
        actions.add(
          _transcriptAction(
            id: '$turnPrefix-next-prompt',
            type: 'write_text',
            sequenceIndex: baseSequence + 3,
            y: baseY + 158,
            text: prompt,
            ink: 'blue',
            fontSize: 23,
          ),
        );
      }
      return actions;
    }

    if (variant == 'final_verified_answer' ||
        response.masterySignal == 'mastered') {
      final finalAnswer =
          _boardItemContent(response.board, 'Final') ??
          _boardActionText(response.boardActions, 'write_equation') ??
          response.displayText;
      final checkLine =
          _firstDifferentEquationActionText(
            response.boardActions,
            differentFrom: finalAnswer,
          ) ??
          _verificationLineFor(
            problem: _problemFromBoard(response.board),
            finalAnswer: finalAnswer,
          );
      final actions = <VisualTutorBoardActionEntity>[
        _transcriptAction(
          id: '$turnPrefix-student-final',
          type: 'write_text',
          sequenceIndex: baseSequence,
          y: baseY,
          text: 'Student: ${submission.message}',
          fontSize: 21,
          metadata: const {'faded': true},
        ),
        _transcriptAction(
          id: '$turnPrefix-final-correct',
          type: 'write_text',
          sequenceIndex: baseSequence + 1,
          y: baseY + 44,
          text: response.spokenText,
          ink: 'green',
          fontSize: 22,
        ),
        _transcriptAction(
          id: '$turnPrefix-final-answer',
          type: 'write_equation',
          sequenceIndex: baseSequence + 2,
          y: baseY + 100,
          text: finalAnswer,
          latex: finalAnswer,
          ink: 'blue',
          fontSize: 34,
          metadata: const {'highlighted': true},
        ),
      ];
      if (checkLine != null && checkLine.trim().isNotEmpty) {
        actions.add(
          _transcriptAction(
            id: '$turnPrefix-final-check',
            type: 'write_equation',
            sequenceIndex: baseSequence + 3,
            y: baseY + 158,
            text: checkLine,
            latex: checkLine,
            fontSize: 24,
          ),
        );
      }
      actions.add(
        _transcriptAction(
          id: '$turnPrefix-final-summary',
          type: 'write_text',
          sequenceIndex: baseSequence + 4,
          y: baseY + 214,
          text: "Problem solved. You've mastered this problem.",
          ink: 'blue',
          fontSize: 23,
        ),
      );
      return actions;
    }

    if (response.teachingMode == 'step_check') {
      final step = _boardItemContent(response.board, 'Step 1');
      final operation = _boardItemMetadataString(
        response.board,
        'Step 1',
        'operation',
      );
      final expandedStep = _expandedLinearStep(
        problem: _problemFromBoard(response.board),
        operation: operation,
      );
      final coefficient = _stringFromMap(metadata, 'coefficient');
      final variable = _linearVariableFromProblem(
        _problemFromBoard(response.board),
      );
      final actions = <VisualTutorBoardActionEntity>[
        _transcriptAction(
          id: '$turnPrefix-student-step',
          type: 'write_text',
          sequenceIndex: baseSequence,
          y: baseY,
          text: 'Student: ${submission.message}',
          fontSize: 21,
          metadata: const {'faded': true},
        ),
        _transcriptAction(
          id: '$turnPrefix-correct',
          type: 'write_text',
          sequenceIndex: baseSequence + 1,
          y: baseY + 44,
          text: operation == null
              ? 'Yes, correct.'
              : 'Yes, correct: $operation.',
          fontSize: 22,
        ),
      ];
      if (expandedStep != null) {
        actions.add(
          _transcriptAction(
            id: '$turnPrefix-expanded-step',
            type: 'write_equation',
            sequenceIndex: baseSequence + 2,
            y: baseY + 90,
            text: expandedStep,
            latex: expandedStep,
            fontSize: 26,
          ),
        );
      }
      if (step != null && step.trim().isNotEmpty) {
        actions.add(
          _transcriptAction(
            id: '$turnPrefix-simplified-step',
            type: 'write_equation',
            sequenceIndex: baseSequence + 3,
            y: baseY + 142,
            text: step,
            latex: step,
            fontSize: 30,
          ),
        );
      }
      if (coefficient != null && variable != null) {
        actions.add(
          _transcriptAction(
            id: '$turnPrefix-next-question',
            type: 'write_text',
            sequenceIndex: baseSequence + 4,
            y: baseY + 204,
            text: 'Step 2: divide both sides by $coefficient',
            ink: 'blue',
            fontSize: 24,
          ),
        );
        actions.add(
          _transcriptAction(
            id: '$turnPrefix-next-task',
            type: 'write_text',
            sequenceIndex: baseSequence + 5,
            y: baseY + 248,
            x: 72,
            text: '$variable = ?',
            ink: 'blue',
            fontSize: 25,
          ),
        );
      }
      return actions;
    }

    return const [];
  }

  VisualTutorBoardActionEntity _transcriptAction({
    required String id,
    required String type,
    required int sequenceIndex,
    required double y,
    double x = 40,
    double width = 760,
    double height = 44,
    String? text,
    String? latex,
    String? ink,
    double? fontSize,
    Map<String, dynamic> metadata = const {},
  }) {
    final style = <String, dynamic>{};
    if (ink != null) style['ink'] = ink;
    if (fontSize != null) style['size'] = fontSize;
    return VisualTutorBoardActionEntity(
      id: id,
      type: type,
      sequenceIndex: sequenceIndex,
      x: x,
      y: y,
      width: width,
      height: height,
      text: text,
      latex: latex,
      style: style,
      metadata: {'transcript': true, ...metadata},
    );
  }

  double _nextTranscriptY() {
    if (_renderedBoardActions.isEmpty) return 36;
    var bottom = 0.0;
    for (final action in _renderedBoardActions) {
      if (action.hidden) continue;
      final y = action.y ?? 0;
      final height = action.height ?? 44;
      bottom = math.max(bottom, y + height);
    }
    return bottom + 34;
  }

  double _boardContentBottom() {
    final actions = _renderedBoardActions.isEmpty
        ? (_currentTurn.boardActions.isEmpty
              ? _currentTurn.canvasActions
              : _currentTurn.boardActions)
        : _renderedBoardActions;
    var bottom = 0.0;
    for (final action in actions) {
      if (action.hidden) continue;
      final y = action.y ?? 0;
      final height = action.height ?? 44;
      bottom = math.max(bottom, y + height);
    }
    return bottom;
  }

  void _scrollBoardToLatestWriting() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_boardVerticalController.hasClients) return;
      final target = _boardVerticalController.position.maxScrollExtent;
      _boardVerticalController.animateTo(
        target,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    });
  }

  int _nextTranscriptSequenceIndex() {
    if (_renderedBoardActions.isEmpty) return 0;
    return _renderedBoardActions
            .map((action) => action.sequenceIndex)
            .reduce(math.max) +
        1;
  }

  List<VisualTutorBoardActionEntity> _actionsFromSession(
    VisualTutorSessionEntity session,
  ) {
    final teachingBoardActions = _actionsFromTeachingBoard(
      session.teachingBoard,
    );
    if (teachingBoardActions.isNotEmpty) return teachingBoardActions;
    return _actionsFromBoardElements(session.visibleBoardElements);
  }

  List<VisualTutorBoardActionEntity> _actionsFromTeachingBoard(
    VisualTutorTeachingBoardEntity? teachingBoard,
  ) {
    if (teachingBoard == null) return const [];
    final elementActions = _actionsFromBoardElements(teachingBoard.elements);
    if (elementActions.isNotEmpty) return elementActions;
    return teachingBoard.actions
        .map(_actionFromMap)
        .whereType<VisualTutorBoardActionEntity>()
        .toList()
      ..sort((a, b) => a.sequenceIndex.compareTo(b.sequenceIndex));
  }

  List<VisualTutorBoardActionEntity> _actionsFromBoardElements(
    List<Map<String, dynamic>> elements,
  ) {
    final actions = <VisualTutorBoardActionEntity>[];
    for (var index = 0; index < elements.length; index++) {
      final action = _actionFromElement(elements[index], index);
      if (action != null) actions.add(action);
    }
    actions.sort((a, b) => a.sequenceIndex.compareTo(b.sequenceIndex));
    return actions;
  }

  VisualTutorBoardActionEntity? _actionFromMap(Map<String, dynamic> map) {
    final id = map['id']?.toString();
    if (id == null || id.isEmpty) return null;
    return VisualTutorBoardActionEntity(
      id: id,
      type: map['type']?.toString() ?? 'write_text',
      sequenceIndex: _intFromMap(map, 'sequence_index') ?? 0,
      durationMs: _intFromMap(map, 'duration_ms') ?? 0,
      waitForSpeechMarker: map['wait_for_speech_marker'] == true,
      requiresStudentResponse: map['requires_student_response'] == true,
      groupId: map['group_id']?.toString(),
      sectionId: map['section_id']?.toString(),
      x: _doubleFromMap(map, 'x'),
      y: _doubleFromMap(map, 'y'),
      width: _doubleFromMap(map, 'width'),
      height: _doubleFromMap(map, 'height'),
      text: map['text']?.toString(),
      latex: map['latex']?.toString(),
      points: _listOfMaps(map['points']),
      targetId: map['target_id']?.toString(),
      style: _mapFromObject(map['style']),
      locked: map['locked'] == true,
      hidden: map['hidden'] == true,
      revealPolicy: map['reveal_policy']?.toString(),
      metadata: _mapFromObject(map['metadata']),
    );
  }

  VisualTutorBoardActionEntity? _actionFromElement(
    Map<String, dynamic> element,
    int index,
  ) {
    final id = element['id']?.toString();
    if (id == null || id.isEmpty) return null;
    final elementType = element['type']?.toString() ?? 'text';
    final actionType = switch (elementType) {
      'equation' => 'write_equation',
      'text' || 'handwriting_style_text' => 'write_text',
      'point' => 'draw_point',
      'line' => 'draw_line',
      'arrow' => 'draw_arrow',
      'axes' => 'draw_axes',
      'graph' => 'show_graph',
      'table' => 'show_table',
      'blank' => 'create_blank',
      'highlight' => 'highlight',
      'circle' => 'circle',
      'cross_out' || 'mistake_marker' => 'cross_out',
      _ => 'write_text',
    };
    final metadata = _mapFromObject(element['metadata']);
    return VisualTutorBoardActionEntity(
      id: id,
      type: actionType,
      sequenceIndex:
          _intFromMap(element, 'sequence_index') ??
          _intFromMap(element, 'z_index') ??
          index,
      x: _doubleFromMap(element, 'x'),
      y: _doubleFromMap(element, 'y'),
      width: _doubleFromMap(element, 'width'),
      height: _doubleFromMap(element, 'height'),
      text: element['text']?.toString() ?? element['content']?.toString(),
      latex: element['latex']?.toString(),
      points: _listOfMaps(element['points']),
      groupId: element['group_id']?.toString(),
      sectionId: element['section_id']?.toString(),
      style: _mapFromObject(element['style']),
      locked: element['locked'] == true,
      hidden: element['hidden'] == true,
      metadata: {
        ...metadata,
        if (element['focus'] == true) 'current_step': true,
        if (element['faded'] == true) 'faded': true,
      },
    );
  }

  bool _shouldReplaceBoardFor(
    VisualTutorStudentSubmission submission,
    VisualTutorTurnResponseEntity response,
  ) {
    final action = _backendActionFor(submission);
    final previousProblem = _turnState.problemText?.trim();
    final nextProblem =
        _stringFromMap(response.board.metadata, 'problem_text') ??
        _problemFromBoard(response.board);
    if (action == 'submit_problem') return true;
    final sameProblem =
        nextProblem != null &&
        nextProblem.trim().isNotEmpty &&
        previousProblem != null &&
        previousProblem.isNotEmpty &&
        nextProblem.trim() == previousProblem;
    if (sameProblem) return false;
    if (nextProblem != null &&
        nextProblem.trim().isNotEmpty &&
        previousProblem != null &&
        previousProblem.isNotEmpty &&
        nextProblem.trim() != previousProblem) {
      return true;
    }
    final teachingBoardMode = response.teachingBoard?.metadata['update_mode'];
    return teachingBoardMode == 'replace' ||
        response.metadata['board_update_mode'] == 'replace';
  }

  String? _problemFromBoard(VisualTutorBoardEntity board) {
    for (final item in board.items) {
      if (item.label.toLowerCase() == 'problem' && item.content.isNotEmpty) {
        return item.content;
      }
    }
    return null;
  }

  String _variantForResponse(VisualTutorTurnResponseEntity response) {
    final metadata = response.board.metadata;
    final explicit = response.screenState.trim().toLowerCase();
    return (explicit != 'speaking_writing'
            ? explicit
            : (metadata['screen_state'] ??
                  metadata['board_type'] ??
                  response.board.type))
        .toString()
        .trim()
        .toLowerCase();
  }

  String? _boardItemContent(VisualTutorBoardEntity board, String label) {
    final target = label.trim().toLowerCase();
    for (final item in board.items) {
      if (item.label.trim().toLowerCase() == target &&
          item.content.trim().isNotEmpty) {
        return item.content.trim();
      }
    }
    return null;
  }

  String? _boardActionText(
    List<VisualTutorBoardActionEntity> actions,
    String type,
  ) {
    for (final action in actions) {
      if (action.type == type &&
          (action.text ?? action.latex ?? '').trim().isNotEmpty) {
        return (action.text ?? action.latex)!.trim();
      }
    }
    return null;
  }

  String? _firstDifferentEquationActionText(
    List<VisualTutorBoardActionEntity> actions, {
    required String differentFrom,
  }) {
    final normalizedDifferent = differentFrom.trim();
    for (final action in actions) {
      if (action.type != 'write_equation') continue;
      final text = (action.text ?? action.latex ?? '').trim();
      if (text.isNotEmpty && text != normalizedDifferent) return text;
    }
    return null;
  }

  String? _studentTaskQuestion(String task) {
    final trimmed = task.trim();
    if (trimmed.isEmpty) return null;
    final firstSentence = RegExp(r'^([^?]+\?)').firstMatch(trimmed);
    return firstSentence?.group(1)?.trim() ?? trimmed;
  }

  String? _verificationLineFor({String? problem, required String finalAnswer}) {
    final variable = _linearVariableFromProblem(problem);
    if (variable == null) return null;
    final match = RegExp(
      '^${RegExp.escape(variable)}\\s*=\\s*([-+]?\\d+(?:\\.\\d+)?)\$',
      caseSensitive: false,
    ).firstMatch(finalAnswer.trim());
    if (match == null) return null;
    final value = match.group(1)!;
    if (problem == null || !problem.contains(variable)) return null;
    return '${problem.replaceFirst(variable, '($value)')} checks';
  }

  String? _boardItemMetadataString(
    VisualTutorBoardEntity board,
    String label,
    String key,
  ) {
    final target = label.trim().toLowerCase();
    for (final item in board.items) {
      if (item.label.trim().toLowerCase() == target) {
        final text = item.metadata[key]?.toString().trim();
        return text == null || text.isEmpty ? null : text;
      }
    }
    return null;
  }

  String? _expandedLinearStep({String? problem, String? operation}) {
    if (problem == null || operation == null || !problem.contains('=')) {
      return null;
    }
    final sides = problem.split('=');
    if (sides.length != 2) return null;
    final match = RegExp(
      r'^(add|subtract)\s+([-+]?\d+(?:/\d+)?(?:\.\d+)?)$',
      caseSensitive: false,
    ).firstMatch(operation.trim());
    if (match == null) return null;
    final symbol = match.group(1)!.toLowerCase() == 'add' ? '+' : '-';
    final value = match.group(2)!;
    return '${sides[0].trim()} $symbol $value = ${sides[1].trim()} $symbol $value';
  }

  String? _linearVariableFromProblem(String? problem) {
    if (problem == null) return null;
    return RegExp(r'[a-zA-Z]').firstMatch(problem)?.group(0);
  }

  String? _stringFromMap(Map<String, dynamic> map, String key) {
    final value = map[key];
    return value?.toString();
  }

  int? _intFromMap(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _doubleFromMap(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> _mapFromObject(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>> _listOfMaps(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _subjectId(String? subject) {
    final normalized = (subject ?? '').trim().toLowerCase();
    if (normalized.startsWith('math')) return 'math';
    return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  }

  String _topicId(String? topic) {
    final normalized = (topic ?? 'linear-equations').trim().toLowerCase();
    return normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  String _friendlyError(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 409) {
        return 'The board changed while that was loading. Retry from the latest board.';
      }
      return error.message;
    }
    return 'Could not reach the tutor service. Check the backend and try again.';
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VisualTutorColors.shell,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            children: [
              TutorPresenceBar(
                learningContext: widget.context,
                stageState: _currentTurn.teachingStage?.stageState,
                compact: true,
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: _teachingBoard(compact: true)),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _FloatingTutorControls(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                          child: Column(children: _lowerTutorControls(true)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teachingBoard({required bool compact}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardVariant = _variantForCurrentTurn();
        final hasLiveTranscript = _renderedBoardActions.any(
          (action) => action.metadata['transcript'] == true,
        );
        final effectiveBoardVariant = hasLiveTranscript
            ? 'speaking_writing'
            : boardVariant;
        final usesDedicatedVariant = _usesDedicatedBoardVariant(
          effectiveBoardVariant,
        );
        final canvasWidth = usesDedicatedVariant
            ? constraints.maxWidth
            : math.max(constraints.maxWidth, 1000.0);
        final contentHeight = _boardContentBottom() + 360;
        final canvasHeight = math.max(
          math.max(constraints.maxHeight + 360, 980.0),
          contentHeight,
        );
        return Stack(
          children: [
            Scrollbar(
              controller: _boardVerticalController,
              thumbVisibility: false,
              child: Scrollbar(
                controller: _boardHorizontalController,
                notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.horizontal,
                scrollbarOrientation: ScrollbarOrientation.bottom,
                thumbVisibility: false,
                child: SingleChildScrollView(
                  key: const Key('visual-tutor-board-vertical-scroll'),
                  controller: _boardVerticalController,
                  physics: const BouncingScrollPhysics(),
                  child: SingleChildScrollView(
                    key: const Key('visual-tutor-board-horizontal-scroll'),
                    controller: _boardHorizontalController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: canvasWidth,
                      height: canvasHeight,
                      child: TeachingCanvasBoard(
                        key: ValueKey(_boardStateId),
                        variant: effectiveBoardVariant,
                        board: _currentTurn.board,
                        actions: _renderedBoardActions.isEmpty
                            ? (_currentTurn.boardActions.isEmpty
                                  ? _currentTurn.canvasActions
                                  : _currentTurn.boardActions)
                            : _renderedBoardActions,
                        finalAnswerLocked: _currentTurn.finalAnswerLocked,
                        compact: compact,
                        restored: _boardRestored,
                        useLogicalCanvasScale: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  key: Key('visual-tutor-loading-indicator'),
                  minHeight: 3,
                  color: VisualTutorColors.cyan,
                  backgroundColor: Colors.transparent,
                ),
              ),
          ],
        );
      },
    );
  }

  String _variantForCurrentTurn() {
    final metadata = _currentTurn.board.metadata;
    final explicit = _currentTurn.screenState.trim().toLowerCase();
    return (explicit != 'speaking_writing'
            ? explicit
            : (metadata['screen_state'] ??
                  metadata['board_type'] ??
                  _currentTurn.board.type ??
                  'speaking_writing'))
        .toString()
        .trim()
        .toLowerCase();
  }

  bool _usesDedicatedBoardVariant(String variant) {
    return variant == 'graph_based' ||
        variant == 'check_my_work' ||
        variant == 'final_verified_answer' ||
        variant == 'unsupported_problem';
  }

  List<Widget> _lowerTutorControls(bool compact) {
    final speechText = _currentTurn.speech?.text ?? _currentTurn.spokenText;
    return [
      const SizedBox(height: 12),
      if (_apiError != null) ...[
        _TutorApiErrorBanner(
          key: const Key('visual-tutor-api-error'),
          message: _apiError!,
          onRetry: _retryLastSubmission,
        ),
        const SizedBox(height: 10),
      ],
      if (_isLoading) ...[
        _TutorLoadingControls(onCancel: _cancelActiveTurn),
        const SizedBox(height: 10),
      ],
      if (_isTranscribingVoice) ...[
        const LinearProgressIndicator(key: Key('voice-transcribing')),
        const SizedBox(height: 10),
      ],
      TutorSpeechQuotePanel(
        speechText: speechText,
        compact: compact,
        isSpeaking: _isSpeaking,
        onReplay: () => _speakText(speechText),
        onStop: _stopTutorSpeech,
      ),
      const SizedBox(height: 6),
      StudentInteractionPanel(
        controller: _messageController,
        turn: _currentTurn,
        latestStudentMessage: _latestStudentMessage,
        onSubmit: _handleStudentSubmission,
        onReset: _resetTutorState,
        compact: compact,
        isListening: _isListening,
        voiceStatus: _voiceStatus,
        onVoiceInput: _toggleListening,
      ),
    ];
  }
}

const _initialGreetingTurn = VisualTutorTurnResponseEntity(
  sessionId: 'local-greeting-session',
  turnId: 'local-greeting-turn',
  spokenText: 'What lesson or problem do you want to explore today?',
  displayText: 'What lesson or problem do you want to explore today?',
  teachingMode: 'guided_question',
  finalAnswerLocked: true,
  studentTask: 'Type or say a problem to start a live tutor session.',
  board: VisualTutorBoardEntity(
    type: 'teaching_stage',
    title: 'Rean AI Visual Tutor',
    metadata: {'screen_state': 'speaking_writing'},
  ),
  speech: VisualTutorSpeechEntity(
    text: 'What lesson or problem do you want to explore today?',
    ttsStatus: 'ready',
  ),
  teachingStage: VisualTutorTeachingStageEntity(
    stageState: 'waiting_for_student',
    lessonState: 'understand_request',
    turnGoal: 'Wait for the student to choose a problem.',
  ),
  interaction: VisualTutorInteractionEntity(
    type: 'text_response',
    prompt: 'Type or say a problem to start.',
    submitLabel: 'Submit',
  ),
  allowedActions: ['submit_answer', 'stuck'],
  nextStudentAction: {
    'type': 'text_response',
    'prompt': 'Type or say a problem to start.',
  },
  metadata: {'source': 'local_greeting'},
);

class _TutorHistoryMessage {
  const _TutorHistoryMessage({required this.role, required this.text});

  final String role;
  final String text;
}

class TutorPresenceBar extends StatelessWidget {
  const TutorPresenceBar({
    super.key,
    required this.learningContext,
    this.stageState,
    this.compact = false,
  });

  final LearningContext? learningContext;
  final String? stageState;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final status = _statusFor(stageState);

    return Container(
      key: const Key('tutor-presence-bar'),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 20 : 24,
        vertical: compact ? 14 : 16,
      ),
      decoration: VisualTutorDecorations.presenceBar(),
      child: Row(
        children: [
          // ── Avatar with status glow ──────────────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              ReanAvatar(size: compact ? 42 : 48),
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: stageState == 'analyzing' || stageState == 'drawing'
                        ? VisualTutorColors.orange
                        : VisualTutorColors.cyan,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: VisualTutorColors.presenceBarBg,
                      width: 1.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // ── Title + status ───────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Rean AI Tutor',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VisualTutorTypography.presenceTitle,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      status.english,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VisualTutorTypography.presenceStatus,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status.khmer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VisualTutorTypography.presenceStatus.copyWith(
                        color: VisualTutorColors.cyan.withValues(alpha: .6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Teaching mode chip + menu ────────────────────────────────────
          if (stageState != null && stageState != 'waiting_for_student')
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: VisualTutorColors.cyan.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(VisualTutorRadius.pill),
                  border: Border.all(
                    color: VisualTutorColors.cyan.withValues(alpha: .35),
                  ),
                ),
                child: Text(
                  _statusChipLabel(stageState!),
                  style: const TextStyle(
                    color: VisualTutorColors.cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                    fontFamilyFallback: VisualTutorTypography.fontFallback,
                  ),
                ),
              ),
            ),
          Container(
            width: compact ? 36 : 40,
            height: compact ? 36 : 40,
            decoration: BoxDecoration(
              color: VisualTutorColors.panelRaised,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: VisualTutorColors.border),
            ),
            child: IconButton(
              tooltip: 'Tutor menu',
              onPressed: () {},
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: VisualTutorColors.textMuted,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusChipLabel(String stageState) {
    return switch (stageState.toLowerCase().replaceAll('-', '_')) {
      'drawing' => 'WRITING',
      'speaking' => 'EXPLAINING',
      'analyzing' => 'THINKING',
      'evaluating' || 'checking' => 'CHECKING',
      'adapting' || 'reteaching' => 'ADAPTING',
      'listening' => 'LISTENING',
      _ => 'ACTIVE',
    };
  }

  _TutorStatusText _statusFor(String? value) {
    final normalized = (value ?? 'waiting_for_student')
        .toLowerCase()
        .replaceAll('-', '_')
        .trim();
    return switch (normalized) {
      'drawing' => const _TutorStatusText('Writing...', 'កំពុងសរសេរ...'),
      'speaking' => const _TutorStatusText('Explaining...', 'កំពុងពន្យល់...'),
      'analyzing' => const _TutorStatusText('Thinking...', 'កំពុងគិត...'),
      'evaluating' ||
      'checking' => const _TutorStatusText('Checking...', 'កំពុងពិនិត្យ...'),
      'adapting' || 'reteaching' => const _TutorStatusText(
        'Adapting...',
        'កំពុងកែវិធីពន្យល់...',
      ),
      'listening' => const _TutorStatusText('Listening...', 'កំពុងស្តាប់...'),
      _ => const _TutorStatusText('Waiting for you', 'រង់ចាំអ្នក'),
    };
  }
}

class _FloatingTutorControls extends StatelessWidget {
  const _FloatingTutorControls({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            VisualTutorColors.shell.withValues(alpha: 0),
            VisualTutorColors.shell.withValues(alpha: .88),
            VisualTutorColors.shell,
          ],
          stops: const [0, .22, .48],
        ),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

class _TutorStatusText {
  const _TutorStatusText(this.english, this.khmer);

  final String english;
  final String khmer;
}

class TutorSpeechQuotePanel extends StatelessWidget {
  const TutorSpeechQuotePanel({
    super.key,
    required this.speechText,
    this.compact = false,
    this.isSpeaking = false,
    this.onReplay,
    this.onStop,
  });

  final String speechText;
  final bool compact;
  final bool isSpeaking;
  final VoidCallback? onReplay;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final isEmpty = speechText.trim().isEmpty;
    if (isEmpty) return const SizedBox.shrink();
    return Container(
      key: const Key('tutor-speech-quote-panel'),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        14,
        compact ? 12 : 14,
        8,
        compact ? 12 : 14,
      ),
      decoration: VisualTutorDecorations.speechPanel(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar icon ──────────────────────────────────────────────────
          Container(
            width: compact ? 30 : 34,
            height: compact ? 30 : 34,
            decoration: BoxDecoration(
              color: VisualTutorColors.cyan.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: VisualTutorColors.cyan,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          // ── Speech text ──────────────────────────────────────────────────
          Expanded(
            child: Text(
              '"$speechText"',
              key: const Key('tutor-speech-text'),
              maxLines: compact ? 3 : 4,
              overflow: TextOverflow.ellipsis,
              style: VisualTutorTypography.tutorSpeech.copyWith(
                color: VisualTutorColors.textSubtle,
                fontSize: compact ? 13 : 14,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // ── Voice replay / stop button ───────────────────────────────────
          Semantics(
            button: true,
            label: isSpeaking
                ? 'Stop tutor speech playback'
                : 'Replay tutor speech',
            child: IconButton(
              tooltip: isSpeaking ? 'Stop tutor speech' : 'Replay tutor speech',
              onPressed: isSpeaking ? onStop : onReplay,
              padding: const EdgeInsets.all(6),
              icon: Icon(
                isSpeaking
                    ? Icons.stop_circle_outlined
                    : Icons.volume_up_rounded,
                color: isSpeaking
                    ? VisualTutorColors.orange
                    : VisualTutorColors.cyan,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorLoadingControls extends StatelessWidget {
  const _TutorLoadingControls({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('tutor-loading-controls'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: VisualTutorColors.shellElevated.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(VisualTutorRadius.lg),
        border: Border.all(color: VisualTutorColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: VisualTutorColors.cyan,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Tutor is thinking and drawing...',
              style: TextStyle(
                color: VisualTutorColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          TextButton.icon(
            key: const Key('cancel-tutor-turn-button'),
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class TeachingCanvasBoard extends StatefulWidget {
  const TeachingCanvasBoard({
    super.key,
    this.variant,
    this.board,
    required this.actions,
    required this.finalAnswerLocked,
    this.compact = false,
    this.animate = true,
    this.reducedMotion = false,
    this.restored = false,
    this.actionInterval = const Duration(milliseconds: 260),
    this.useLogicalCanvasScale = false,
  });

  final String? variant;
  final VisualTutorBoardEntity? board;
  final List<VisualTutorBoardActionEntity> actions;
  final bool finalAnswerLocked;
  final bool compact;
  final bool animate;
  final bool reducedMotion;
  final bool restored;
  final Duration actionInterval;
  final bool useLogicalCanvasScale;

  @override
  State<TeachingCanvasBoard> createState() => _TeachingCanvasBoardState();
}

class _TeachingCanvasBoardState extends State<TeachingCanvasBoard>
    with SingleTickerProviderStateMixin {
  late AnimationController _strokeController;
  List<VisualTutorBoardActionEntity> _visibleActions = [];
  List<String> _playedActionIds = [];
  int _lastActionSignature = 0;
  int _generation = 0;
  final List<Timer> _pendingTimers = [];

  bool get _renderImmediately =>
      !widget.animate || widget.reducedMotion || widget.restored;

  @override
  void initState() {
    super.initState();
    _strokeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..value = 1;
    _syncActions(initial: true);
  }

  @override
  void didUpdateWidget(covariant TeachingCanvasBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSignature = _signatureFor(widget.actions);
    if (nextSignature != _lastActionSignature ||
        oldWidget.finalAnswerLocked != widget.finalAnswerLocked ||
        oldWidget.restored != widget.restored ||
        oldWidget.reducedMotion != widget.reducedMotion ||
        oldWidget.animate != widget.animate) {
      _syncActions();
    }
  }

  @override
  void dispose() {
    for (final timer in _pendingTimers) {
      timer.cancel();
    }
    _pendingTimers.clear();
    _strokeController.dispose();
    super.dispose();
  }

  int _signatureFor(List<VisualTutorBoardActionEntity> actions) {
    return Object.hashAll(
      actions.map(
        (action) => Object.hash(
          action.id,
          action.type,
          action.sequenceIndex,
          action.locked,
          action.hidden,
          action.text,
          action.latex,
        ),
      ),
    );
  }

  List<VisualTutorBoardActionEntity> _sortedRenderableActions() {
    final sortedActions = [...widget.actions]
      ..sort((a, b) => a.sequenceIndex.compareTo(b.sequenceIndex));
    return sortedActions
        .where(
          (action) =>
              !_isMarker(action) &&
              !(action.hidden || (action.locked && widget.finalAnswerLocked)),
        )
        .toList();
  }

  List<VisualTutorBoardActionEntity> _sortedPlayableActions() {
    final sortedActions = [...widget.actions]
      ..sort((a, b) => a.sequenceIndex.compareTo(b.sequenceIndex));
    return sortedActions
        .where(
          (action) =>
              _isMarker(action) ||
              !(action.hidden || (action.locked && widget.finalAnswerLocked)),
        )
        .toList();
  }

  bool _isMarker(VisualTutorBoardActionEntity action) {
    return action.type == 'pause_marker' || action.type == 'speak_marker';
  }

  void _syncActions({bool initial = false}) {
    _generation++;
    _lastActionSignature = _signatureFor(widget.actions);
    final sortedActions = _sortedRenderableActions();
    final sortedActionIds = sortedActions.map((action) => action.id).toSet();
    _visibleActions = _visibleActions
        .where((action) => sortedActionIds.contains(action.id))
        .toList();
    _playedActionIds = _playedActionIds
        .where((actionId) => sortedActionIds.contains(actionId))
        .toList();
    if (_renderImmediately || initial && widget.actions.isEmpty) {
      setState(() {
        _visibleActions = sortedActions;
        _playedActionIds = sortedActions.map((action) => action.id).toList();
      });
      return;
    }

    final newActions = _sortedPlayableActions()
        .where((action) => !_playedActionIds.contains(action.id))
        .toList();
    if (newActions.isEmpty) {
      setState(() => _visibleActions = sortedActions);
      return;
    }
    _playActions(newActions, _generation);
  }

  Future<void> _playActions(
    List<VisualTutorBoardActionEntity> actions,
    int generation,
  ) async {
    for (final action in actions) {
      if (!mounted || generation != _generation) return;
      if (action.type == 'pause_marker') {
        await _delay(
          Duration(milliseconds: action.durationMs.clamp(120, 1800).toInt()),
        );
        _playedActionIds = [..._playedActionIds, action.id];
        continue;
      }
      if (action.type == 'speak_marker') {
        _playedActionIds = [..._playedActionIds, action.id];
        continue;
      }
      setState(() {
        _visibleActions = [..._visibleActions, action];
        _playedActionIds = [..._playedActionIds, action.id];
      });
      if (_drawsProgressively(action)) {
        _strokeController
          ..duration = Duration(
            milliseconds: action.durationMs > 0 ? action.durationMs : 420,
          )
          ..forward(from: 0);
      }
      await _delay(widget.actionInterval);
    }
  }

  Future<void> _delay(Duration duration) {
    final completer = Completer<void>();
    late final Timer timer;
    timer = Timer(duration, () {
      _pendingTimers.remove(timer);
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    _pendingTimers.add(timer);
    return completer.future;
  }

  bool _drawsProgressively(VisualTutorBoardActionEntity action) {
    return action.type == 'draw_line' ||
        action.type == 'draw_arrow' ||
        action.type == 'circle' ||
        action.type == 'cross_out' ||
        action.type == 'write_text' ||
        action.type == 'write_equation';
  }

  @override
  Widget build(BuildContext context) {
    final variant = _variantFor(widget.board, widget.variant);
    if (_usesDedicatedVariant(variant)) {
      return Container(
        key: const Key('visual-tutor-canvas-board'),
        width: double.infinity,
        decoration: BoxDecoration(color: VisualTutorColors.boardPaper),
        clipBehavior: Clip.antiAlias,
        child: LiveTeachingBoard(
          board: widget.board,
          actions: _visibleActions,
          variant: variant,
          finalAnswerLocked: widget.finalAnswerLocked,
          compact: widget.compact,
        ),
      );
    }

    return Container(
      key: const Key('visual-tutor-canvas-board'),
      width: double.infinity,
      decoration: BoxDecoration(color: VisualTutorColors.boardPaper),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.clamp(320.0, 900.0);
          final scale = widget.useLogicalCanvasScale ? 1.0 : width / 390;
          return Container(
            width: double.infinity,
            decoration: VisualTutorDecorations.boardPaper(),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: 0,
                  top: 88,
                  bottom: 60,
                  child: Container(
                    width: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5B5A87),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                    ),
                  ),
                ),
                const Positioned.fill(child: _CanvasPaperLines()),
                Positioned(
                  right: widget.compact ? 12 : 18,
                  top: widget.compact ? 12 : 18,
                  child: _BoardStatusCluster(
                    locked: widget.finalAnswerLocked,
                    compact: widget.compact,
                  ),
                ),
                Positioned(
                  right: widget.compact ? 18 : 30,
                  top: widget.compact ? 96 : 126,
                  child: Icon(
                    Icons.flag_rounded,
                    color: VisualTutorColors.blackInk.withValues(alpha: .06),
                    size: widget.compact ? 72 : 110,
                  ),
                ),
                for (var i = 0; i < _visibleActions.length; i++)
                  _BoardActionRenderer(
                    action: _visibleActions[i],
                    scale: scale,
                    faded: i < _visibleActions.length - 1,
                    progress: i == _visibleActions.length - 1
                        ? _strokeController
                        : const AlwaysStoppedAnimation(1),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _variantFor(VisualTutorBoardEntity? board, String? explicitVariant) {
    final metadata = board?.metadata ?? const <String, dynamic>{};
    final normalizedExplicit = explicitVariant?.trim().toLowerCase();
    return ((normalizedExplicit != null &&
                normalizedExplicit != 'speaking_writing')
            ? normalizedExplicit
            : (metadata['screen_state'] ??
                  metadata['board_type'] ??
                  board?.type ??
                  'speaking_writing'))
        .toString()
        .trim()
        .toLowerCase();
  }

  bool _usesDedicatedVariant(String variant) {
    return variant == 'graph_based' ||
        variant == 'check_my_work' ||
        variant == 'final_verified_answer' ||
        variant == 'unsupported_problem';
  }
}

class _BoardStatusCluster extends StatelessWidget {
  const _BoardStatusCluster({required this.locked, required this.compact});

  final bool locked;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(VisualTutorRadius.pill),
        border: Border.all(color: VisualTutorColors.boardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 28 : 34,
            height: compact ? 28 : 34,
            decoration: const BoxDecoration(
              color: Color(0xFF1D63CE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: compact ? 16 : 19,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            locked ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
            color: locked
                ? VisualTutorColors.orange
                : VisualTutorColors.success,
            size: compact ? 17 : 20,
          ),
          if (!compact) ...[
            const SizedBox(width: 6),
            Text(
              locked ? 'guided mode' : 'answer ready',
              style: TextStyle(
                color: locked
                    ? VisualTutorColors.orange
                    : VisualTutorColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontFamilyFallback: VisualTutorTypography.fontFallback,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TutorApiErrorBanner extends StatelessWidget {
  const _TutorApiErrorBanner({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Tutor request needs attention. $message',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: VisualTutorDecorations.errorBanner(),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: VisualTutorColors.orange,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: VisualTutorColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamilyFallback: VisualTutorTypography.fontFallback,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'Retry the submitted tutor work',
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CanvasPaperLines extends StatelessWidget {
  const _CanvasPaperLines();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CanvasPaperPainter());
  }
}

class _CanvasPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = VisualTutorColors.boardPaperLine.withValues(alpha: .65)
      ..strokeWidth = 1;
    final dotPaint = Paint()
      ..color = VisualTutorColors.boardPaperDot.withValues(alpha: .45)
      ..strokeWidth = 1;

    for (double y = 42; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    for (double x = 24; x < size.width; x += 36) {
      for (double y = 22; y < size.height; y += 36) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BoardActionRenderer extends StatelessWidget {
  const _BoardActionRenderer({
    required this.action,
    required this.scale,
    required this.faded,
    required this.progress,
  });

  final VisualTutorBoardActionEntity action;
  final double scale;
  final bool faded;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final left = (action.x ?? 28) * scale;
    final top = action.y ?? 32;
    final width = (action.width ?? 260) * scale;
    final height = action.height ?? 42;
    final opacity = action.type == 'highlight' ? 1.0 : (faded ? .66 : 1.0);

    if (action.type == 'highlight') {
      return Positioned(
        key: const Key('teaching-board-highlight'),
        left: left,
        top: top,
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: VisualTutorColors.yellowHighlight.withValues(alpha: .38),
            borderRadius: BorderRadius.circular(VisualTutorRadius.md),
            border: Border.all(color: VisualTutorColors.orange, width: 1.4),
          ),
        ),
      );
    }

    if (action.type == 'draw_axes') {
      return Positioned.fill(
        child: CustomPaint(
          key: const Key('teaching-board-axes'),
          painter: _AxesActionPainter(scale: scale),
        ),
      );
    }

    if (action.type == 'draw_point') {
      return Positioned(
        key: Key('teaching-board-point-${action.id}'),
        left: left,
        top: top,
        width: width,
        height: height,
        child: _PointActionLabel(action: action),
      );
    }

    if (action.type == 'draw_line' ||
        action.type == 'draw_arrow' ||
        action.type == 'circle' ||
        action.type == 'cross_out') {
      return Positioned.fill(
        child: AnimatedBuilder(
          animation: progress,
          builder: (context, _) {
            return CustomPaint(
              key: Key('teaching-board-${action.type}-${action.id}'),
              painter: _ShapeActionPainter(
                action: action,
                scale: scale,
                progress: progress.value,
              ),
            );
          },
        ),
      );
    }

    if (action.type == 'show_table') {
      return Positioned(
        key: Key('teaching-board-table-${action.id}'),
        left: left,
        top: top,
        width: width,
        height: height,
        child: _TableActionView(action: action),
      );
    }

    if (action.type == 'create_blank') {
      return Positioned(
        key: Key('teaching-board-blank-${action.id}'),
        left: left,
        top: top,
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .68),
            borderRadius: BorderRadius.circular(VisualTutorRadius.sm),
            border: Border.all(color: VisualTutorColors.orange, width: 1.5),
          ),
        ),
      );
    }

    if (action.type == 'show_graph') {
      return Positioned(
        key: Key('teaching-board-graph-${action.id}'),
        left: left,
        top: top,
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .62),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: VisualTutorColors.blueInk),
          ),
          child: const CustomPaint(painter: _MiniGraphPainter()),
        ),
      );
    }

    final isEquation = action.type == 'write_equation';
    final ink = action.style['ink'] == 'blue'
        ? VisualTutorColors.blueInk
        : VisualTutorColors.blackInk;
    final fontSize =
        ((action.style['size'] as num?)?.toDouble() ?? (isEquation ? 26 : 19)) *
        scale.clamp(.86, 1.1);

    return Positioned(
      key: Key('teaching-board-action-${action.id}'),
      left: left,
      top: top,
      width: width,
      height: height,
      child: Opacity(
        opacity: opacity,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isEquation
                  ? Colors.transparent
                  : VisualTutorColors.yellowHighlight.withValues(alpha: .36),
              borderRadius: BorderRadius.circular(VisualTutorRadius.sm),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AnimatedBuilder(
                animation: progress,
                builder: (context, _) => Text(
                  _visibleTextFor(action, progress.value),
                  maxLines: 1,
                  style: TextStyle(
                    color: ink,
                    fontSize: fontSize,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    fontFamilyFallback: VisualTutorTypography.fontFallback,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _visibleTextFor(VisualTutorBoardActionEntity action, double progress) {
    final fullContent = action.latex ?? action.text ?? '';
    if (fullContent.isEmpty) return '';
    if (action.type != 'write_text' && action.type != 'write_equation') {
      return fullContent;
    }
    final visibleCharacters = (fullContent.length * progress)
        .ceil()
        .clamp(1, fullContent.length)
        .toInt();
    return fullContent.substring(0, visibleCharacters);
  }
}

class _PointActionLabel extends StatelessWidget {
  const _PointActionLabel({required this.action});

  final VisualTutorBoardActionEntity action;

  @override
  Widget build(BuildContext context) {
    final label =
        action.text ??
        action.metadata['label']?.toString() ??
        action.id.replaceAll('-', ' ');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: VisualTutorColors.blueInk,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: VisualTutorColors.blackInk,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _TableActionView extends StatelessWidget {
  const _TableActionView({required this.action});

  final VisualTutorBoardActionEntity action;

  @override
  Widget build(BuildContext context) {
    final rows = (action.metadata['rows'] as List?) ?? const [];
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBBF9E)),
      ),
      child: Column(
        children: [
          for (final row in rows.take(4))
            Expanded(
              child: Row(
                children: [
                  for (final cell in ((row as List?) ?? const []).take(3))
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFCBBF9E),
                            width: .6,
                          ),
                        ),
                        child: Text(
                          cell.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF15120B),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AxesActionPainter extends CustomPainter {
  const _AxesActionPainter({required this.scale});

  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width * .18, size.height * .72);
    final paint = Paint()
      ..color = const Color(0xFF15120B).withValues(alpha: .78)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * .08, origin.dy),
      Offset(size.width * .9, origin.dy),
      paint,
    );
    canvas.drawLine(
      Offset(origin.dx, size.height * .18),
      Offset(origin.dx, size.height * .86),
      paint,
    );
    _drawArrowHead(canvas, Offset(size.width * .9, origin.dy), 0, paint);
    _drawArrowHead(
      canvas,
      Offset(origin.dx, size.height * .18),
      -math.pi / 2,
      paint,
    );
  }

  void _drawArrowHead(Canvas canvas, Offset tip, double angle, Paint paint) {
    const length = 8.0;
    final left =
        tip -
        Offset(math.cos(angle - .55) * length, math.sin(angle - .55) * length);
    final right =
        tip -
        Offset(math.cos(angle + .55) * length, math.sin(angle + .55) * length);
    canvas.drawLine(tip, left, paint);
    canvas.drawLine(tip, right, paint);
  }

  @override
  bool shouldRepaint(covariant _AxesActionPainter oldDelegate) {
    return oldDelegate.scale != scale;
  }
}

class _ShapeActionPainter extends CustomPainter {
  const _ShapeActionPainter({
    required this.action,
    required this.scale,
    required this.progress,
  });

  final VisualTutorBoardActionEntity action;
  final double scale;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = action.type == 'cross_out'
          ? const Color(0xFFC62828)
          : const Color(0xFF15120B)
      ..strokeWidth = action.type == 'highlight' ? 8 : 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (action.type == 'circle') {
      final rect = Rect.fromLTWH(
        (action.x ?? 40) * scale,
        action.y ?? 40,
        (action.width ?? 90) * scale,
        action.height ?? 46,
      );
      final sweep = math.pi * 2 * progress.clamp(0, 1);
      canvas.drawArc(rect, 0, sweep, false, paint);
      return;
    }

    if (action.type == 'cross_out') {
      final rect = Rect.fromLTWH(
        (action.x ?? 40) * scale,
        action.y ?? 40,
        (action.width ?? 120) * scale,
        action.height ?? 44,
      );
      _drawProgressLine(canvas, rect.topLeft, rect.bottomRight, paint);
      _drawProgressLine(canvas, rect.bottomLeft, rect.topRight, paint);
      return;
    }

    final points = _pointsForAction(size);
    if (points.length < 2) return;
    _drawProgressLine(canvas, points.first, points.last, paint);
    if (action.type == 'draw_arrow') {
      _drawArrowHead(canvas, points.first, points.last, paint);
    }
  }

  List<Offset> _pointsForAction(Size size) {
    if (action.points.length >= 2) {
      return action.points.take(2).map((point) {
        final x = ((point['x'] as num?)?.toDouble() ?? 0) * scale;
        final y = (point['y'] as num?)?.toDouble() ?? 0;
        return Offset(x, y);
      }).toList();
    }
    final start = Offset((action.x ?? 40) * scale, action.y ?? 40);
    final end = Offset(
      ((action.x ?? 40) + (action.width ?? 120)) * scale,
      (action.y ?? 40) + (action.height ?? 0),
    );
    return [start, end];
  }

  void _drawProgressLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final clamped = progress.clamp(0, 1).toDouble();
    final current = Offset.lerp(start, end, clamped)!;
    canvas.drawLine(start, current, paint);
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end, Paint paint) {
    if (progress < .95) return;
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const length = 9.0;
    final left =
        end -
        Offset(math.cos(angle - .55) * length, math.sin(angle - .55) * length);
    final right =
        end -
        Offset(math.cos(angle + .55) * length, math.sin(angle + .55) * length);
    canvas.drawLine(end, left, paint);
    canvas.drawLine(end, right, paint);
  }

  @override
  bool shouldRepaint(covariant _ShapeActionPainter oldDelegate) {
    return oldDelegate.action != action ||
        oldDelegate.scale != scale ||
        oldDelegate.progress != progress;
  }
}

class _MiniGraphPainter extends CustomPainter {
  const _MiniGraphPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFB7C5DA).withValues(alpha: .5)
      ..strokeWidth = .7;
    final linePaint = Paint()
      ..color = const Color(0xFF1B5CCB)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (double x = 0; x <= size.width; x += size.width / 4) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += size.height / 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    canvas.drawLine(
      Offset(size.width * .12, size.height * .74),
      Offset(size.width * .84, size.height * .24),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VisualTutorStudentSubmission {
  const VisualTutorStudentSubmission({
    required this.message,
    required this.intent,
    required this.action,
    required this.inputType,
    this.clientTurnId,
    this.metadata = const {},
  });

  final String message;
  final String intent;
  final String action;
  final String inputType;
  final String? clientTurnId;
  final Map<String, dynamic> metadata;

  VisualTutorStudentSubmission copyWith({
    String? clientTurnId,
    Map<String, dynamic>? metadata,
  }) {
    return VisualTutorStudentSubmission(
      message: message,
      intent: intent,
      action: action,
      inputType: inputType,
      clientTurnId: clientTurnId ?? this.clientTurnId,
      metadata: metadata ?? this.metadata,
    );
  }
}

class StudentInteractionPanel extends StatefulWidget {
  const StudentInteractionPanel({
    super.key,
    required this.controller,
    required this.turn,
    required this.latestStudentMessage,
    required this.onSubmit,
    required this.onReset,
    this.compact = false,
    this.isListening = false,
    this.voiceStatus,
    this.onVoiceInput,
  });

  final TextEditingController controller;
  final VisualTutorTurnResponseEntity turn;
  final String? latestStudentMessage;
  final ValueChanged<VisualTutorStudentSubmission> onSubmit;
  final VoidCallback onReset;
  final bool compact;
  final bool isListening;
  final String? voiceStatus;
  final VoidCallback? onVoiceInput;

  @override
  State<StudentInteractionPanel> createState() =>
      _StudentInteractionPanelState();
}

class _StudentInteractionPanelState extends State<StudentInteractionPanel> {
  String? _answerLockNotice;

  VisualTutorInteractionEntity? get _interaction => widget.turn.interaction;

  bool get _isCheckWork {
    final metadata = widget.turn.board.metadata;
    final variant = (metadata['screen_state'] ?? metadata['board_type'])
        ?.toString()
        .toLowerCase();
    return variant == 'check_my_work';
  }

  bool get _isGraphBased {
    final metadata = widget.turn.board.metadata;
    final variant = (metadata['screen_state'] ?? metadata['board_type'])
        ?.toString()
        .toLowerCase();
    return variant == 'graph_based';
  }

  bool get _isFinalVerified {
    final metadata = widget.turn.board.metadata;
    final variant = (metadata['screen_state'] ?? metadata['board_type'])
        ?.toString()
        .toLowerCase();
    return variant == 'final_verified_answer';
  }

  bool get _isUnsupported {
    final metadata = widget.turn.board.metadata;
    final variant = (metadata['screen_state'] ?? metadata['board_type'])
        ?.toString()
        .toLowerCase();
    return variant == 'unsupported_problem';
  }

  bool get _inputEnabled {
    final stage = widget.turn.teachingStage?.stageState;
    final interactionEnabled = _interaction?.inputEnabled;
    if ((stage == 'analyzing' || stage == 'drawing') &&
        interactionEnabled != true) {
      return false;
    }
    return interactionEnabled ?? true;
  }

  bool _allows(String action) {
    final plannedActions = widget.turn.quickActions.isNotEmpty
        ? widget.turn.quickActions
        : widget.turn.allowedActions;
    final allowed = plannedActions.map(_normalizeAction).toSet();
    if (allowed.isEmpty) return false;
    return allowed.contains(_normalizeAction(action));
  }

  String _normalizeAction(String action) {
    final normalized = action
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    return switch (normalized) {
      'hint' => 'request_hint',
      'check_step' || 'submitted_step' || 'submit_step' => 'check_work',
      'show_answer' => 'request_answer',
      'request_final_answer' => 'request_answer',
      'show_visual_hint' => 'show_visually',
      'request_explain_differently' => 'explain_differently',
      _ => normalized,
    };
  }

  void _submitText({
    String? message,
    String intent = 'student_message',
    String action = 'student_message',
    String? inputType,
    Map<String, dynamic> metadata = const {},
  }) {
    final text = (message ?? widget.controller.text).trim();
    if (text.isEmpty || !_inputEnabled) return;
    final clientIntentHint = intent == 'student_message'
        ? _softClientIntentHintFor(text)
        : intent;
    setState(() => _answerLockNotice = null);
    widget.onSubmit(
      VisualTutorStudentSubmission(
        message: text,
        intent: clientIntentHint,
        action: action,
        inputType: inputType ?? _interaction?.type ?? 'text_response',
        metadata: metadata,
      ),
    );
  }

  String _softClientIntentHintFor(String text) {
    final normalized = text.trim().toLowerCase();
    if (normalized.contains('stuck') ||
        normalized.contains("don't understand") ||
        normalized.contains('do not understand') ||
        normalized.contains('help me') ||
        normalized.contains("can't solve") ||
        normalized.contains('confused') ||
        normalized.contains('មិនយល់') ||
        normalized.contains('ជួយខ្ញុំ')) {
      return 'stuck';
    }
    if (normalized.contains('show answer') ||
        normalized.contains('give me answer') ||
        normalized.contains('solve it')) {
      return 'request_answer';
    }
    if (normalized.contains('hint')) {
      return 'request_hint';
    }
    return 'student_message';
  }

  void _submitQuickAction(String action) {
    final normalized = _normalizeAction(action);

    final message = switch (normalized) {
      'request_hint' => 'Hint',
      'stuck' => "I'm stuck",
      'show_visually' => 'Show visually',
      'explain_differently' => 'Explain differently',
      'check_work' =>
        widget.controller.text.trim().isEmpty
            ? 'Check my step'
            : widget.controller.text.trim(),
      'request_answer' => 'Show answer',
      _ => action,
    };
    final intent = switch (normalized) {
      'request_hint' => 'request_hint',
      'stuck' => 'stuck',
      'show_visually' => 'request_explain_differently',
      'explain_differently' => 'request_explain_differently',
      'check_work' => 'check_work',
      'request_answer' => 'request_answer',
      _ => 'unknown',
    };
    _submitText(
      message: message,
      intent: intent,
      action: normalized == 'show_visually'
          ? 'explain_differently'
          : normalized,
      inputType: 'quick_action',
      metadata: normalized == 'show_visually'
          ? const {'mode': 'show_visually'}
          : const {},
    );
  }

  void _tryAgain() {
    setState(() {
      _answerLockNotice = 'Try that same step again. The board will stay here.';
    });
  }

  void _showMeWhy() {
    _submitText(
      message: 'Show me why',
      intent: 'request_explain_differently',
      action: 'explain_differently',
      inputType: 'quick_action',
      metadata: {'reason': 'check_work_show_me_why'},
    );
  }

  void _repeatProblem() {
    _submitText(
      message: 'Repeat',
      intent: 'request_explain_differently',
      action: 'explain_differently',
      inputType: 'quick_action',
      metadata: {'mode': 'repeat_final_solution'},
    );
  }

  void _showSummary() {
    setState(() {
      _answerLockNotice = 'Summary is shown on the board.';
    });
  }

  void _nextPracticeProblem() {
    _submitText(
      message: 'Next practice problem',
      intent: 'new_problem',
      action: 'submit_problem',
      inputType: 'quick_action',
      metadata: {'mode': 'next_practice'},
    );
  }

  void _backToHome() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _answerLockNotice = 'You are already on the tutor screen.';
    });
  }

  void _contactSupport() {
    setState(() {
      _answerLockNotice =
          'Support contact is not connected in this demo build yet.';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isUnsupported) {
      return _UnsupportedActionPanel(
        prompt:
            widget.turn.speech?.text ??
            (widget.turn.spokenText.isNotEmpty
                ? widget.turn.spokenText
                : "I'm still learning! I can help with Math, Physics, and Chemistry for now."),
        compact: widget.compact,
        notice: _answerLockNotice,
        onTryAnother: widget.onReset,
        onContactSupport: _contactSupport,
      );
    }
    if (_isFinalVerified) {
      return _FinalVerifiedActionPanel(
        prompt:
            widget.turn.speech?.text ??
            (widget.turn.spokenText.isNotEmpty
                ? widget.turn.spokenText
                : 'Excellent work! You’ve completed this problem. Ready for a similar one?'),
        compact: widget.compact,
        notice: _answerLockNotice,
        onRepeat: _inputEnabled ? _repeatProblem : null,
        onShowSummary: _inputEnabled ? _showSummary : null,
        onNextPractice: _inputEnabled ? _nextPracticeProblem : null,
        onBackHome: _backToHome,
        onVoice: _inputEnabled ? widget.onVoiceInput : null,
      );
    }

    return Container(
      key: const Key('student-interaction-panel'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_answerLockNotice != null) ...[
            Text(
              _answerLockNotice!,
              key: const Key('answer-locked-explanation'),
              style: const TextStyle(
                color: VisualTutorColors.orange,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
          if (_answerLockNotice != null) const SizedBox(height: 8),
          _quickActionStrip(),
          if (_isCheckWork) ...[
            SizedBox(height: widget.compact ? 10 : 14),
            _CheckWorkBottomActions(
              onTryAgain: _inputEnabled ? _tryAgain : null,
              onShowWhy: _inputEnabled ? _showMeWhy : null,
            ),
          ],
          if (!widget.compact) ...[
            const SizedBox(height: 10),
            _InteractionInput(
              controller: widget.controller,
              interaction: _interaction,
              inputEnabled: _inputEnabled,
              compact: widget.compact,
              onSubmitText: _submitText,
              onVoiceInput: widget.onVoiceInput,
              isListening: widget.isListening,
            ),
          ],
          if (widget.compact) ...[
            const SizedBox(height: 10),
            _InteractionInput(
              controller: widget.controller,
              interaction: _interaction,
              inputEnabled: _inputEnabled,
              compact: widget.compact,
              onSubmitText: _submitText,
              onVoiceInput: widget.onVoiceInput,
              isListening: widget.isListening,
            ),
          ],
          if (widget.voiceStatus != null &&
              widget.voiceStatus!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.voiceStatus!,
              key: const Key('tutor-voice-status'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: VisualTutorColors.cyan,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
          if (widget.latestStudentMessage != null) ...[
            SizedBox(height: widget.compact ? 7 : 10),
            Container(
              key: const Key('latest-student-message'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: VisualTutorDecorations.subtleStudentMessage(),
              child: Text(
                'You just said  ${widget.latestStudentMessage}',
                style: const TextStyle(
                  color: VisualTutorColors.textSubtle,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _quickActions() {
    return [
      if (_allows('request_hint'))
        _QuickActionButton(
          key: const Key('quick-action-hint'),
          icon: Icons.lightbulb_outline,
          label: 'Hint',
          onPressed: _inputEnabled
              ? () => _submitQuickAction('request_hint')
              : null,
        ),
      if (_allows('stuck'))
        _QuickActionButton(
          key: const Key('quick-action-stuck'),
          icon: Icons.support_agent,
          label: "I'm stuck",
          onPressed: _inputEnabled ? () => _submitQuickAction('stuck') : null,
        ),
      if (_allows('show_visually'))
        _QuickActionButton(
          key: const Key('quick-action-show-visually'),
          icon: Icons.visibility_outlined,
          label: 'Show Visually',
          onPressed: _inputEnabled
              ? () => _submitQuickAction('show_visually')
              : null,
        ),
      if (_allows('check_work'))
        _QuickActionButton(
          key: const Key('quick-action-check-step'),
          icon: Icons.fact_check_outlined,
          label: 'Check step',
          onPressed: _inputEnabled
              ? () => _submitQuickAction('check_work')
              : null,
        ),
      if (_allows('explain_differently'))
        _QuickActionButton(
          key: const Key('quick-action-explain-differently'),
          icon: Icons.swap_horiz_rounded,
          label: _isGraphBased ? 'Explain Different' : 'Explain differently',
          onPressed: _inputEnabled
              ? () => _submitQuickAction('explain_differently')
              : null,
        ),
      if (_allows('request_answer'))
        _QuickActionButton(
          key: const Key('quick-action-show-answer'),
          icon: widget.turn.finalAnswerLocked
              ? Icons.lock_outline_rounded
              : Icons.visibility_outlined,
          label: _isCheckWork
              ? 'Show Solution'
              : widget.turn.finalAnswerLocked
              ? 'Request answer'
              : 'Show answer',
          onPressed: _inputEnabled
              ? () => _submitQuickAction('request_answer')
              : null,
        ),
    ];
  }

  Widget _quickActionStrip() {
    final actions = _quickActions();
    if (actions.isEmpty) return const SizedBox.shrink();
    return ClipRect(
      child: SizedBox(
        height: 50,
        child: SingleChildScrollView(
          key: const Key('quick-action-horizontal-scroll'),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final action in actions)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: action,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckWorkBottomActions extends StatelessWidget {
  const _CheckWorkBottomActions({
    required this.onTryAgain,
    required this.onShowWhy,
  });

  final VoidCallback? onTryAgain;
  final VoidCallback? onShowWhy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            key: const Key('check-work-try-again'),
            onPressed: onTryAgain,
            icon: const Icon(Icons.replay_rounded, size: 17),
            label: const Text('Try again'),
            style: FilledButton.styleFrom(
              backgroundColor: VisualTutorColors.cyan,
              foregroundColor: VisualTutorColors.shell,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VisualTutorRadius.md),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamilyFallback: VisualTutorTypography.fontFallback,
              ),
            ).copyWith(
              elevation: WidgetStatePropertyAll(
                onTryAgain != null ? 6 : 0,
              ),
              shadowColor: WidgetStatePropertyAll(
                VisualTutorColors.cyan.withValues(alpha: .42),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            key: const Key('check-work-show-me-why'),
            onPressed: onShowWhy,
            icon: const Icon(Icons.help_outline_rounded, size: 17),
            label: const Text('Show me why'),
            style: FilledButton.styleFrom(
              backgroundColor: VisualTutorColors.panelRaised,
              foregroundColor: VisualTutorColors.text,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VisualTutorRadius.md),
                side: BorderSide(color: VisualTutorColors.border),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamilyFallback: VisualTutorTypography.fontFallback,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FinalVerifiedActionPanel extends StatelessWidget {
  const _FinalVerifiedActionPanel({
    required this.prompt,
    required this.compact,
    required this.notice,
    required this.onRepeat,
    required this.onShowSummary,
    required this.onNextPractice,
    required this.onBackHome,
    required this.onVoice,
  });

  final String prompt;
  final bool compact;
  final String? notice;
  final VoidCallback? onRepeat;
  final VoidCallback? onShowSummary;
  final VoidCallback? onNextPractice;
  final VoidCallback? onBackHome;
  final VoidCallback? onVoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('final-verified-action-panel'),
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: VisualTutorColors.panel,
        borderRadius: BorderRadius.circular(VisualTutorRadius.xl),
        border: Border.all(color: VisualTutorColors.border),
        boxShadow: VisualTutorShadows.cardRaise,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Tutor message row ───────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VisualTutorColors.cyan.withValues(alpha: .13),
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: VisualTutorColors.cyan,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  prompt,
                  key: const Key('final-verified-tutor-message'),
                  style: TextStyle(
                    color: VisualTutorColors.textSubtle,
                    fontSize: compact ? 13 : 14,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    fontFamilyFallback: VisualTutorTypography.fontFallback,
                  ),
                ),
              ),
            ],
          ),
          if (notice != null) ...[
            const SizedBox(height: 10),
            Text(
              notice!,
              key: const Key('final-verified-panel-notice'),
              style: const TextStyle(
                color: VisualTutorColors.cyan,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
          SizedBox(height: compact ? 14 : 16),
          // ── Repeat + Show Summary row ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _FinalPanelButton(
                  key: const Key('final-repeat-button'),
                  icon: Icons.repeat_rounded,
                  label: 'Repeat',
                  onPressed: onRepeat,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FinalPanelButton(
                  key: const Key('final-show-summary-button'),
                  icon: Icons.menu_book_rounded,
                  label: 'Show Summary',
                  onPressed: onShowSummary,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 12),
          // ── Next Practice Problem (primary CTA) ─────────────────────────────
          FilledButton(
            key: const Key('final-next-practice-button'),
            onPressed: onNextPractice,
            style: VisualTutorButtonStyles.primary(glow: true).copyWith(
              minimumSize: WidgetStatePropertyAll(
                Size.fromHeight(compact ? 50 : 56),
              ),
            ),
            child: const Text('Next Practice Problem  →'),
          ),
          const SizedBox(height: 8),
          // ── Back to Home (secondary) ─────────────────────────────────────────
          FilledButton(
            key: const Key('final-back-home-button'),
            onPressed: onBackHome,
            style: VisualTutorButtonStyles.darkCard().copyWith(
              minimumSize: WidgetStatePropertyAll(
                Size.fromHeight(compact ? 46 : 52),
              ),
            ),
            child: const Text('Back to Home'),
          ),
          SizedBox(height: compact ? 14 : 18),
          // ── Centered cyan mic FAB ───────────────────────────────────────────────
          Align(
            alignment: Alignment.center,
            child: Container(
              width: compact ? 58 : 66,
              height: compact ? 58 : 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: onVoice != null
                    ? VisualTutorShadows.cyanGlowStrong
                    : null,
              ),
              child: FilledButton(
                key: const Key('final-answer-mic-button'),
                onPressed: onVoice,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: onVoice != null
                      ? VisualTutorColors.cyan
                      : VisualTutorColors.panel,
                  foregroundColor: onVoice != null
                      ? VisualTutorColors.shell
                      : VisualTutorColors.textMuted,
                  disabledBackgroundColor: VisualTutorColors.panel,
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.mic_rounded, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnsupportedActionPanel extends StatelessWidget {
  const _UnsupportedActionPanel({
    required this.prompt,
    required this.compact,
    required this.notice,
    required this.onTryAnother,
    required this.onContactSupport,
  });

  final String prompt;
  final bool compact;
  final String? notice;
  final VoidCallback onTryAnother;
  final VoidCallback onContactSupport;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('unsupported-action-panel'),
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: VisualTutorColors.panelRaised,
        borderRadius: BorderRadius.circular(VisualTutorRadius.lg),
        border: Border.all(color: VisualTutorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VisualTutorColors.blueInk.withValues(alpha: .14),
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: VisualTutorColors.blueInk,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  prompt,
                  key: const Key('unsupported-tutor-message'),
                  style: TextStyle(
                    color: VisualTutorColors.textSubtle,
                    fontSize: compact ? 13 : 15,
                    height: 1.45,
                    fontWeight: FontWeight.w800,
                    fontFamilyFallback: VisualTutorTypography.fontFallback,
                  ),
                ),
              ),
            ],
          ),
          if (notice != null) ...[
            const SizedBox(height: 10),
            Text(
              notice!,
              key: const Key('unsupported-panel-notice'),
              style: const TextStyle(
                color: VisualTutorColors.orange,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
          SizedBox(height: compact ? 14 : 18),
          FilledButton(
            key: const Key('unsupported-try-another-button'),
            onPressed: onTryAnother,
            style: VisualTutorButtonStyles.primary().copyWith(
              minimumSize: WidgetStatePropertyAll(
                Size.fromHeight(compact ? 48 : 56),
              ),
            ),
            child: const Text('Try Another Problem'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('unsupported-contact-support-button'),
            onPressed: onContactSupport,
            icon: const Icon(Icons.headset_mic_rounded, size: 18),
            label: const Text('Contact Support'),
            style: VisualTutorButtonStyles.darkCard().copyWith(
              minimumSize: WidgetStatePropertyAll(
                Size.fromHeight(compact ? 46 : 54),
              ),
            ),
          ),
          SizedBox(height: compact ? 12 : 18),
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: compact ? 58 : 66,
              height: compact ? 58 : 66,
              child: FilledButton(
                key: const Key('unsupported-disabled-mic-button'),
                onPressed: null,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  disabledBackgroundColor: VisualTutorColors.textMuted
                      .withValues(alpha: .18),
                  disabledForegroundColor: VisualTutorColors.textMuted,
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.mic_rounded, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalPanelButton extends StatelessWidget {
  const _FinalPanelButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: VisualTutorButtonStyles.darkCard().copyWith(
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        ),
      ),
    );
  }
}

class _InteractionInput extends StatelessWidget {
  const _InteractionInput({
    required this.controller,
    required this.interaction,
    required this.inputEnabled,
    required this.compact,
    required this.onSubmitText,
    required this.onVoiceInput,
    required this.isListening,
  });

  final TextEditingController controller;
  final VisualTutorInteractionEntity? interaction;
  final bool inputEnabled;
  final bool compact;
  final void Function({
    String? message,
    String intent,
    String action,
    String? inputType,
    Map<String, dynamic> metadata,
  })
  onSubmitText;
  final VoidCallback? onVoiceInput;
  final bool isListening;

  @override
  Widget build(BuildContext context) {
    final type = interaction?.type ?? 'text_response';
    if (type == 'multiple_choice' && interaction != null) {
      return _ChoiceInput(
        interaction: interaction!,
        enabled: inputEnabled,
        compact: compact,
        onVoiceInput: onVoiceInput,
        isListening: isListening,
        onSelected: (choice) => onSubmitText(
          message: choice.value,
          intent: 'student_message',
          action: 'student_message',
          inputType: 'multiple_choice',
          metadata: {'choice_id': choice.id, 'label': choice.label},
        ),
      );
    }
    if (type == 'yes_no') {
      return _ButtonChoices(
        enabled: inputEnabled,
        choices: const ['Yes', 'No'],
        onSelected: (value) => onSubmitText(
          message: value,
          intent: 'student_message',
          action: 'student_message',
          inputType: 'yes_no',
        ),
      );
    }
    if (type == 'confidence') {
      return _ButtonChoices(
        enabled: inputEnabled,
        choices: const ['Low', 'Medium', 'High'],
        onSelected: (value) => onSubmitText(
          message: value,
          intent: 'confidence',
          action: 'student_message',
          inputType: 'confidence',
        ),
      );
    }
    // ── Pill-shaped text input + large cyan mic FAB ──────────────────────────
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            decoration: VisualTutorDecorations.interactionInputField(),
            child: TextField(
              key: const Key('tutor-message-field'),
              controller: controller,
              enabled: inputEnabled,
              keyboardType: type == 'numeric_input'
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSubmitText(
                intent: 'student_message',
                action: 'student_message',
                inputType: type,
              ),
              style: TextStyle(
                color: VisualTutorColors.text,
                fontSize: compact ? 14 : 15,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: type == 'numeric_input'
                    ? 'Type your number...'
                    : 'Ask a follow-up...',
                hintStyle: TextStyle(
                  color: VisualTutorColors.textMuted,
                  fontSize: compact ? 13 : 14,
                ),
                filled: false,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: compact ? 12 : 15,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                // Send icon inline inside field
                suffixIcon: inputEnabled
                    ? IconButton(
                        key: const Key('tutor-send-button'),
                        onPressed: () => onSubmitText(
                          intent: 'student_message',
                          action: 'student_message',
                          inputType: type,
                        ),
                        icon: const Icon(
                          Icons.send_rounded,
                          color: VisualTutorColors.cyan,
                          size: 20,
                        ),
                        tooltip: 'Submit your answer',
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // ── Cyan mic FAB ─────────────────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: compact ? 54 : 58,
          height: compact ? 54 : 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: (inputEnabled && isListening)
                ? VisualTutorShadows.cyanGlowStrong
                : inputEnabled
                    ? VisualTutorShadows.cyanGlow
                    : null,
          ),
          child: FilledButton(
            key: const Key('voice-response-button'),
            onPressed: inputEnabled ? onVoiceInput : null,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: inputEnabled
                  ? VisualTutorColors.cyan
                  : VisualTutorColors.panel,
              foregroundColor: inputEnabled
                  ? VisualTutorColors.shell
                  : VisualTutorColors.textMuted,
              disabledBackgroundColor:
                  VisualTutorColors.panel,
              shape: const CircleBorder(),
            ),
            child: Semantics(
              label: isListening
                  ? 'Stop recording your voice response'
                  : 'Record a voice response',
              child: Icon(
                isListening ? Icons.stop_rounded : Icons.mic_rounded,
                size: 26,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceInput extends StatelessWidget {
  const _ChoiceInput({
    required this.interaction,
    required this.enabled,
    required this.compact,
    required this.onVoiceInput,
    required this.isListening,
    required this.onSelected,
  });

  final VisualTutorInteractionEntity interaction;
  final bool enabled;
  final bool compact;
  final VoidCallback? onVoiceInput;
  final bool isListening;
  final ValueChanged<VisualTutorInteractionChoiceEntity> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 2×2 choice grid ─────────────────────────────────────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final (index, choice) in interaction.choices.indexed)
                  SizedBox(
                    width: cardWidth,
                    child: GestureDetector(
                      onTap: enabled ? () => onSelected(choice) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: EdgeInsets.all(compact ? 13 : 16),
                        decoration: VisualTutorDecorations.multiChoiceCard(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Option label row: "OPTION A" etc.
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: VisualTutorColors.cyan
                                        .withValues(alpha: .12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: VisualTutorColors.cyan
                                          .withValues(alpha: .35),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(
                                        65 + index,
                                      ), // A, B, C, D
                                      style: const TextStyle(
                                        color: VisualTutorColors.cyan,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Flexible(
                                  child: Text(
                                    'OPTION ${choice.label.toUpperCase()}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: VisualTutorTypography
                                        .multiChoiceLabel,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              choice.value,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  VisualTutorTypography.multiChoiceAnswer
                                      .copyWith(
                                        fontSize: compact ? 15 : 17,
                                        color: enabled
                                            ? VisualTutorColors.text
                                            : VisualTutorColors.textMuted,
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        SizedBox(height: compact ? 14 : 18),
        // ── Centered cyan mic FAB ────────────────────────────────────────────
        Align(
          alignment: Alignment.center,
          child: Container(
            width: compact ? 56 : 64,
            height: compact ? 56 : 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow:
                  enabled && isListening
                      ? VisualTutorShadows.cyanGlowStrong
                      : enabled
                          ? VisualTutorShadows.cyanGlow
                          : null,
            ),
            child: FilledButton(
              key: const Key('choice-voice-button'),
              onPressed: enabled ? onVoiceInput : null,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: enabled
                    ? VisualTutorColors.cyan
                    : VisualTutorColors.panel,
                foregroundColor: enabled
                    ? VisualTutorColors.shell
                    : VisualTutorColors.textMuted,
                disabledBackgroundColor: VisualTutorColors.panel,
                shape: const CircleBorder(),
              ),
              child: Icon(
                isListening ? Icons.stop_rounded : Icons.mic_rounded,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ButtonChoices extends StatelessWidget {
  const _ButtonChoices({
    required this.enabled,
    required this.choices,
    required this.onSelected,
  });

  final bool enabled;
  final List<String> choices;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final choice in choices)
          OutlinedButton(
            key: Key('choice-${choice.toLowerCase()}'),
            onPressed: enabled ? () => onSelected(choice) : null,
            child: Text(choice),
          ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return AnimatedOpacity(
      opacity: disabled ? 0.45 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: VisualTutorDecorations.quickActionChip(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: disabled
                    ? VisualTutorColors.textMuted
                    : VisualTutorColors.cyan,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: VisualTutorTypography.quickAction.copyWith(
                  color: disabled
                      ? VisualTutorColors.textMuted
                      : VisualTutorColors.text,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TutorWelcomeBubble extends StatelessWidget {
  const TutorWelcomeBubble({super.key, required this.studentName});

  final String studentName;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 326),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.answer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(2),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(color: AppColors.cyan.withValues(alpha: .22)),
            ),
            child: Text(
              'Hey $studentName, how can I help you today?',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 17,
                height: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Rean AI',
            style: TextStyle(
              color: AppColors.cyan,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class UserBubble extends StatelessWidget {
  const UserBubble({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 306,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: const BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(2),
              ),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You • 10:43 AM',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class TutorClassContextBanner extends StatelessWidget {
  const TutorClassContextBanner({super.key, required this.context});

  final LearningContext context;

  @override
  Widget build(BuildContext buildContext) {
    return Container(
      key: const Key('tutor-class-context-banner'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.answer.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cyan.withValues(alpha: .22)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _ContextChip(label: context.gradeLabel),
          _ContextChip(label: context.subject),
          _ContextChip(label: context.topic),
        ],
      ),
    );
  }
}

class _ContextChip extends StatelessWidget {
  const _ContextChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.cyan,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.step,
    required this.isFirst,
    required this.isLast,
    required this.onBack,
    required this.onNext,
    required this.onExplainAgain,
    required this.showExtraHelp,
  });

  final LessonStep step;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onExplainAgain;
  final bool showExtraHelp;

  @override
  Widget build(BuildContext context) {
    return TutorPanel(
      title: step.title,
      subtitle: step.progress,
      onExplainAgain: onExplainAgain,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EquationGraph(mode: step.graphMode),
          const SizedBox(height: 16),
          ExplanationBox(step: step),
          if (showExtraHelp) ...[
            const SizedBox(height: 12),
            const ExtraHelpBox(),
          ],
          const SizedBox(height: 20),
          TutorActionRow(
            backLabel: isFirst ? 'Back' : 'Back',
            nextLabel: isLast ? 'Finish' : 'Next Step',
            onBack: onBack,
            onNext: onNext,
          ),
        ],
      ),
    );
  }
}

class PracticeCard extends StatelessWidget {
  const PracticeCard({
    super.key,
    required this.onBack,
    required this.onExplainAgain,
    required this.showExtraHelp,
  });

  final VoidCallback onBack;
  final VoidCallback onExplainAgain;
  final bool showExtraHelp;

  @override
  Widget build(BuildContext context) {
    return TutorPanel(
      title: 'Practice: Your Turn',
      subtitle: 'Try the same idea with a new pair of points',
      onExplainAgain: onExplainAgain,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Find the equation of the line passing through P(1,2) and Q(3,6).',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 16,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          const PracticeIllustration(),
          const SizedBox(height: 18),
          const PracticeAnswerField(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cyan.withValues(alpha: .7)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.cyan, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Correct! The slope is 2 and the intercept is 0.',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontSize: 16,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showExtraHelp) ...[
            const SizedBox(height: 12),
            const ExtraHelpBox(),
          ],
          const SizedBox(height: 20),
          TutorActionRow(
            backLabel: 'Back',
            nextLabel: 'Next Challenge',
            onBack: onBack,
            onNext: onExplainAgain,
          ),
        ],
      ),
    );
  }
}

class TutorPanel extends StatelessWidget {
  const TutorPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onExplainAgain,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onExplainAgain;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.answer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cyan.withValues(alpha: .22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cyan.withValues(alpha: .14),
                    border: Border.all(
                      color: AppColors.cyan.withValues(alpha: .55),
                    ),
                  ),
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: AppColors.cyan,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.cyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Explain another way',
                  onPressed: onExplainAgain,
                  icon: const Icon(
                    Icons.help_outline_rounded,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            color: AppColors.answer.withValues(alpha: .7),
            child: child,
          ),
        ],
      ),
    );
  }
}

class EquationGraph extends StatelessWidget {
  const EquationGraph({super.key, required this.mode});

  final GraphMode mode;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.08,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF101422),
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomPaint(painter: EquationGraphPainter(mode)),
      ),
    );
  }
}

class ExplanationBox extends StatelessWidget {
  const ExplanationBox({super.key, required this.step});

  final LessonStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            step.prompt,
            style: const TextStyle(
              color: AppColors.subtle,
              fontSize: 16,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            step.work,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 19,
              height: 1.55,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            step.takeaway,
            style: const TextStyle(
              color: AppColors.cyan,
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class ExtraHelpBox extends StatelessWidget {
  const ExtraHelpBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2144),
        borderRadius: BorderRadius.circular(10),
        border: const Border(left: BorderSide(color: AppColors.cyan, width: 4)),
      ),
      child: const Text(
        'Think of the line like stairs: slope tells how high each step rises, and the intercept tells where the stairs start on the y-axis.',
        style: TextStyle(color: AppColors.subtle, height: 1.45),
      ),
    );
  }
}

class TutorActionRow extends StatelessWidget {
  const TutorActionRow({
    super.key,
    required this.backLabel,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
  });

  final String backLabel;
  final String nextLabel;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              fixedSize: const Size.fromHeight(54),
              foregroundColor: AppColors.blue,
              side: const BorderSide(color: AppColors.blue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              backLabel,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              fixedSize: const Size.fromHeight(54),
              backgroundColor: AppColors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              nextLabel,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}

class PracticeIllustration extends StatelessWidget {
  const PracticeIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.68,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF101422),
          borderRadius: BorderRadius.circular(14),
        ),
        child: CustomPaint(painter: PracticeIllustrationPainter()),
      ),
    );
  }
}

class PracticeAnswerField extends StatelessWidget {
  const PracticeAnswerField({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111523),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cyan, width: 2),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              'y = 2x',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Icon(Icons.sentiment_satisfied_alt, color: AppColors.muted),
        ],
      ),
    );
  }
}

class ChatInput extends StatelessWidget {
  const ChatInput({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: .05)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.attach_file_rounded,
              color: AppColors.muted,
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                key: const Key('tutor-message-field'),
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmit(),
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ask Rean any question!',
                  hintStyle: TextStyle(color: Color(0xFF777C91), fontSize: 16),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
            const Icon(
              Icons.mic_none_rounded,
              color: AppColors.muted,
              size: 20,
            ),
            const SizedBox(width: 10),
            SizedBox.square(
              dimension: 40,
              child: FilledButton(
                key: const Key('tutor-send-button'),
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: AppColors.blue,
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.send_rounded, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LessonStep {
  const LessonStep({
    required this.title,
    required this.progress,
    required this.graphMode,
    required this.prompt,
    required this.work,
    required this.takeaway,
  });

  final String title;
  final String progress;
  final GraphMode graphMode;
  final String prompt;
  final String work;
  final String takeaway;
}

enum GraphMode { slope, intercept, finalEquation }

class EquationGraphPainter extends CustomPainter {
  const EquationGraphPainter(this.mode);

  final GraphMode mode;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1.4;
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: .045)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = AppColors.cyan
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final guidePaint = Paint()
      ..color = AppColors.muted.withValues(alpha: .55)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    final pointPaint = Paint()..color = AppColors.blue;

    const xMin = -1.0;
    const xMax = 3.0;
    const yMin = -1.0;
    const yMax = 5.0;
    final unit = math.min(
      size.width * .84 / (xMax - xMin),
      size.height * .8 / (yMax - yMin),
    );
    final planeWidth = (xMax - xMin) * unit;
    final planeHeight = (yMax - yMin) * unit;
    final left = (size.width - planeWidth) / 2;
    final top = (size.height - planeHeight) / 2;
    final right = left + planeWidth;
    final bottom = top + planeHeight;

    Offset map(double x, double y) {
      return Offset(left + (x - xMin) * unit, top + (yMax - y) * unit);
    }

    for (var x = xMin; x <= xMax; x += 1) {
      final point = map(x, yMin);
      canvas.drawLine(
        Offset(point.dx, top),
        Offset(point.dx, bottom),
        gridPaint,
      );
    }
    for (var y = yMin; y <= yMax; y += 1) {
      final point = map(xMin, y);
      canvas.drawLine(
        Offset(left, point.dy),
        Offset(right, point.dy),
        gridPaint,
      );
    }

    canvas.drawLine(map(-1, 0), map(3, 0), axisPaint);
    canvas.drawLine(map(0, -1), map(0, 5), axisPaint);
    canvas.drawLine(map(-1, -1), map(2, 5), linePaint);

    final d = map(0, 1);
    final e = map(1, 3);
    canvas.drawCircle(d, 5, pointPaint);
    canvas.drawCircle(e, 5, pointPaint);

    if (mode == GraphMode.slope) {
      canvas.drawLine(d, Offset(e.dx, d.dy), guidePaint);
      canvas.drawLine(Offset(e.dx, d.dy), e, guidePaint);
      _label(canvas, 'D(0,1)', d + const Offset(8, -16));
      _label(canvas, 'E(1,3)', e + const Offset(8, -16));
    } else if (mode == GraphMode.intercept) {
      _label(canvas, 'D(0,1)', d + const Offset(-18, 12));
      _label(canvas, 'E(1,3)', e + const Offset(8, 0));
    } else {
      final labelOrigin = map(1.5, 3.2);
      final labelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(labelOrigin.dx, labelOrigin.dy, 82, 38),
        const Radius.circular(6),
      );
      canvas.drawRRect(labelRect, Paint()..color = AppColors.card);
      _label(
        canvas,
        'y = 2x + 1',
        labelOrigin + const Offset(9, 12),
        cyan: true,
      );
      _label(canvas, 'D(0,1)', d + const Offset(-18, 12));
      _label(canvas, 'E(1,3)', e + const Offset(-10, 18));
    }
  }

  void _label(Canvas canvas, String text, Offset offset, {bool cyan = false}) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: cyan ? AppColors.cyan : AppColors.text,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant EquationGraphPainter oldDelegate) {
    return oldDelegate.mode != mode;
  }
}

class PracticeIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bookPaint = Paint()..color = const Color(0xFFFFC928);
    final coverPaint = Paint()..color = const Color(0xFFFF4D5A);
    final accentPaint = Paint()..color = const Color(0xFFE80E67);
    final pencilPaint = Paint()..color = const Color(0xFF2D69E8);
    final circlePaint = Paint()..color = const Color(0xFFFF8A00);

    canvas.drawCircle(
      Offset(size.width * .78, size.height * .48),
      size.height * .42,
      coverPaint,
    );
    canvas.drawCircle(
      Offset(size.width * .18, size.height * .48),
      size.height * .43,
      accentPaint,
    );
    canvas.save();
    canvas.translate(size.width * .16, size.height * .12);
    canvas.rotate(.2);
    final book = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width * .5, size.height * .7),
      const Radius.circular(6),
    );
    canvas.drawRRect(book, bookPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .32, 0, size.width * .18, size.height * .7),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white,
    );
    _drawText(
      canvas,
      'MATH',
      Offset(size.width * .22, size.height * .12),
      Colors.white,
      20,
    );
    canvas.restore();

    canvas.drawLine(
      Offset(size.width * .4, size.height * .64),
      Offset(size.width * .9, size.height * .72),
      pencilPaint..strokeWidth = 14,
    );
    canvas.drawCircle(
      Offset(size.width * .73, size.height * .72),
      22,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * .73, size.height * .72),
      10,
      bookPaint,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double size,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
