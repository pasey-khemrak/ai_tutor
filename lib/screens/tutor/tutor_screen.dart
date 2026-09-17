// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_service.dart';
import '../../core/config/app_config.dart';
import '../../core/localization/app_language_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/responsive/app_breakpoints.dart';
import '../../shared/language_switcher_button.dart';
import '../../features/visual_tutor/data/datasources/visual_tutor_remote_data_source.dart';
import '../../features/visual_tutor/data/client_telemetry.dart';
import '../../features/visual_tutor/data/voice_tutor_repository.dart';
import '../../features/visual_tutor/local_mvp_limits_session.dart';
import '../../features/visual_tutor/data/repositories/visual_tutor_repository_impl.dart';
import '../../features/quizzes/quiz_repository.dart';
import '../../features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import '../../features/visual_tutor/presentation/live_board_state.dart';
import '../../features/visual_tutor/presentation/board_pagination.dart';
import '../../features/visual_tutor/presentation/widgets/board_page_switcher.dart';
import '../../features/visual_tutor/presentation/semantic_board_layout.dart';
import '../../features/visual_tutor/presentation/visual_tutor_board_snapshot.dart';
import '../../features/visual_tutor/domain/repositories/visual_tutor_repository.dart';
import '../../features/visual_tutor/presentation/visual_tutor_design.dart';
import '../../features/visual_tutor/presentation/widgets/live_teaching_board.dart';
import '../../features/visual_tutor/presentation/visual_tutor_voice.dart';
import '../../features/visual_tutor/presentation/visual_tutor_recorder.dart';
import '../../shared/rean_avatar.dart';
import '../learning_selection/learning_selection_repository.dart';
import '../lessons/local_mvp_limits_scope.dart';
import '../profile/student_profile_repository.dart';
import '../onboarding/first_run_explainer_sheet.dart';
import 'tutor_stream_coordinator.dart';

class TutorScreen extends StatefulWidget {
  const TutorScreen({
    super.key,
    this.context,
    this.repository,
    this.initialSessionId,
    this.initialSubmission,
    this.userId = '',
    this.voiceMode = false,
    this.onOpenTargetedPractice,
  });

  final LearningContext? context;
  final VisualTutorRepository? repository;
  final String? initialSessionId;
  final VisualTutorStudentSubmission? initialSubmission;
  final String userId;

  /// Selects the microphone-first dock. It does not create a different lesson.
  final bool voiceMode;
  final ValueChanged<TargetedPracticeContext>? onOpenTargetedPractice;

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
  late final VisualTutorClientTelemetry _clientTelemetry;
  VisualTutorTurnResponseEntity _currentTurn = _initialGreetingTurn;
  VisualTutorSessionEntity? _session;
  LocalMvpLimitsSession? _localLimitsSession;
  VisualTutorTurnStateEntity _turnState = const VisualTutorTurnStateEntity();
  List<VisualTutorBoardActionEntity> _renderedBoardActions = const [];
  int _boardIdentitySerial = 0;
  int _boardVersion = 0;
  int _baseBoardVersion = 0;
  String _boardStateId = 'local-greeting';
  bool _boardRestored = false;
  VisualTutorBoardSnapshot? _boardSnapshot;
  Timer? _boardSnapshotWriteTimer;
  final List<_TutorHistoryMessage> _history = [
    const _TutorHistoryMessage(
      role: 'Tutor',
      text: 'What lesson or problem do you want to explore today?',
    ),
  ];
  bool _isLoading = false;
  bool _isSpeaking = false;
  Timer? _speechDelayTimer;
  String? _pendingSpeechText;
  String? _pendingSpeechActionId;
  int? _pendingSpeechTurnSerial;
  DateTime? _manualBoardScrollUntil;
  final GlobalKey _teachingCanvasKey = GlobalKey();
  bool _isListening = false;
  bool _isTranscribingVoice = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  final TutorStreamCoordinator _streamCoordinator = TutorStreamCoordinator();
  String? _apiError;
  String? _voiceStatus;
  final List<BoardActionDiagnostic> _boardActionDiagnostics = [];
  VisualTutorStudentSubmission? _lastFailedSubmission;
  String? _latestStudentMessage;
  bool _keyboardMode = false;
  bool _tutorMuted = false;
  bool _showHistoryPanel = false;
  bool _stepPanelExpanded = false;
  StudentProfileView? _studentProfile;
  late final Future<void> _profileLoadFuture;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? _buildDefaultRepository();
    // A free-form "ask anything" question carries no lesson context (it isn't
    // a published lesson), so it's the only source of grade/subject for the
    // scope-locked dynamic tutor -- without it every such question is
    // rejected as out of scope regardless of the student's saved profile.
    // Every submission path awaits this before building request metadata, so
    // a fast first submission can't race ahead of the fetch.
    _profileLoadFuture = _loadStudentProfileForFallbackContext();
    _clientTelemetry = VisualTutorClientTelemetry(
      ApiClient(
        config: AppConfig.current,
        tokenProvider: appAuthService.getAccessToken,
      ),
    );
    if (_isLocalCurriculumDemo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_handleStudentSubmission(
          widget.initialSubmission ?? const VisualTutorStudentSubmission(
            message: 'Start local curriculum demo.',
            intent: 'new_problem', action: 'submit_problem', inputType: 'quick_action',
          ),
        ));
      });
      return;
    }
    if (widget.initialSessionId != null &&
        widget.initialSessionId!.isNotEmpty) {
      unawaited(_createOrRestoreSession());
    }
    final initialSubmission = widget.initialSubmission;
    if (initialSubmission != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (initialSubmission.action == 'start_voice' &&
              initialSubmission.message.trim().isEmpty) {
            _toggleListening();
          } else {
            unawaited(_handleStudentSubmission(initialSubmission));
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _speechDelayTimer?.cancel();
    _boardSnapshotWriteTimer?.cancel();
    _streamCoordinator.invalidate();
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

  Future<void> _loadStudentProfileForFallbackContext() async {
    try {
      final profile = await StudentProfileRepository().loadProfile();
      if (mounted && profile.isComplete) {
        setState(() => _studentProfile = profile);
      }
    } catch (_) {
      // No saved profile yet (or it failed to load) -- ask_question requests
      // simply stay unscoped, same as before this fallback existed.
    }
  }

  /// Parses the numeric grade out of a `grade-<N>` catalog id, e.g. "grade-12"
  /// -> 12. Matches the id scheme used throughout the catalog/profile system.
  int? get _profileGradeNumber {
    final gradeLevelId = _studentProfile?.gradeLevelId;
    if (gradeLevelId == null || gradeLevelId.isEmpty) return null;
    final match = RegExp(r'(\d+)$').firstMatch(gradeLevelId);
    return match == null ? null : int.tryParse(match.group(1)!);
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

  bool get _hasCurriculumContext => widget.context?.isCurriculumScoped ?? false;

  String get _requestSubject => _hasCurriculumContext
      ? widget.context!.subject
      : 'General';

  String? get _requestTopic => _hasCurriculumContext
      ? widget.context!.topic
      : null;

  String get _requestLanguageMode {
    final explicit = widget.context?.languageMode;
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return AppLanguageController.isKhmer ? 'khmer' : 'english';
  }

  bool get _isLocalCurriculumDemo => isLocalMvpLimitsScope(
    grade: widget.context?.grade ?? 0,
    subject: widget.context?.subject ?? '',
    topic: widget.context?.topic ?? '',
    lessonId: widget.context?.lessonId ?? '',
    curriculumVersionId: widget.context?.curriculumVersionId ?? '',
    teachingMomentId: widget.context?.teachingMomentId,
  );

  String? get _boardSnapshotKey {
    final sessionId = _session?.sessionId;
    if (sessionId == null || sessionId.isEmpty || _boardStateId.isEmpty) {
      return null;
    }
    return 'visual_tutor_board_snapshot_v2/$sessionId/$_boardStateId';
  }

  Future<void> _loadBoardSnapshot() async {
    if (_isLocalCurriculumDemo) return;
    final key = _boardSnapshotKey;
    if (key == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final serialized = prefs.getString(key);
      if (serialized == null) return;
      final snapshot = VisualTutorBoardSnapshot.tryFromJson(
        jsonDecode(serialized),
      );
      if (snapshot == null ||
          snapshot.sessionId != _session?.sessionId ||
          snapshot.boardStateId != _boardStateId) {
        // Invalid device data must never block the tutor. Remove it so every
        // later restore uses the server-authoritative board.
        await prefs.remove(key);
        return;
      }
      if (mounted) {
        setState(() {
          _boardSnapshot = snapshot;
          // A privacy-projected session can legitimately omit replay actions.
          // The device snapshot is then a validated, local fallback only; a
          // current server turn always wins when actions are available.
          if (_renderedBoardActions.isEmpty) {
            _adoptBoardActions(snapshot.actions);
            _boardRestored = true;
          }
        });
      }
    } catch (_) {
      // SharedPreferences can fail or old data may be malformed. The board is
      // still usable because snapshots are presentation-only.
    }
  }

  void _saveBoardSnapshot(VisualTutorBoardSnapshot snapshot) {
    if (_isLocalCurriculumDemo) return;
    if (snapshot.sessionId != _session?.sessionId ||
        snapshot.boardStateId != _boardStateId)
      return;
    final key = _boardSnapshotKey;
    if (key == null) return;
    _boardSnapshotWriteTimer?.cancel();
    _boardSnapshotWriteTimer = Timer(
      const Duration(milliseconds: 300),
      () async {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(key, jsonEncode(snapshot.toJson()));
        } catch (_) {
          // Device persistence is best effort; do not turn an ink-save failure
          // into a lesson failure.
        }
      },
    );
  }

  Future<void> _createOrRestoreSession() async {
    if (_isLocalCurriculumDemo) {
      _localLimitsSession = await LocalMvpLimitsSession.open(userId: widget.userId);
      if (mounted) _applyLocalLimitsTurn(_localLimitsSession!.currentTurn, restored: true);
      return;
    }
    try {
      String? existingSessionId = widget.initialSessionId;
      SharedPreferences? prefs;
      VisualTutorSessionEntity? session;

      // An explicit session is supplied by the resume route. Restore it before
      // consulting device storage so a storage delay or failure cannot turn a
      // resume into a new lesson session.
      if (existingSessionId != null && existingSessionId.isNotEmpty) {
        try {
          session = await _repository.restoreSession(existingSessionId);
        } catch (_) {
          // Continue to the stored-session fallback or a new session below.
        }
      }

      try {
        prefs = await SharedPreferences.getInstance();
        if (session == null &&
            (existingSessionId == null || existingSessionId.isEmpty)) {
          existingSessionId = prefs.getString('active_tutor_session_id');
        }
      } catch (_) {
        // A caller-provided session ID is authoritative and must still be
        // restored if device preferences are unavailable (including widget
        // tests and privacy-restricted web storage).
      }

      if (session == null &&
          existingSessionId != null &&
          existingSessionId.isNotEmpty) {
        try {
          session = await _repository.restoreSession(existingSessionId);
        } catch (_) {
          await prefs?.remove('active_tutor_session_id');
        }
      }

      session ??= await _repository.createSession(
        VisualTutorSessionCreateRequestEntity(
          userId: widget.userId,
          subject: _requestSubject,
          sessionMode: 'draft',
          topic: _requestTopic,
          metadata: _contextMetadata(),
        ),
      );

      final currentSession = session;
      await prefs?.setString('active_tutor_session_id', currentSession.sessionId);
      if (!mounted) return;
      setState(() {
        _session = currentSession;
        _turnState = VisualTutorTurnStateEntity(
          problemInstanceId: _stringFromMap(
            _mapFromObject(
              currentSession.metadata['authoritative_lesson_state'],
            ),
            'problem_instance_id',
          ),
          lessonId: _stringFromMap(
            _mapFromObject(
              currentSession.metadata['authoritative_lesson_state'],
            ),
            'lesson_id',
          ),
          activeStepId: _stringFromMap(
            _mapFromObject(
              currentSession.metadata['authoritative_lesson_state'],
            ),
            'active_step_id',
          ),
          expectedStudentActionId: _stringFromMap(
            _mapFromObject(
              currentSession.metadata['authoritative_lesson_state'],
            ),
            'expected_student_action_id',
          ),
          problemText: currentSession.problemText,
          normalizedProblem: currentSession.normalizedProblem,
          currentStepIndex: currentSession.currentStepIndex,
          hintCount: currentSession.hintCount,
          wrongAttempts: currentSession.wrongAttempts,
          finalAnswerRevealed: currentSession.finalAnswerRevealed,
        );
        _boardVersion =
            _intFromMap(currentSession.metadata, 'board_version') ?? 0;
        _baseBoardVersion =
            _intFromMap(currentSession.metadata, 'base_board_version') ?? 0;
        _adoptBoardActions(_actionsFromSession(currentSession));
        _boardStateId = 'board-v$_boardVersion';
        _boardRestored = _renderedBoardActions.isNotEmpty;
      });
      unawaited(_loadBoardSnapshot());
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
    if (!_hasCurriculumContext) await _profileLoadFuture;
    final clientTurnId = submission.clientTurnId ?? _newClientTurnId();
    final effectiveSubmission = submission.copyWith(clientTurnId: clientTurnId);
    final requestBoardVersion = _boardVersion;
    _invalidateActiveStream();
    final turnSerial = _streamCoordinator.activeSerial;
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
      if (_isLocalCurriculumDemo) {
        await _handleLocalLimitsSubmission(effectiveSubmission, turnSerial);
        return;
      }
      final session = _session ?? await _repository.createSession(
        VisualTutorSessionCreateRequestEntity(
          userId: widget.userId, subject: _requestSubject,
          sessionMode: _isExplicitTutorAction(effectiveSubmission)
              ? 'draft' : 'confirmed_problem',
          topic: _requestTopic,
          problemText: _isExplicitTutorAction(effectiveSubmission) ? null : message,
          metadata: _contextMetadata(),
        ),
      );
      activeSessionId = session.sessionId;
      final turnRequest = VisualTutorTurnRequestEntity(
        userId: widget.userId,
        sessionId: session.sessionId,
        subject: _requestSubject,
        // A free-form question must not inherit the topic of a restored or
        // previously created session. Only an explicitly selected lesson can
        // supply curriculum topic scope for this turn.
        topic: _requestTopic,
        languageMode: _requestLanguageMode,
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
      );
      final response = await _sendTurnWithStreaming(
        turnRequest,
        turnSerial: turnSerial,
        requestBoardVersion: requestBoardVersion,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw const ApiException(
          message:
              'The tutor is taking longer than expected. Tap retry to continue.',
          statusCode: 408,
        ),
      );
      if (!mounted) return;
      if (!_streamCoordinator.isCurrent(turnSerial)) return;
      final responseLessonState = _mapFromObject(
        response.metadata['authoritative_lesson_state'],
      );
      final responseProblemId = _stringFromMap(
        responseLessonState,
        'problem_instance_id',
      );
      if (_backendActionFor(effectiveSubmission) != 'submit_problem' &&
          _turnState.problemInstanceId != null &&
          responseProblemId != null &&
          responseProblemId != _turnState.problemInstanceId) {
        await _refreshSessionAfterBoardConflict(
          turnSerial,
          sessionId: session.sessionId,
        );
        if (!mounted || !_streamCoordinator.isCurrent(turnSerial)) return;
        setState(() {
          _apiError =
              'Your tutor board was refreshed because the lesson step changed. Tap retry to send your answer again.';
          _lastFailedSubmission = effectiveSubmission;
        });
        return;
      }
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
        if (!mounted || !_streamCoordinator.isCurrent(turnSerial)) return;
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
        if (!mounted || !_streamCoordinator.isCurrent(turnSerial)) return;
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
      final previousActionIds = _renderedBoardActions
          .map((action) => action.id)
          .toSet();
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
        _adoptBoardActions(nextBoardActions);
        _boardStateId = 'board-v$_boardVersion';
        _boardRestored = false;
        _boardSnapshot = null;
        _history.add(
          _TutorHistoryMessage(
            role: 'Tutor',
            text: response.speech?.text ?? response.spokenText,
          ),
        );
      });
      unawaited(_loadBoardSnapshot());
      _scrollBoardToNewTeachingBlock(
        nextBoardActions,
        previousActionIds: previousActionIds,
        response: response,
      );
      unawaited(_speakTutorTurn(response, turnSerial: turnSerial));
      unawaited(_recordProgressSafely(response));
    } catch (error) {
      if (!mounted) return;
      if (!_streamCoordinator.isCurrent(turnSerial)) return;
      final recoveredConflict =
          _isBoardVersionConflict(error) &&
          await _refreshSessionAfterBoardConflict(
            turnSerial,
            sessionId: activeSessionId,
          );
      if (!mounted || !_streamCoordinator.isCurrent(turnSerial)) return;
      setState(() {
        _apiError = recoveredConflict
            ? 'Your tutor board was refreshed because another update arrived. Tap retry to send your answer again.'
            : _friendlyError(error);
        _lastFailedSubmission = effectiveSubmission;
      });
    } finally {
      if (mounted && _streamCoordinator.isCurrent(turnSerial)) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isBoardVersionConflict(Object error) {
    return error is ApiException && error.statusCode == 409;
  }

  Future<void> _handleLocalLimitsSubmission(
    VisualTutorStudentSubmission submission, int turnSerial,
  ) async {
    final local = _localLimitsSession ??=
        await LocalMvpLimitsSession.open(userId: widget.userId);
    if (!mounted || !_streamCoordinator.isCurrent(turnSerial)) return;
    final opening = _backendActionFor(submission) == 'submit_problem';
    VisualTutorTurnResponseEntity response;
    try {
      response = opening ? local.currentTurn : await local.turn(
        VisualTutorTurnRequestEntity(
          userId: widget.userId, sessionId: local.session.sessionId,
          subject: _requestSubject, topic: _requestTopic,
          message: submission.message, action: _backendActionFor(submission),
          idempotencyKey: submission.clientTurnId,
          metadata: {'client_board_version': _boardVersion},
        ),
      );
    } on LocalLimitsSessionException catch (error) {
      if (error.code != 'stale_board_version') rethrow;
      _localLimitsSession = await LocalMvpLimitsSession.open(userId: widget.userId);
      if (!mounted || !_streamCoordinator.isCurrent(turnSerial)) return;
      _applyLocalLimitsTurn(_localLimitsSession!.currentTurn, restored: true);
      setState(() {
        _apiError = 'The lesson was restored. Tap retry to send your answer again.';
        _lastFailedSubmission = submission;
      });
      return;
    }
    if (!mounted || !_streamCoordinator.isCurrent(turnSerial)) return;
    final previousIds = _renderedBoardActions.map((action) => action.id).toSet();
    _applyLocalLimitsTurn(response, restored: opening &&
        (response.metadata['board_version'] as int) > 1);
    _scrollBoardToNewTeachingBlock(_renderedBoardActions,
        previousActionIds: previousIds, response: response);
  }

  void _applyLocalLimitsTurn(VisualTutorTurnResponseEntity response, {
    required bool restored,
  }) {
    setState(() {
      _session = _localLimitsSession!.session;
      _currentTurn = response;
      _turnState = _stateFromResponse(response);
      _boardVersion = response.metadata['board_version'] as int;
      _baseBoardVersion = response.metadata['base_board_version'] as int;
      _boardStateId = 'local-limits-board-v$_boardVersion';
      _adoptBoardActions(response.boardActions);
      _boardRestored = restored;
      _boardSnapshot = null;
    });
  }

  Future<VisualTutorTurnResponseEntity> _sendTurnWithStreaming(
    VisualTutorTurnRequestEntity request, {
    required int turnSerial,
    required int requestBoardVersion,
  }) async {
    final streaming = _repository is VisualTutorStreamingRepository
        ? _repository as VisualTutorStreamingRepository
        : null;
    if (streaming == null) {
      return _repository.sendTurn(request);
    }
    try {
      VisualTutorTurnResponseEntity? completed;
      var hasPresentedVisualAction = false;
      final iterator = _streamCoordinator.begin(streaming.streamTurn(request));
      while (await iterator.moveNext()) {
        final event = iterator.current;
        if (!mounted || !_streamCoordinator.isCurrent(turnSerial)) break;
        switch (event.type) {
          case VisualTutorStreamEventType.status:
            final state = event.data['state']?.toString();
            if (state != null && mounted)
              setState(() => _voiceStatus = 'Tutor is $state…');
            break;
          case VisualTutorStreamEventType.speechReady:
            if (mounted)
              setState(
                () => _voiceStatus = 'Tutor is preparing the explanation…',
              );
            break;
          case VisualTutorStreamEventType.boardAction:
            final action = event.boardAction;
            if (action != null) {
              _recordBoardActionDiagnostic(
                BoardActionDiagnostic(
                  actionId: action.id,
                  lifecycle: BoardActionLifecycle.received,
                ),
              );
            }
            // Provisional events only paint on the exact snapshot they were
            // generated from. turn_complete remains the state authority.
            if (action == null || !isValidBoardAction(action)) {
              if (action != null) {
                _recordBoardActionDiagnostic(
                  BoardActionDiagnostic(
                    actionId: action.id,
                    lifecycle: BoardActionLifecycle.skipped,
                    reason: 'invalid_action',
                  ),
                );
              }
              break;
            }
            _recordBoardActionDiagnostic(
              BoardActionDiagnostic(
                actionId: action.id,
                lifecycle: BoardActionLifecycle.schemaValid,
              ),
            );
            if (!mounted ||
                !isCurrentStreamedBoardAction(
                  requestBoardVersion: requestBoardVersion,
                  currentBoardVersion: _boardVersion,
                  eventBoardVersion: event.boardVersion,
                  eventBaseBoardVersion: event.baseBoardVersion,
                )) {
              _recordBoardActionDiagnostic(
                BoardActionDiagnostic(
                  actionId: action.id,
                  lifecycle: BoardActionLifecycle.skipped,
                  reason: 'stale_board_version',
                ),
              );
              break;
            }
            {
              _recordBoardActionDiagnostic(
                BoardActionDiagnostic(
                  actionId: action.id,
                  lifecycle: BoardActionLifecycle.queued,
                ),
              );
              // Skip non-visual marker types — they control timing only.
              final isMarker =
                  action.type == 'speak_marker' ||
                  action.type == 'pause_marker';

              // Sequential reveal: wait duration_ms so each element appears
              // one at a time, simulating a teacher writing on the board.
              // The first visual is the anti-blank-board safety net. Its
              // typed duration still drives the board's progressive writing,
              // but it must mount immediately when the SSE begins.
              final revealDelayMs = hasPresentedVisualAction
                  ? streamedBoardRevealDelayMs(action)
                  : 0;

              if (revealDelayMs > 0) {
                await Future<void>.delayed(
                  Duration(milliseconds: revealDelayMs),
                );
              }

              if (!mounted ||
                  !_streamCoordinator.isCurrent(turnSerial) ||
                  requestBoardVersion != _boardVersion) {
                _recordBoardActionDiagnostic(
                  BoardActionDiagnostic(
                    actionId: action.id,
                    lifecycle: BoardActionLifecycle.skipped,
                    reason: 'turn_cancelled_or_stale_after_queue',
                  ),
                );
                break;
              }

              if (!isMarker) {
                setState(() {
                  if (!_renderedBoardActions.any(
                    (existing) => existing.id == action.id,
                  )) {
                    _adoptBoardActions([..._renderedBoardActions, action]);
                    _voiceStatus = '✏️ Writing…';
                    _recordBoardActionDiagnostic(
                      BoardActionDiagnostic(
                        actionId: action.id,
                        lifecycle: BoardActionLifecycle.visible,
                      ),
                    );
                  }
                });
                hasPresentedVisualAction = true;
                // Auto-scroll the board to reveal the newly written element.
                _scrollBoardToAction(action);
              }
            }
            break;
          case VisualTutorStreamEventType.turnComplete:
            if (event.boardVersion != null &&
                (event.baseBoardVersion != requestBoardVersion ||
                    event.boardVersion! < _boardVersion)) {
              break;
            }
            completed = event.response;
            if (mounted) setState(() => _voiceStatus = null);
            break;
          case VisualTutorStreamEventType.boardPatch:
          case VisualTutorStreamEventType.error:
            break;
        }
      }
      await iterator.cancel();
      _streamCoordinator.clear(iterator);
      if (completed != null) return completed;
    } catch (_) {
      // A stream is progressive enhancement. Its POST fallback uses the same
      // idempotency key, so it cannot advance a lesson twice.
    }
    return _repository.sendTurn(request);
  }

  void _recordBoardActionDiagnostic(BoardActionDiagnostic diagnostic) {
    _boardActionDiagnostics.add(diagnostic);
    if (_boardActionDiagnostics.length > 120) {
      _boardActionDiagnostics.removeRange(
        0,
        _boardActionDiagnostics.length - 120,
      );
    }
    assert(() {
      debugPrint(
        'VisualTutor board action ${diagnostic.lifecycle.name}: '
        '${diagnostic.actionId}${diagnostic.reason == null ? '' : ' (${diagnostic.reason})'}',
      );
      return true;
    }());
    final lifecycle = switch (diagnostic.lifecycle) {
      BoardActionLifecycle.schemaValid => 'validated',
      _ => diagnostic.lifecycle.name,
    };
    _clientTelemetry.action(lifecycle);
    if (_boardActionDiagnostics.length % 10 == 0) _flushClientTelemetry();
  }

  void _flushClientTelemetry() {
    if (!mounted || _isLocalCurriculumDemo) return;
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final device = width < 600
        ? 'mobile'
        : width < 1000
        ? 'tablet'
        : 'desktop';
    final bucket = width < 380
        ? 'xs'
        : width < 480
        ? 'sm'
        : width < 800
        ? 'md'
        : width < 1200
        ? 'lg'
        : 'xl';
    unawaited(
      _clientTelemetry.flush(
        deviceClass: device,
        viewportBucket: bucket,
        reducedMotion: MediaQuery.of(context).disableAnimations,
      ),
    );
  }

  /// Measure the actual renderer, including semantic layout and canvas scale.
  /// Missing/not-yet-rendered actions never justify moving into empty space.
  void _scrollBoardToAction(VisualTutorBoardActionEntity action) {
    final boardStateId = _boardStateId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || boardStateId != _boardStateId ||
          !_boardVerticalController.hasClients) return;
      if (_manualBoardScrollUntil?.isAfter(DateTime.now()) ?? false) return;
      RenderBox? actionBox;
      void findAction(Element element) {
        if (element.widget.key == Key('teaching-board-action-${action.id}')) {
          final render = element.findRenderObject();
          if (render is RenderBox && render.hasSize) actionBox = render;
          return;
        }
        element.visitChildElements(findAction);
      }
      _teachingCanvasKey.currentContext?.visitChildElements(findAction);
      final box = actionBox;
      if (box == null || !box.attached) return;
      final canvas = _teachingCanvasKey.currentContext?.findRenderObject();
      if (canvas is! RenderBox || !canvas.hasSize) return;
      final bounds = MatrixUtils.transformRect(
        box.getTransformTo(canvas), Offset.zero & box.size,
      );
      final position = _boardVerticalController.position;
      final top = bounds.top;
      final bottom = bounds.bottom;
      final visibleTop = position.pixels;
      final visibleBottom = visibleTop + position.viewportDimension;
      // Oversized blocks are already visible when their beginning is visible.
      if (top >= visibleTop &&
          (bottom <= visibleBottom || top < visibleBottom - 56)) return;
      final target = (top - 24).clamp(0.0, position.maxScrollExtent);
      if ((target - position.pixels).abs() < 1) return;
      if (MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context)) {
        _boardVerticalController.jumpTo(target);
      } else {
        _boardVerticalController.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<bool> _refreshSessionAfterBoardConflict(
    int turnSerial, {
    String? sessionId,
  }) async {
    sessionId ??= _session?.sessionId;
    if (sessionId == null || sessionId.isEmpty) return false;
    try {
      final restored = await _repository.restoreSession(sessionId);
      if (!mounted || !_streamCoordinator.isCurrent(turnSerial)) return false;
      setState(() {
        _session = restored;
        final lessonState = _mapFromObject(
          restored.metadata['authoritative_lesson_state'],
        );
        _turnState = VisualTutorTurnStateEntity(
          problemInstanceId: _stringFromMap(lessonState, 'problem_instance_id'),
          lessonId: _stringFromMap(lessonState, 'lesson_id'),
          activeStepId: _stringFromMap(lessonState, 'active_step_id'),
          expectedStudentActionId: _stringFromMap(
            lessonState,
            'expected_student_action_id',
          ),
          problemText: restored.problemText,
          normalizedProblem: restored.normalizedProblem,
          currentStepIndex:
              _intFromMap(lessonState, 'current_step_index') ??
              restored.currentStepIndex,
          hintCount: restored.hintCount,
          wrongAttempts: restored.wrongAttempts,
          finalAnswerRevealed: restored.finalAnswerRevealed,
        );
        _boardVersion = _intFromMap(restored.metadata, 'board_version') ?? 0;
        _baseBoardVersion =
            _intFromMap(restored.metadata, 'base_board_version') ?? 0;
        _adoptBoardActions(_actionsFromSession(restored));
        _boardStateId = 'board-v$_boardVersion';
        _boardRestored = true;
        _boardSnapshot = null;
      });
      unawaited(_loadBoardSnapshot());
      return true;
    } catch (_) {
      return false;
    }
  }

  void _cancelActiveTurn() {
    _invalidateActiveStream();
    unawaited(_cancelVoiceRecording());
    _stopTutorSpeech();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _voiceStatus = 'Stopped. You can ask again.';
    });
  }

  /// Every cancel, retry, and new turn gets a new serial and closes the old
  /// iterator immediately. A late SSE frame can therefore never repaint the
  /// newer lesson, even while the HTTP transport is still unwinding.
  void _invalidateActiveStream() {
    _streamCoordinator.invalidate();
  }

  void _resetTutorState() {
    _messageController.clear();
    setState(() {
      _currentTurn = _initialGreetingTurn;
      _turnState = const VisualTutorTurnStateEntity();
      _adoptBoardActions(const []);
      _boardStateId = 'local-greeting-${DateTime.now().microsecondsSinceEpoch}';
      _boardRestored = false;
      _boardSnapshot = null;
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
    final actionId = response.speech?.speakAfterActionId?.trim();
    if (actionId != null && actionId.isNotEmpty) {
      // Board playback reports the actual animation completion. This avoids
      // speaking from a guessed timer when the learner pauses or replays.
      _pendingSpeechText = text;
      _pendingSpeechActionId = actionId;
      _pendingSpeechTurnSerial = turnSerial;
      return;
    }
    _speechDelayTimer = Timer(_speechDelayFor(response), () {
      if (!mounted || !_streamCoordinator.isCurrent(turnSerial)) return;
      _speakText(text);
    });
  }

  void _onBoardActionCompleted(String actionId) {
    if (actionId != _pendingSpeechActionId ||
        !_streamCoordinator.isCurrent(_pendingSpeechTurnSerial!)) {
      return;
    }
    final text = _pendingSpeechText;
    _pendingSpeechText = null;
    _pendingSpeechActionId = null;
    _pendingSpeechTurnSerial = null;
    if (text != null) unawaited(_speakText(text));
  }

  void _jumpToCurrentBoardStep() {
    final actions = _renderedBoardActions;
    if (actions.isEmpty || !_boardVerticalController.hasClients) return;
    final current = actions.last;
    _manualBoardScrollUntil = null;
    _scrollBoardToAction(current);
  }

  Future<void> _speakText(String text) async {
    if (_tutorMuted) return;
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
          // Show a short preview of what was heard so students know if STT
          // misheard them before they accidentally submit the wrong text.
          final preview = transcript.length > 60
              ? '${transcript.substring(0, 57)}…'
              : transcript;
          _voiceStatus = '🎤 Heard: "$preview" — Edit if needed, then send.';
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
    final topicId =
        widget.context?.topicId ??
        _topicId(widget.context?.topic ?? session.topic);
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
      'subject_id':
          widget.context?.subjectId ??
          _subjectId(widget.context?.subject ?? session.subject),
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
    // Progress needs the deterministic outcome, not solver evidence or a
    // hidden solution. Those details remain server-side while an answer lock
    // is active.
    return {'status': verification.status, 'verified': verification.verified};
  }

  Map<String, dynamic> _contextMetadata() {
    return {
      'entry_context': _hasCurriculumContext ? 'lesson' : 'ask_question',
      'is_curriculum_scoped': _hasCurriculumContext,
      'language_mode': _requestLanguageMode,
      if (_hasCurriculumContext)
        'grade': widget.context!.grade
      else if (_profileGradeNumber != null)
        'grade': _profileGradeNumber,
      if (_hasCurriculumContext) 'subject': widget.context!.subject,
      if (_hasCurriculumContext) 'topic': widget.context!.topic,
      if (_hasCurriculumContext && widget.context?.gradeLevelId != null)
        'grade_level_id': widget.context!.gradeLevelId,
      if (_hasCurriculumContext && widget.context?.subjectId != null)
        'subject_id': widget.context!.subjectId,
      if (_hasCurriculumContext && widget.context?.topicId != null)
        'topic_id': widget.context!.topicId,
      if (_hasCurriculumContext && widget.context?.lessonId != null)
        'lesson_id': widget.context!.lessonId,
      if (_hasCurriculumContext && widget.context?.curriculumVersionId != null)
        'curriculum_version_id': widget.context!.curriculumVersionId,
      if (_hasCurriculumContext && widget.context?.teachingMomentId != null)
        'teaching_moment_id': widget.context!.teachingMomentId,
    };
  }

  String _backendActionFor(VisualTutorStudentSubmission submission) {
    final intent = submission.intent.trim().toLowerCase();
    // Typed help phrases are soft client intents, but they still must reach
    // the server as help actions. Otherwise the gateway treats the phrase as
    // a math-step submission and records it as an incorrect answer.
    if (intent == 'stuck') return 'request_stuck_help';
    if (intent == 'request_hint') return 'request_hint';
    if (intent == 'request_explain_differently') {
      return 'explain_differently';
    }
    if (intent == 'request_answer') return 'request_final_answer';
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
      ...submission.metadata,
      // The selected lesson owns its curriculum identifiers. A quick action
      // must not overwrite them with stale client metadata.
      ..._contextMetadata(),
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
    final lessonState = _mapFromObject(metadata['authoritative_lesson_state']);
    final problemText =
        _stringFromMap(boardMetadata, 'problem_text') ??
        _problemFromBoard(response.board) ??
        _turnState.problemText ??
        _latestStudentMessage;
    return VisualTutorTurnStateEntity(
      problemInstanceId:
          _stringFromMap(lessonState, 'problem_instance_id') ??
          _turnState.problemInstanceId,
      lessonId: _stringFromMap(lessonState, 'lesson_id') ?? _turnState.lessonId,
      activeStepId:
          _stringFromMap(lessonState, 'active_step_id') ??
          _turnState.activeStepId,
      expectedStudentActionId:
          _stringFromMap(lessonState, 'expected_student_action_id') ??
          _turnState.expectedStudentActionId,
      problemText: problemText,
      normalizedProblem:
          _stringFromMap(boardMetadata, 'normalized_problem') ??
          _stringFromMap(metadata, 'normalized_problem') ??
          _turnState.normalizedProblem,
      currentStepIndex:
          _intFromMap(lessonState, 'current_step_index') ??
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

  /// The board keeps writing where the stream left off. A new identity would
  /// rebuild the board from nothing, so the student would watch the whole
  /// solution written a second time when `turn_complete` repeats it.
  void _adoptBoardActions(List<VisualTutorBoardActionEntity> next) {
    if (boardIdentityMustChange(
      // The service's own live preview line is dropped by the turn that
      // replaces it. Losing a presentation hint is not a new board.
      renderedActionIds: _renderedBoardActions
          .where((action) => !isProvisionalBoardAction(action))
          .map((action) => action.id),
      nextActionIds: next.map((action) => action.id),
    )) {
      _boardIdentitySerial++;
    }
    _renderedBoardActions = next;
  }

  List<VisualTutorBoardActionEntity> _nextRenderedBoardActions(
    VisualTutorTurnResponseEntity response, {
    required bool replace,
    required VisualTutorStudentSubmission submission,
  }) {
    final responseActions = response.boardActions.isEmpty
        ? response.canvasActions
        : response.boardActions;
    // A current response (including a locally validated teaching plan) is the
    // authoritative block for this turn. A replay snapshot is only a resume
    // fallback, never a reason to discard the current AI-selected actions.
    if (responseActions.isEmpty) {
      final snapshotActions = _actionsFromTeachingBoard(response.teachingBoard);
      if (snapshotActions.isNotEmpty) return snapshotActions;
    }
    if (replace) {
      return responseActions;
    }

    final boardUpdateMode =
        response.metadata['board_update_mode']?.toString() ?? 'replace';
    if (boardUpdateMode == 'replace') {
      return responseActions;
    }
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

  /// Legacy migration helper retained for replay migration only. New live
  /// turns never call this; they render their validated structured actions.
  List<VisualTutorBoardActionEntity> legacyTranscriptActionsForResponse(
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
    var bottom = SemanticBoardLayout.estimatedContentBottom(actions);
    for (final action in actions) {
      if (action.hidden) continue;
      final y = action.y ?? 0;
      final height = action.height ?? 44;
      bottom = math.max(bottom, y + height);
    }
    return bottom;
  }

  void _scrollBoardToNewTeachingBlock(
    List<VisualTutorBoardActionEntity> actions, {
    required Set<String> previousActionIds,
    required VisualTutorTurnResponseEntity response,
  }) {
    final responseIds = {
      ...response.boardActions.map((action) => action.id),
      ...response.canvasActions.map((action) => action.id),
    };
    final candidates = actions.where((action) =>
        !action.hidden && isValidBoardAction(action) &&
        (!previousActionIds.contains(action.id) || responseIds.contains(action.id)))
        .toList()..sort((a, b) => a.sequenceIndex.compareTo(b.sequenceIndex));
    if (candidates.isEmpty) return;
    // Anchor the first teaching action, never the trailing canvas padding.
    _scrollBoardToAction(candidates.first);
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
        .where(isValidBoardAction)
        .take(64)
        .toList()
      ..sort((a, b) => a.sequenceIndex.compareTo(b.sequenceIndex));
  }

  List<VisualTutorBoardActionEntity> _actionsFromBoardElements(
    List<Map<String, dynamic>> elements,
  ) {
    final actions = <VisualTutorBoardActionEntity>[];
    for (var index = 0; index < elements.length; index++) {
      final action = _actionFromElement(elements[index], index);
      if (action != null && isValidBoardAction(action)) actions.add(action);
      if (actions.length == 64) break;
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
    final serverMode = response.metadata['board_update_mode']?.toString();
    if (serverMode == 'replace') return true;
    final action = _backendActionFor(submission);
    final previousProblem = _turnState.problemText?.trim();
    final nextProblem =
        _stringFromMap(response.board.metadata, 'problem_text') ??
        _problemFromBoard(response.board);
    // A board may only be cleared for a genuinely new problem.  Some service
    // responses mark a single turn as `replace`, but using that signal alone
    // would erase earlier teaching steps when the response omits problem
    // metadata. A student's lesson board is therefore append-only for the
    // current problem.
    if (_renderedBoardActions.isEmpty) return true;
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
    // `submit_problem` without a different confirmed problem is a turn in the
    // existing lesson, not permission to discard its history.
    if (action == 'submit_problem') return false;
    return false;
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
    final loc = AppLocalizations.of(context);
    if (error is TimeoutException) {
      return loc.requestTimedOutFriendly;
    }
    if (error is ApiException) {
      if (error.statusCode == 408) {
        return loc.requestTimedOutFriendly;
      }
      if (error.statusCode == 409) {
        return loc.boardConflictFriendly;
      }
      final msg = error.message.trim();
      if (msg.isNotEmpty && !msg.toLowerCase().contains('backend') && !msg.toLowerCase().contains('exception')) {
        return msg;
      }
      return loc.connectionErrorFriendly;
    }
    return loc.connectionErrorFriendly;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VisualTutorColors.shell,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final formFactor = AppBreakpoints.getFormFactor(constraints.maxWidth);
          final isPhone = formFactor == DeviceFormFactor.phone;
          final isDesktop = formFactor == DeviceFormFactor.desktop;
          final compact = isPhone;
          final fabItems = _screenActionItems();

          final content = Column(
            children: [
              TutorPresenceBar(
                learningContext: widget.context,
                stageState: _currentTurn.teachingStage?.stageState,
                compact: compact,
                onHistoryTap: () =>
                    setState(() => _showHistoryPanel = !_showHistoryPanel),
                onReportTap: _showTutorReportSheet,
              ),
              Expanded(
                child: isPhone
                    ? Column(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: _teachingBoard(compact: true),
                                ),
                                if (fabItems.isNotEmpty)
                                  Positioned(
                                    right: 12,
                                    bottom: 16,
                                    child: _FloatingRadialFab(
                                      key: const Key('floating-radial-fab'),
                                      items: fabItems,
                                    ),
                                  ),
                                if (_showHistoryPanel)
                                  Positioned.fill(
                                    child: _HistoryPanel(
                                      history: _history,
                                      onClose: () => setState(
                                        () => _showHistoryPanel = false,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            key: const Key('tutor-phone-dock'),
                            decoration: BoxDecoration(
                              color: VisualTutorColors.shell,
                              border: Border(
                                top: BorderSide(
                                  color: VisualTutorColors.cyan.withValues(
                                    alpha: .18,
                                  ),
                                  width: 1,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .4),
                                  blurRadius: 16,
                                  offset: const Offset(0, -4),
                                ),
                              ],
                            ),
                            child: SafeArea(
                              top: false,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  4,
                                  12,
                                  8,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: _lowerTutorControls(true),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: _teachingBoard(compact: false),
                                ),
                                if (fabItems.isNotEmpty)
                                  Positioned(
                                    right: 16,
                                    bottom: 24,
                                    child: _FloatingRadialFab(
                                      key: const Key('floating-radial-fab'),
                                      items: fabItems,
                                    ),
                                  ),
                                if (_showHistoryPanel)
                                  Positioned.fill(
                                    child: _HistoryPanel(
                                      history: _history,
                                      onClose: () => setState(
                                        () => _showHistoryPanel = false,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            key: const Key('tutor-side-panel'),
                            width: isDesktop
                                ? AppBreakpoints.sidePanelWidthDesktop
                                : AppBreakpoints.sidePanelWidthTablet,
                            decoration: BoxDecoration(
                              color: VisualTutorColors.shell,
                              border: Border(
                                left: BorderSide(
                                  color: VisualTutorColors.cyan.withValues(
                                    alpha: .2,
                                  ),
                                  width: 1.2,
                                ),
                              ),
                            ),
                            child: SafeArea(
                              top: false,
                              child: Scrollbar(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    20,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: _lowerTutorControls(false),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );

          if (isDesktop) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.maxContentWidthDesktop,
                ),
                child: content,
              ),
            );
          }

          return content;
        },
      ),
    );
  }

  Widget _teachingBoard({required bool compact}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardVariant = _variantForCurrentTurn();
        final boardActions = _renderedBoardActions.isEmpty
            ? (_currentTurn.boardActions.isEmpty
                  ? _currentTurn.canvasActions
                  : _currentTurn.boardActions)
            : _renderedBoardActions;
        // Legacy sessions retain their logical 1000px canvas, while semantic
        // actions are resolved against the actual viewport. This prevents a
        // phone from inheriting desktop-width coordinates and horizontal
        // overflow from an older board session.
        final usesSemanticLayout = boardActions.any(
          (action) => action.layoutZone != null,
        );
        final hasLiveTranscript = _renderedBoardActions.any(
          (action) => action.metadata['transcript'] == true,
        );
        final effectiveBoardVariant = hasLiveTranscript
            ? 'speaking_writing'
            : boardVariant;
        final usesDedicatedVariant = _usesDedicatedBoardVariant(
          effectiveBoardVariant,
        );
        final canvasWidth = usesDedicatedVariant || usesSemanticLayout
            ? constraints.maxWidth
            : math.max(constraints.maxWidth, 1000.0);
        final contentHeight = _boardContentBottom() + 360;
        // A solution split across boards must not also scroll: the extra
        // canvas below the content is what left the student looking at blank
        // paper once the board scrolled to the end.
        final boardPages = paginateBoardActions(
          actions: boardActions,
          viewportHeight: constraints.maxHeight - boardTabsHeight,
          viewportWidth: constraints.maxWidth,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        );
        final canvasHeight = boardPages.length > 1
            ? constraints.maxHeight
            : math.max(
                math.max(constraints.maxHeight + 360, 980.0),
                contentHeight,
              );
        return Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification &&
                    notification.dragDetails != null ||
                    notification is UserScrollNotification &&
                        notification.direction != ScrollDirection.idle) {
                  // Respect a learner who intentionally reads earlier work.
                  _manualBoardScrollUntil = DateTime.now().add(
                    const Duration(seconds: 8),
                  );
                }
                return false;
              },
              child: Scrollbar(
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
                        key: _teachingCanvasKey,
                        width: canvasWidth,
                        height: canvasHeight,
                        child: TeachingCanvasBoard(
                          key: ValueKey('board-$_boardIdentitySerial'),
                          variant: effectiveBoardVariant,
                          board: _currentTurn.board,
                          actions: boardActions,
                          finalAnswerLocked: _currentTurn.finalAnswerLocked,
                          compact: compact,
                          // Respect the platform accessibility preference even
                          // when this board is reconstructed from a session.
                          reducedMotion:
                              MediaQuery.disableAnimationsOf(context) ||
                              MediaQuery.accessibleNavigationOf(context),
                          restored: _boardRestored,
                          useLogicalCanvasScale: true,
                          sessionId: _session?.sessionId,
                          boardStateId: _boardStateId,
                          snapshot: _boardSnapshot,
                          onSnapshotChanged: _saveBoardSnapshot,
                          onActionDiagnostic: _recordBoardActionDiagnostic,
                          onStudentInteraction: _handleBoardStudentInteraction,
                          onActionCompleted: _onBoardActionCompleted,
                          onJumpToCurrentStep: _jumpToCurrentBoardStep,
                          pageViewportHeight: constraints.maxHeight,
                        ),
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
            if (_isLocalCurriculumDemo)
              const Positioned(
                top: 14,
                left: 16,
                child: _LocalCurriculumDemoLabel(),
              ),
          ],
        );
      },
    );
  }

  void _handleBoardStudentInteraction(BoardStudentInteraction interaction) {
    if (interaction.kind == 'selection') return;
    final isExplain = interaction.kind == 'explain';
    final value = interaction.value?.trim() ?? '';
    if (!isExplain && value.isEmpty) return;
    _handleStudentSubmission(
      VisualTutorStudentSubmission(
        message: isExplain ? 'Please explain the selected board step.' : value,
        intent: isExplain ? 'explain_differently' : 'student_message',
        action: 'student_message',
        inputType: 'text',
        metadata: {
          'board_interaction': interaction.kind,
          'board_action_id': interaction.actionId,
        },
      ),
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
    // Screen state is tutoring state, not a visual layout selector. The live
    // board always uses the generic allow-list renderer for validated actions.
    return true;
  }

  // ── Helpers for the floating radial action menu ───────────────────────────

  bool _screenAllows(String action) {
    final plannedActions = _currentTurn.quickActions.isNotEmpty
        ? _currentTurn.quickActions
        : _currentTurn.allowedActions;
    if (plannedActions.isEmpty) return false;
    final normalized = _normalizeScreenAction(action);
    return plannedActions.map(_normalizeScreenAction).contains(normalized);
  }

  String _normalizeScreenAction(String action) {
    final n = action
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    return switch (n) {
      'hint' => 'request_hint',
      'check_step' || 'submitted_step' || 'submit_step' => 'check_work',
      'show_answer' => 'request_answer',
      'request_final_answer' => 'request_answer',
      'show_visual_hint' => 'show_visually',
      'request_explain_differently' => 'explain_differently',
      _ => n,
    };
  }

  bool get _screenInputEnabled {
    final stage = _currentTurn.teachingStage?.stageState;
    final interactionEnabled = _currentTurn.interaction?.inputEnabled;
    if ((stage == 'analyzing' || stage == 'drawing') &&
        interactionEnabled != true) {
      return false;
    }
    return interactionEnabled ?? true;
  }

  void _screenSubmitQuickAction(String action) {
    final normalized = _normalizeScreenAction(action);
    final message = switch (normalized) {
      'request_hint' => 'Hint',
      'stuck' => "I'm stuck",
      'show_visually' => 'Show visually',
      'explain_differently' => 'Explain differently',
      'check_work' =>
        _messageController.text.trim().isEmpty
            ? 'Check my step'
            : _messageController.text.trim(),
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
    _handleStudentSubmission(
      VisualTutorStudentSubmission(
        message: message,
        intent: intent,
        action: normalized == 'show_visually'
            ? 'explain_differently'
            : normalized,
        inputType: 'quick_action',
        metadata: normalized == 'show_visually'
            ? const {'mode': 'show_visually'}
            : const {},
      ),
    );
  }

  List<_RadialItem> _screenActionItems() {
    final enabled = _screenInputEnabled;
    return [
      if (_screenAllows('request_hint'))
        _RadialItem(
          key: const Key('screen-quick-hint'),
          icon: Icons.lightbulb_outline,
          label: 'Hint',
          onPressed: enabled
              ? () => _screenSubmitQuickAction('request_hint')
              : null,
        ),
      if (_screenAllows('stuck'))
        _RadialItem(
          key: const Key('screen-quick-stuck'),
          icon: Icons.support_agent,
          label: "Stuck",
          onPressed: enabled ? () => _screenSubmitQuickAction('stuck') : null,
        ),
      if (_screenAllows('show_visually'))
        _RadialItem(
          key: const Key('screen-quick-visual'),
          icon: Icons.visibility_outlined,
          label: 'Visual',
          onPressed: enabled
              ? () => _screenSubmitQuickAction('show_visually')
              : null,
        ),
      if (_screenAllows('check_work'))
        _RadialItem(
          key: const Key('screen-quick-check'),
          icon: Icons.fact_check_outlined,
          label: 'Check',
          onPressed: enabled
              ? () => _screenSubmitQuickAction('check_work')
              : null,
        ),
      if (_screenAllows('explain_differently'))
        _RadialItem(
          key: const Key('screen-quick-explain'),
          icon: Icons.swap_horiz_rounded,
          label: 'Explain',
          onPressed: enabled
              ? () => _screenSubmitQuickAction('explain_differently')
              : null,
        ),
      if (_screenAllows('request_answer'))
        _RadialItem(
          key: const Key('screen-quick-answer'),
          icon: _currentTurn.finalAnswerLocked
              ? Icons.lock_outline_rounded
              : Icons.key_rounded,
          label: 'Answer',
          onPressed: enabled
              ? () => _screenSubmitQuickAction('request_answer')
              : null,
        ),
    ];
  }

  /// True when the step panel would say something the quote above it has not
  /// already said.
  bool get _stepPanelAddsSomething {
    String plain(String value) =>
        value.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    final spoken = plain(_currentTurn.speech?.text ?? _currentTurn.spokenText);
    final shown = plain(_currentTurn.displayText);
    if (shown.isEmpty) return false;
    return shown != spoken;
  }

  /// A verdict is worth showing only when it judged the student's own work.
  /// "Cannot verify" on a turn the student never submitted work for tells them
  /// nothing and crowds out the board.
  bool get _showsVerification {
    final verification = _currentTurn.verification;
    if (verification == null) return false;
    return const {
      'correct',
      'invalid',
      'incomplete',
      'mathematically_valid_but_inefficient',
    }.contains(verification.status);
  }

  List<Widget> _lowerTutorControls(bool compact) {
    final speechText = _currentTurn.speech?.text ?? _currentTurn.spokenText;
    return [
      const SizedBox(height: 8),
      // Keep the teacher's current short explanation visible above the task.
      // This is intentionally presentation-only: the board remains the source
      // of visual teaching actions and no model-authored widget code is used.
      TutorSpeechQuotePanel(
        speechText: speechText,
        compact: compact,
        isSpeaking: !_tutorMuted && _voiceStatus?.contains('Speaking') == true,
        onReplay: _tutorMuted
            ? null
            : () {
                unawaited(_speakText(speechText));
              },
        onStop: _stopTutorSpeech,
      ),
      // The step panel repeated the same sentence directly under the quote
      // above it, costing a third of the panel for nothing. It now appears
      // only when it has something else to say.
      if (_stepPanelAddsSomething) ...[
      const SizedBox(height: 8),
      _CompactStepPanel(
        stepNumber: math.max(1, _turnState.currentStepIndex + 1),
        explanation: _currentTurn.displayText,
        task: _currentTurn.studentTask,
        expanded: _stepPanelExpanded,
        onToggle: () =>
            setState(() => _stepPanelExpanded = !_stepPanelExpanded),
        onJumpToLatest: _jumpToLatestStep,
        onReviewPrevious: _reviewPreviousStep,
        onResumeTask: _resumeCurrentTask,
      ),
      ],
      const SizedBox(height: 8),
      if (_apiError != null) ...[
        _TutorApiErrorBanner(
          key: const Key('visual-tutor-api-error'),
          message: _apiError!,
          onRetry: _retryLastSubmission,
        ),
        const SizedBox(height: 8),
      ],
      if (_isLoading) ...[
        _TutorLoadingControls(
          status: _voiceStatus,
          onCancel: _cancelActiveTurn,
        ),
        const SizedBox(height: 8),
      ],
      if (_isTranscribingVoice) ...[
        const LinearProgressIndicator(key: Key('voice-transcribing')),
        const SizedBox(height: 8),
      ],
      if (_showsVerification) ...[
        const SizedBox(height: 6),
        _VerificationFeedbackPanel(verification: _currentTurn.verification!),
      ],
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
        voiceMode: widget.voiceMode,
        keyboardMode: _keyboardMode,
        onKeyboardToggle: () {
          setState(() => _keyboardMode = !_keyboardMode);
        },
        isTutorMuted: _tutorMuted,
        onMuteToggle: () {
          if (_tutorMuted) {
            setState(() => _tutorMuted = false);
          } else {
            _stopTutorSpeech();
            setState(() => _tutorMuted = true);
          }
        },
        onCancelRecording: _isListening ? _cancelVoiceRecording : null,
        onTargetedPractice: widget.onOpenTargetedPractice == null
            ? null
            : _openTargetedPractice,
      ),
    ];
  }

  Future<void> _showTutorReportSheet() async {
    final session = _session;
    if (session == null || _currentTurn.turnId.isEmpty) {
      _showTutorSnackBar('Start a tutor session before sending a report.');
      return;
    }
    final reason = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What was the problem?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your report is sent without the lesson text, audio, or image.',
              ),
              const SizedBox(height: 10),
              for (final item in const <(String, String)>[
                ('incorrect_math', 'Incorrect math'),
                ('confusing_explanation', 'Confusing explanation'),
                ('unsafe_unhelpful', 'Unsafe or unhelpful'),
                ('visual_problem', 'Visual problem'),
                ('other', 'Other'),
              ])
                ListTile(
                  key: Key('tutor-report-reason-${item.$1}'),
                  title: Text(item.$2),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(sheetContext).pop(item.$1),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || reason == null) return;
    final client = ApiClient(
      config: AppConfig.current,
      tokenProvider: appAuthService.getAccessToken,
    );
    try {
      await client.post(
        '/tutor/reports',
        body: {
          'tutor_session_id': session.sessionId,
          'tutor_turn_id': _currentTurn.turnId,
          'reason': reason,
        },
      );
      if (mounted)
        _showTutorSnackBar('Thank you — your report was sent for review.');
    } catch (_) {
      if (mounted)
        _showTutorSnackBar('We could not send that report. Please try again.');
    } finally {
      client.close();
    }
  }

  void _showTutorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openTargetedPractice() {
    final session = _session;
    final openPractice = widget.onOpenTargetedPractice;
    if (session == null || openPractice == null) return;
    final verification = _currentTurn.verification;
    openPractice(
      TargetedPracticeContext(
        topicId:
            widget.context?.topicId ??
            _topicId(widget.context?.topic ?? session.topic),
        subjectId:
            widget.context?.subjectId ??
            _subjectId(widget.context?.subject ?? session.subject),
        gradeLevelId:
            widget.context?.gradeLevelId ??
            'grade-${widget.context?.grade ?? 10}',
        tutorSessionId: session.sessionId,
        hintCount: _turnState.hintCount,
        stuckCount: _turnState.wrongAttempts,
        misconceptions: _turnState.wrongAttempts > 0
            ? const ['recent_verified_incorrect_step']
            : const [],
        verificationResults: verification == null
            ? const []
            : [verification.status],
      ),
    );
  }

  void _jumpToLatestStep() {
    if (!_boardVerticalController.hasClients) return;
    final currentIds = _currentTurn.boardActions
        .map((action) => action.id)
        .toSet();
    final currentActions = _renderedBoardActions
        .where((action) => currentIds.contains(action.id) && !action.hidden)
        .toList();
    // With nothing identifiable to jump to, stay where we are: scrolling to
    // the end of the canvas used to park the student on empty paper.
    if (currentActions.isEmpty) return;
    final targetY = currentActions.map((action) => action.y ?? 0.0).reduce(math.min);
    _boardVerticalController.animateTo(
      math.max(
        0,
        math.min(
          _boardVerticalController.position.maxScrollExtent,
          targetY - 48,
        ),
      ),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _reviewPreviousStep() {
    if (!_boardVerticalController.hasClients) return;
    final position = _boardVerticalController.position;
    _boardVerticalController.animateTo(
      math.max(0, position.pixels - position.viewportDimension * .8),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _resumeCurrentTask() {
    _jumpToLatestStep();
  }
}

class _LocalCurriculumDemoLabel extends StatelessWidget {
  const _LocalCurriculumDemoLabel();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Local curriculum demo. This is not a published production lesson.',
    child: Container(
      key: const Key('local-curriculum-demo-label'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: VisualTutorColors.panel.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VisualTutorColors.cyan.withValues(alpha: .7)),
      ),
      child: const Text(
        'Local curriculum demo',
        style: TextStyle(
          color: VisualTutorColors.cyan,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    ),
  );
}

class _CurrentLearningStepPanel extends StatelessWidget {
  const _CurrentLearningStepPanel({
    required this.stepNumber,
    required this.explanation,
    required this.task,
    required this.onJumpToLatest,
    required this.onReviewPrevious,
    required this.onResumeTask,
  });

  final int stepNumber;
  final String explanation;
  final String task;
  final VoidCallback onJumpToLatest;
  final VoidCallback onReviewPrevious;
  final VoidCallback onResumeTask;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: 'New teaching step $stepNumber. $explanation Current task: $task',
    child: Container(
      key: const Key('current-learning-step-panel'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VisualTutorColors.shellElevated,
        borderRadius: BorderRadius.circular(VisualTutorRadius.md),
        border: Border.all(color: VisualTutorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).stepCurrent(stepNumber),
            style: const TextStyle(
              color: VisualTutorColors.cyan,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            explanation,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: VisualTutorColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (task.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Semantics(
              label: 'Current student task: $task',
              child: Text(
                AppLocalizations.of(context).yourTask(task),
                style: const TextStyle(
                  color: VisualTutorColors.textSubtle,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              TextButton.icon(
                key: const Key('review-previous-step'),
                onPressed: onReviewPrevious,
                icon: const Icon(Icons.arrow_upward_rounded, size: 17),
                label: Text(AppLocalizations.of(context).reviewPrevious),
              ),
              TextButton.icon(
                key: const Key('jump-to-latest-step'),
                onPressed: onJumpToLatest,
                icon: const Icon(Icons.south_rounded, size: 17),
                label: Text(AppLocalizations.of(context).jumpToLatest),
              ),
              TextButton.icon(
                key: const Key('resume-current-task'),
                onPressed: onResumeTask,
                icon: const Icon(Icons.play_arrow_rounded, size: 17),
                label: Text(AppLocalizations.of(context).resumeTask),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Compact collapsible step indicator. Shows a single-row chip when collapsed,
/// and expands to show the full explanation, task, and navigation buttons.
class _CompactStepPanel extends StatelessWidget {
  const _CompactStepPanel({
    required this.stepNumber,
    required this.explanation,
    required this.task,
    required this.expanded,
    required this.onToggle,
    required this.onJumpToLatest,
    required this.onReviewPrevious,
    required this.onResumeTask,
  });

  final int stepNumber;
  final String explanation;
  final String task;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onJumpToLatest;
  final VoidCallback onReviewPrevious;
  final VoidCallback onResumeTask;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Step $stepNumber: $explanation',
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        child: Container(
          key: const Key('current-learning-step-panel'),
          decoration: BoxDecoration(
            color: VisualTutorColors.shellElevated,
            borderRadius: BorderRadius.circular(VisualTutorRadius.md),
            border: Border.all(color: VisualTutorColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Collapsed header row — always visible ──────────────────────
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(VisualTutorRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: VisualTutorColors.cyan.withValues(
                              alpha: .14,
                            ),
                            borderRadius: BorderRadius.circular(
                              VisualTutorRadius.pill,
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context).stepNumber(stepNumber),
                            style: const TextStyle(
                              color: VisualTutorColors.cyan,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            explanation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: VisualTutorColors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: VisualTutorColors.textMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ── Expanded detail ────────────────────────────────────────────
              if (expanded) ...[
                Divider(height: 1, color: VisualTutorColors.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        explanation,
                        style: const TextStyle(
                          color: VisualTutorColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (task.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          AppLocalizations.of(context).yourTask(task),
                          style: const TextStyle(
                            color: VisualTutorColors.textSubtle,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          TextButton.icon(
                            key: const Key('review-previous-step'),
                            onPressed: onReviewPrevious,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(
                              Icons.arrow_upward_rounded,
                              size: 14,
                            ),
                            label: Text(
                              AppLocalizations.of(context).reviewPrevious,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton.icon(
                            key: const Key('jump-to-latest-step'),
                            onPressed: onJumpToLatest,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.south_rounded, size: 14),
                            label: Text(
                              AppLocalizations.of(context).jumpToLatest,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton.icon(
                            key: const Key('resume-current-task'),
                            onPressed: onResumeTask,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              size: 14,
                            ),
                            label: Text(
                              AppLocalizations.of(context).resumeTask,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
    this.onHistoryTap,
    this.onReportTap,
  });

  final LearningContext? learningContext;
  final String? stageState;
  final bool compact;
  final VoidCallback? onHistoryTap;
  final VoidCallback? onReportTap;

  @override
  Widget build(BuildContext context) {
    final status = _statusFor(stageState);

    return Container(
      key: const Key('tutor-presence-bar'),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 24,
        vertical: compact ? 8 : 16,
      ),
      decoration: VisualTutorDecorations.presenceBar(),
      child: Row(
        children: [
          // ── Avatar with status glow ──────────────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              ReanAvatar(size: compact ? 36 : 48),
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
                Text(
                  AppLocalizations.of(context).tutorPresenceTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VisualTutorTypography.presenceTitle,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context).isKhmer
                            ? status.khmer
                            : status.english,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VisualTutorTypography.presenceStatus,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context).isKhmer
                            ? status.english
                            : status.khmer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VisualTutorTypography.presenceStatus.copyWith(
                          color: VisualTutorColors.cyan.withValues(alpha: .6),
                        ),
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
                    letterSpacing: .5,
                  ),
                ),
              ),
            ),
          // ── Language switcher button ────────────────────────────────────
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: LanguageSwitcherButton(compact: true),
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
              tooltip: AppLocalizations.of(context).conversationHistory,
              onPressed: onHistoryTap,
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.history_rounded,
                color: VisualTutorColors.textMuted,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: compact ? 36 : 40,
            height: compact ? 36 : 40,
            decoration: BoxDecoration(
              color: VisualTutorColors.panelRaised,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: VisualTutorColors.border),
            ),
            child: PopupMenuButton<String>(
              tooltip: AppLocalizations.of(context).tutorMenu,
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: VisualTutorColors.textMuted,
                size: 20,
              ),
              color: VisualTutorColors.shellElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VisualTutorRadius.md),
                side: BorderSide(color: VisualTutorColors.border),
              ),
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'how_it_works',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.help_outline_rounded,
                        size: 16,
                        color: VisualTutorColors.cyan,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context).firstRunTitle,
                        style: const TextStyle(
                          color: VisualTutorColors.text,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'report',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flag_outlined,
                        size: 16,
                        color: VisualTutorColors.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context).reportExplanation,
                        style: const TextStyle(
                          color: VisualTutorColors.text,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'how_it_works') {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (sheetContext) => FirstRunExplainerSheet(
                      onStart: () => Navigator.of(sheetContext).pop(),
                      onSkip: () => Navigator.of(sheetContext).pop(),
                    ),
                  );
                } else if (value == 'report') {
                  onReportTap?.call();
                }
              },
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

/// Slide-in conversation history panel. Overlays the board from the right.
/// Tapping the backdrop closes the panel.
class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.history, required this.onClose});

  final List<_TutorHistoryMessage> history;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Semi-transparent backdrop ──────────────────────────────────────
        Expanded(
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: .2),
                    Colors.black.withValues(alpha: .5),
                  ],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        // ── History panel ──────────────────────────────────────────────────
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: VisualTutorColors.shell,
            border: Border(left: BorderSide(color: VisualTutorColors.border)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                  decoration: BoxDecoration(
                    color: VisualTutorColors.presenceBarBg,
                    border: Border(
                      bottom: BorderSide(color: VisualTutorColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        color: VisualTutorColors.cyan,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).conversationHistory,
                          style: const TextStyle(
                            color: VisualTutorColors.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: VisualTutorColors.textMuted,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(6),
                        tooltip: AppLocalizations.of(context).closeHistory,
                      ),
                    ],
                  ),
                ),
                // Messages list
                Expanded(
                  child: history.isEmpty
                      ? Center(
                          child: Text(
                            AppLocalizations.of(context).noConversationYet,
                            style: const TextStyle(
                              color: VisualTutorColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: history.length,
                          itemBuilder: (_, i) {
                            final msg = history[i];
                            final isStudent = msg.role == 'You';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: isStudent
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  if (!isStudent) ...[
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: VisualTutorColors.cyan
                                            .withValues(alpha: .14),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.auto_awesome_rounded,
                                        color: VisualTutorColors.cyan,
                                        size: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isStudent
                                            ? VisualTutorColors.cyan.withValues(
                                                alpha: .12,
                                              )
                                            : VisualTutorColors.shellElevated,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(12),
                                          topRight: const Radius.circular(12),
                                          bottomLeft: Radius.circular(
                                            isStudent ? 12 : 4,
                                          ),
                                          bottomRight: Radius.circular(
                                            isStudent ? 4 : 12,
                                          ),
                                        ),
                                        border: Border.all(
                                          color: isStudent
                                              ? VisualTutorColors.cyan
                                                    .withValues(alpha: .25)
                                              : VisualTutorColors.border,
                                        ),
                                      ),
                                      child: Text(
                                        msg.text,
                                        style: TextStyle(
                                          color: isStudent
                                              ? VisualTutorColors.cyan
                                              : VisualTutorColors.textSubtle,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          height: 1.45,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isStudent) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: VisualTutorColors.cyan
                                            .withValues(alpha: .18),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.person_rounded,
                                        color: VisualTutorColors.cyan,
                                        size: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
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
      padding: EdgeInsets.fromLTRB(12, compact ? 8 : 14, 8, compact ? 8 : 14),
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
              maxLines: compact ? 2 : 4,
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

/// Deterministic verification is deliberately presented independently from the
/// tutor's natural-language explanation.  A friendly AI sentence is never a
/// substitute for a verified math result.
class _VerificationFeedbackPanel extends StatelessWidget {
  const _VerificationFeedbackPanel({required this.verification});

  final VisualTutorVerificationEntity verification;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = verification.status;
    final (label, color, icon) = switch (status) {
      'correct' => (
        l10n.verifiedCorrect,
        VisualTutorColors.cyan,
        Icons.verified_outlined,
      ),
      'mathematically_valid_but_inefficient' => (
        l10n.validShowRequestedStep,
        VisualTutorColors.orange,
        Icons.route_outlined,
      ),
      'invalid' => (
        l10n.stepNeedsCorrection,
        VisualTutorColors.orange,
        Icons.error_outline,
      ),
      'incomplete' => (
        l10n.moreOfStepNeeded,
        VisualTutorColors.textSubtle,
        Icons.pending_outlined,
      ),
      _ => (
        l10n.mathCheckUnavailable,
        VisualTutorColors.textSubtle,
        Icons.info_outline,
      ),
    };
    return Semantics(
      liveRegion: true,
      label: '$label: ${verification.studentMessage}',
      child: Container(
        key: const Key('visual-tutor-verification-feedback'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .11),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .55)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label · ${verification.studentMessage}',
                style: VisualTutorTypography.tutorSpeech.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorLoadingControls extends StatelessWidget {
  const _TutorLoadingControls({
    required this.onCancel,
    this.status,
  });

  final VoidCallback onCancel;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final effectiveStatus = (status != null && status!.trim().isNotEmpty)
        ? status!
        : AppLocalizations.of(context).tutorThinkingAndDrawing;

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
          Expanded(
            child: Text(
              effectiveStatus,
              style: const TextStyle(
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
            label: Text(AppLocalizations.of(context).cancel),
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
    this.actionInterval = Duration.zero,
    this.useLogicalCanvasScale = false,
    this.sessionId,
    this.boardStateId,
    this.snapshot,
    this.onSnapshotChanged,
    this.onActionDiagnostic,
    this.onStudentInteraction,
    this.onActionCompleted,
    this.onJumpToCurrentStep,
    this.pageViewportHeight,
  });

  /// Height the student can actually see, used to decide where one board ends
  /// and the next begins. Without it the board is handed the whole scrollable
  /// canvas and believes everything fits.
  final double? pageViewportHeight;

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
  final String? sessionId;
  final String? boardStateId;
  final VisualTutorBoardSnapshot? snapshot;
  final ValueChanged<VisualTutorBoardSnapshot>? onSnapshotChanged;
  final BoardActionDiagnosticListener? onActionDiagnostic;
  final ValueChanged<BoardStudentInteraction>? onStudentInteraction;

  /// Fired only after the action's own board animation has completed.
  final ValueChanged<String>? onActionCompleted;
  final VoidCallback? onJumpToCurrentStep;

  @override
  State<TeachingCanvasBoard> createState() => _TeachingCanvasBoardState();
}

class _TeachingCanvasBoardState extends State<TeachingCanvasBoard>
    with TickerProviderStateMixin {
  late AnimationController _strokeController;
  late AnimationController _waitController;
  late TransformationController _viewportController;
  List<VisualTutorBoardActionEntity> _visibleActions = [];
  int _boardPageIndex = 0;
  bool _studentPickedBoardPage = false;
  List<String> _playedActionIds = [];
  String? _activeActionId;
  int _lastActionSignature = 0;
  int _generation = 0;
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _isReplaying = false;
  bool _isApplyingSnapshot = false;
  bool _drawingMode = false;
  bool _eraseMode = false;
  String? _selectedActionId;
  final List<_StudentInkStroke> _studentInk = [];
  final List<_StudentInkStroke> _redoInk = [];
  Completer<void>? _resumeCompleter;
  Timer? _viewportSnapshotTimer;
  bool _lastEffectiveReducedMotion = false;
  bool _systemReducedMotion = false;
  String? _waitingForStudentActionId;
  int _pauseVersion = 0;

  bool get _renderImmediately =>
      !widget.animate || _effectiveReducedMotion || widget.restored;

  bool get _replayDisabled => !widget.animate || _effectiveReducedMotion;

  bool get _effectiveReducedMotion {
    return widget.reducedMotion || _systemReducedMotion;
  }

  @override
  void initState() {
    super.initState();
    _strokeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..value = 1;
    _waitController = AnimationController(vsync: this)..value = 1;
    _viewportController = TransformationController();
    _viewportController.addListener(_onViewportChanged);
    _syncActions(initial: true);
    _restoreSnapshot();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.maybeOf(context);
    _systemReducedMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
    final changed = _lastEffectiveReducedMotion != _effectiveReducedMotion;
    _lastEffectiveReducedMotion = _effectiveReducedMotion;
    if (changed && _lastActionSignature != 0) {
      _syncActions();
    }
  }

  @override
  void didUpdateWidget(covariant TeachingCanvasBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSignature = _signatureFor(widget.actions);
    if (nextSignature != _lastActionSignature ||
        oldWidget.finalAnswerLocked != widget.finalAnswerLocked ||
        oldWidget.restored != widget.restored ||
        oldWidget.reducedMotion != widget.reducedMotion ||
        oldWidget.animate != widget.animate ||
        oldWidget.snapshot != widget.snapshot) {
      _syncActions();
      _restoreSnapshot();
    }
  }

  @override
  void dispose() {
    _cancelTimeline();
    _strokeController.dispose();
    _waitController.dispose();
    _viewportSnapshotTimer?.cancel();
    _viewportController.removeListener(_onViewportChanged);
    _viewportController.dispose();
    super.dispose();
  }

  int _signatureFor(List<VisualTutorBoardActionEntity> actions) {
    return Object.hashAll(actions.map((action) => _actionSignature(action)));
  }

  int _actionSignature(VisualTutorBoardActionEntity action) {
    // Board patches are authoritative snapshots. Include every declarative
    // rendering field so a geometry, graph, focus, or style-only patch cannot
    // leave an old visual on screen merely because its action ID is unchanged.
    try {
      return jsonEncode({
        'id': action.id,
        'type': action.type,
        'sequence_index': action.sequenceIndex,
        'duration_ms': action.durationMs,
        'wait_for_speech_marker': action.waitForSpeechMarker,
        'requires_student_response': action.requiresStudentResponse,
        'group_id': action.groupId,
        'section_id': action.sectionId,
        'x': action.x,
        'y': action.y,
        'width': action.width,
        'height': action.height,
        'text': action.text,
        'latex': action.latex,
        'points': action.points,
        'graph': action.graph,
        'target_id': action.targetId,
        'style': action.style,
        'locked': action.locked,
        'hidden': action.hidden,
        'reveal_policy': action.revealPolicy,
        'metadata': action.metadata,
      }).hashCode;
    } catch (_) {
      // The network decoder accepts JSON-compatible values only. This fallback
      // keeps a malformed legacy local action from crashing the board.
      return Object.hash(
        action.id,
        action.type,
        action.sequenceIndex,
        action.points.toString(),
        action.graph.toString(),
        action.style.toString(),
        action.metadata.toString(),
      );
    }
  }


  /// Boards the current teaching is split across, using the height the student
  /// can actually see.
  double _boardWidth = 390;

  List<BoardPage> _boardPages() => paginateBoardActions(
    actions: _visibleActions,
    viewportHeight:
        (widget.pageViewportHeight ?? double.infinity) - boardTabsHeight,
    viewportWidth: _boardWidth,
  );

  int _visibleBoardPageIndex(List<BoardPage> pages) {
    if (pages.length <= 1) return 0;
    // The step being written wins, unless the student went back to read an
    // earlier board themselves.
    final active = pageIndexOfAction(pages, _activeActionId);
    final target = _studentPickedBoardPage
        ? _boardPageIndex
        : (active ?? _boardPageIndex);
    return target.clamp(0, pages.length - 1);
  }

  List<VisualTutorBoardActionEntity> _currentBoardPageActions() {
    final pages = _boardPages();
    if (pages.length <= 1) return _visibleActions;
    return pages[_visibleBoardPageIndex(pages)].actions;
  }

  /// Follow the teacher's hand: when a newly written action lands on a later
  /// board, move there -- unless the student is reading an earlier board.
  ///
  /// Callers are already inside setState, so this only assigns. Calling
  /// setState again from here nests it inside the caller's own callback, which
  /// aborted playback and left the student staring at a blank board.
  void _followBoardPageFor(VisualTutorBoardActionEntity action) {
    if (_studentPickedBoardPage) return;
    final pages = _boardPages();
    if (pages.length <= 1) return;
    final index = pageIndexOfAction(pages, action.id);
    if (index == null || index == _boardPageIndex) return;
    _boardPageIndex = index;
    // The tutor moved to the next board: show it from its first line.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showBoardFromTheTop();
    });
  }

  void _selectBoardPage(int index) {
    setState(() {
      _boardPageIndex = index;
      _studentPickedBoardPage = true;
    });
    _showBoardFromTheTop();
  }

  /// A new board starts at its first line. The board lives inside a pan/zoom
  /// viewport, so without this it keeps whatever offset the student left on the
  /// previous board -- and the next board, drawn at the top, is off-screen. To
  /// the student that is simply a blank board.
  void _showBoardFromTheTop() {
    // A paged board is sized to the screen, so there is nothing to scroll --
    // only this pan/zoom transform can hide the new board's content.
    _viewportController.value = Matrix4.identity();
  }

  List<VisualTutorBoardActionEntity> _sortedRenderableActions() {
    final sortedActions = [..._effectiveActions]
      ..sort((a, b) {
        final sequence = a.sequenceIndex.compareTo(b.sequenceIndex);
        return sequence != 0 ? sequence : a.id.compareTo(b.id);
      });
    return sortedActions
        .where(
          (action) =>
              isValidBoardAction(action) &&
              !_isMarker(action) &&
              !(action.hidden || (action.locked && widget.finalAnswerLocked)),
        )
        .toList();
  }

  List<VisualTutorBoardActionEntity> _sortedPlayableActions() {
    final sortedActions = [..._effectiveActions]
      ..sort((a, b) {
        final sequence = a.sequenceIndex.compareTo(b.sequenceIndex);
        return sequence != 0 ? sequence : a.id.compareTo(b.id);
      });
    return sortedActions
        .where(
          (action) =>
              _isTimelinePlayableAction(action) &&
              (_isMarker(action) ||
                  !(action.hidden ||
                      (action.locked && widget.finalAnswerLocked))),
        )
        .toList();
  }

  bool _isMarker(VisualTutorBoardActionEntity action) {
    return action.type == 'pause_marker' || action.type == 'speak_marker';
  }

  bool _isTimelinePlayableAction(VisualTutorBoardActionEntity action) {
    if (isValidBoardAction(action)) return true;
    // Older local snapshots used a timed speak marker before the public
    // transport contract standardized it to zero duration. It is not accepted
    // from streaming, but keeping this bounded playback compatibility avoids
    // breaking existing restored lessons.
    return action.type == 'speak_marker' &&
        action.durationMs >= 0 &&
        action.durationMs <= 8000;
  }

  List<VisualTutorBoardActionEntity> get _effectiveActions {
    final snapshot = widget.snapshot;
    if (snapshot == null || !_snapshotMatchesBoard(snapshot))
      return widget.actions;
    final visibleIds = snapshot.visibleActionIds.toSet();
    final hiddenIds = snapshot.hiddenActionIds.toSet();
    final fadedIds = snapshot.fadedActionIds.toSet();
    return widget.actions
        .map((action) {
          final shouldHide =
              hiddenIds.contains(action.id) ||
              (visibleIds.isNotEmpty &&
                  !_isMarker(action) &&
                  !visibleIds.contains(action.id));
          final faded = fadedIds.contains(action.id);
          return action.copyWith(
            hidden: action.hidden || shouldHide,
            metadata: faded
                ? {...action.metadata, 'faded': true}
                : action.metadata,
          );
        })
        .toList(growable: false);
  }

  bool _snapshotMatchesBoard(VisualTutorBoardSnapshot snapshot) {
    if (widget.sessionId == null ||
        widget.boardStateId == null ||
        snapshot.sessionId != widget.sessionId ||
        snapshot.boardStateId != widget.boardStateId)
      return false;
    return snapshot.actions.length == widget.actions.length &&
        _signatureFor(snapshot.actions) == _signatureFor(widget.actions);
  }

  void _restoreSnapshot() {
    final snapshot = widget.snapshot;
    if (snapshot == null || !_snapshotMatchesBoard(snapshot)) return;
    _isApplyingSnapshot = true;
    try {
      _studentInk
        ..clear()
        ..addAll(
          snapshot.studentInk.map(
            (stroke) =>
                _StudentInkStroke(points: List<Offset>.of(stroke.points)),
          ),
        );
      _redoInk.clear();
      _selectedActionId = snapshot.focusedActionId;
      _viewportController.value = Matrix4.identity()
        ..translateByDouble(
          snapshot.viewport.translateX,
          snapshot.viewport.translateY,
          0,
          1,
        )
        ..scaleByDouble(snapshot.viewport.scale, snapshot.viewport.scale, 1, 1);
    } finally {
      _isApplyingSnapshot = false;
    }
    // Restore never resumes motion. The snapshot's playhead/paused state is
    // retained for an explicit replay, while the board is shown complete now.
    _isPlaying = false;
    _isPaused = false;
    _isReplaying = false;
  }

  void _notifySnapshot() {
    final callback = widget.onSnapshotChanged;
    final sessionId = widget.sessionId;
    final boardStateId = widget.boardStateId;
    if (callback == null || sessionId == null || boardStateId == null) return;
    final matrix = _viewportController.value.storage;
    callback(
      VisualTutorBoardSnapshot(
        sessionId: sessionId,
        boardStateId: boardStateId,
        actions: List<VisualTutorBoardActionEntity>.of(widget.actions),
        visibleActionIds: _visibleActions
            .map((action) => action.id)
            .toList(growable: false),
        hiddenActionIds: _effectiveActions
            .where((action) => action.hidden)
            .map((action) => action.id)
            .toList(growable: false),
        fadedActionIds: _effectiveActions
            .where((action) => action.metadata['faded'] == true)
            .map((action) => action.id)
            .toList(growable: false),
        focusedActionId: _selectedActionId,
        studentInk: _studentInk
            .map(
              (stroke) =>
                  VisualTutorStudentInkStroke(List<Offset>.of(stroke.points)),
            )
            .toList(growable: false),
        playheadIndex: math.min(_playedActionIds.length, widget.actions.length),
        playbackPaused: _isPaused,
        viewport: VisualTutorBoardViewport(
          scale: matrix[0].clamp(1.0, 3.0).toDouble(),
          translateX: matrix[12],
          translateY: matrix[13],
        ),
      ),
    );
  }

  void _onViewportChanged() {
    if (!_isApplyingSnapshot) {
      // Panning can produce dozens of matrix updates each frame. Persist the
      // final viewport shortly after the gesture settles instead of repeatedly
      // serialising the complete board and ink layer on low-end devices.
      _viewportSnapshotTimer?.cancel();
      _viewportSnapshotTimer = Timer(const Duration(milliseconds: 160), () {
        if (mounted) _notifySnapshot();
      });
    }
  }

  void _syncActions({bool initial = false}) {
    _cancelTimeline();
    _activeActionId = null;
    _lastActionSignature = _signatureFor(widget.actions);
    for (final action in widget.actions) {
      if (!_isTimelinePlayableAction(action)) {
        _emitActionDiagnostic(
          action.id,
          BoardActionLifecycle.skipped,
          reason: 'invalid_action',
        );
      }
    }
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
        _activeActionId = null;
        _isPlaying = false;
        _isPaused = false;
      });
      for (final action in sortedActions) {
        _emitActionDiagnostic(action.id, BoardActionLifecycle.visible);
      }
      return;
    }

    final newActions = _sortedPlayableActions()
        .where((action) => !_playedActionIds.contains(action.id))
        .toList();
    for (final action in newActions) {
      _emitActionDiagnostic(action.id, BoardActionLifecycle.queued);
    }
    if (newActions.isEmpty) {
      setState(() {
        _visibleActions = sortedActions;
        _activeActionId = null;
        _isPlaying = false;
        _isPaused = false;
      });
      return;
    }
    final generation = _generation;
    // Mount the first actual teaching visual before an optional marker/timer
    // yields.  On Flutter Web a streamed `turn_complete` can otherwise leave
    // a blank board while the zero-duration speak marker is queued. The
    // timeline still owns the animation and records the action only after it
    // has played; this is a display safety net, not a second lesson state.
    VisualTutorBoardActionEntity? firstVisible;
    var firstVisibleIndex = -1;
    for (var index = 0; index < newActions.length; index++) {
      if (!_isMarker(newActions[index])) {
        firstVisible = newActions[index];
        firstVisibleIndex = index;
        break;
      }
    }
    // A real speech gate must remain a gate. The immediate mount is only for
    // marker-free or zero-duration marker prefixes, such as the final board
    // snapshot sent after a streamed tutor turn completes.
    final waitsForSpeech =
        firstVisibleIndex > 0 &&
        newActions
            .take(firstVisibleIndex)
            .any(
              (action) =>
                  action.type == 'speak_marker' &&
                  (action.waitForSpeechMarker || action.durationMs > 0),
            );
    final immediatelyVisibleAction = firstVisible;
    setState(() {
      _isPlaying = true;
      if (!waitsForSpeech &&
          immediatelyVisibleAction != null &&
          !_visibleActions.any(
            (action) => action.id == immediatelyVisibleAction.id,
          )) {
        _visibleActions = [..._visibleActions, immediatelyVisibleAction];
        _followBoardPageFor(immediatelyVisibleAction);
        _emitActionDiagnostic(
          immediatelyVisibleAction.id,
          BoardActionLifecycle.visible,
        );
      }
    });
    _playActions(newActions, generation);
  }

  Future<void> _playActions(
    List<VisualTutorBoardActionEntity> actions,
    int generation,
  ) async {
    for (final action in actions) {
      if (!mounted || generation != _generation) return;
      if (action.type == 'pause_marker') {
        if (!await _waitForDuration(_markerDuration(action), generation))
          return;
        _playedActionIds = [..._playedActionIds, action.id];
        _notifySnapshot();
        continue;
      }
      if (action.type == 'speak_marker') {
        if (!await _waitForDuration(_markerDuration(action), generation))
          return;
        _playedActionIds = [..._playedActionIds, action.id];
        _notifySnapshot();
        continue;
      }
      // `wait_for_speech_marker` is part of the existing board-action
      // contract. A preceding speak marker is its deterministic barrier. We
      // deliberately do not invent a TTS-completion callback here: legacy
      // turns without a marker continue safely instead of deadlocking.
      setState(() {
        if (!_visibleActions.any((visible) => visible.id == action.id)) {
          _visibleActions = [..._visibleActions, action];
          _followBoardPageFor(action);
          _emitActionDiagnostic(action.id, BoardActionLifecycle.visible);
        }
        _playedActionIds = [..._playedActionIds, action.id];
        _activeActionId = _drawsProgressively(action) ? action.id : null;
      });
      _notifySnapshot();
      final duration = _animationDurationFor(action);
      final completed = _drawsProgressively(action)
          ? await _runController(_strokeController, duration, generation)
          : await _waitForDuration(duration, generation);
      if (!completed || !mounted || generation != _generation) return;
      setState(() => _activeActionId = null);
      widget.onActionCompleted?.call(action.id);
      _notifySnapshot();
      if (action.requiresStudentResponse) {
        setState(() {
          _waitingForStudentActionId = action.id;
          _isPaused = true;
        });
        _resumeCompleter = Completer<void>();
        if (!await _waitUntilPlaying(generation)) return;
        if (mounted && generation == _generation) {
          setState(() => _waitingForStudentActionId = null);
        }
      }
      if (widget.actionInterval > Duration.zero &&
          !await _waitForDuration(widget.actionInterval, generation)) {
        return;
      }
    }
    if (mounted && generation == _generation) {
      setState(() {
        _activeActionId = null;
        _isPlaying = false;
        _isPaused = false;
        _isReplaying = false;
      });
      _notifySnapshot();
    }
  }

  void _emitActionDiagnostic(
    String actionId,
    BoardActionLifecycle lifecycle, {
    String? reason,
  }) {
    widget.onActionDiagnostic?.call(
      BoardActionDiagnostic(
        actionId: actionId,
        lifecycle: lifecycle,
        reason: reason,
      ),
    );
  }

  Duration _markerDuration(VisualTutorBoardActionEntity action) {
    // Marker timing is authored as part of the teaching timeline. Unlike a
    // visible drawing duration, it is not substituted with a default.
    return Duration(milliseconds: math.max(0, action.durationMs));
  }

  Future<bool> _waitForDuration(Duration duration, int generation) {
    return _runController(_waitController, duration, generation);
  }

  Future<bool> _runController(
    AnimationController controller,
    Duration duration,
    int generation,
  ) async {
    if (duration == Duration.zero) {
      return mounted && generation == _generation;
    }
    controller.duration = duration;
    controller.value = 0;
    while (mounted && generation == _generation && controller.value < 1) {
      if (!await _waitUntilPlaying(generation)) return false;
      final pauseVersion = _pauseVersion;
      try {
        await controller.forward(from: controller.value).orCancel;
      } on TickerCanceled {
        if (!mounted || generation != _generation) return false;
        // A pause cancels an AnimationController future. It can be resumed
        // before this catch runs, so use a version token instead of reading
        // only `_isPaused` (which would incorrectly cancel the timeline).
        if (pauseVersion == _pauseVersion) return false;
      }
    }
    return mounted && generation == _generation;
  }

  Future<bool> _waitUntilPlaying(int generation) async {
    while (_isPaused && mounted && generation == _generation) {
      final completer = _resumeCompleter ??= Completer<void>();
      await completer.future;
    }
    return mounted && generation == _generation;
  }

  void _cancelTimeline() {
    _generation++;
    _strokeController.stop(canceled: true);
    if (_waitController.isAnimating) {
      _waitController.stop(canceled: true);
    }
    _resumeCompleter?.complete();
    _resumeCompleter = null;
    _isPaused = false;
    _isPlaying = false;
  }

  void _replay() {
    if (_replayDisabled) return;
    _cancelTimeline();
    final playableActions = _sortedPlayableActions();
    final generation = _generation;
    setState(() {
      _visibleActions = [];
      _boardPageIndex = 0;
      _studentPickedBoardPage = false;
      _playedActionIds = [];
      _activeActionId = null;
      _isPlaying = playableActions.isNotEmpty;
      _isPaused = false;
      _isReplaying = playableActions.isNotEmpty;
    });
    _notifySnapshot();
    if (playableActions.isNotEmpty) {
      _playActions(playableActions, generation);
    }
  }

  void _togglePlayback() {
    if (_replayDisabled || !_isPlaying) {
      _replay();
      return;
    }
    if (_isPaused) {
      // AnimationController cancels its future when paused. Rather than
      // relying on its cancellation callback racing the resume tap, cancel
      // this generation and restart only the unplayed suffix. The visible
      // board remains intact and no completed action can be replayed.
      final remaining = _sortedPlayableActions()
          .where((action) => !_playedActionIds.contains(action.id))
          .toList(growable: false);
      _cancelTimeline();
      final generation = _generation;
      setState(() {
        _isPlaying = remaining.isNotEmpty;
        _isPaused = false;
      });
      if (remaining.isNotEmpty) {
        _playActions(remaining, generation);
      }
      _notifySnapshot();
      return;
    }
    setState(() => _isPaused = true);
    _resumeCompleter = Completer<void>();
    _pauseVersion++;
    _strokeController.stop(canceled: true);
    _waitController.stop(canceled: true);
    _notifySnapshot();
  }

  bool _drawsProgressively(VisualTutorBoardActionEntity action) {
    return action.type == 'draw_line' ||
        action.type == 'draw_arrow' ||
        action.type == 'circle' ||
        action.type == 'cross_out' ||
        action.type == 'write_text' ||
        action.type == 'write_equation' ||
        action.type == 'draw_axes' ||
        action.type == 'show_table' ||
        action.type == 'show_graph' ||
        action.type == 'plot_function';
  }

  Duration _animationDurationFor(VisualTutorBoardActionEntity action) {
    const min = 160;
    const max = 1800;
    final fallback = switch (action.type) {
      'write_text' => 360,
      'write_equation' => 520,
      'draw_line' || 'draw_arrow' => 420,
      'circle' || 'cross_out' => 560,
      _ => 420,
    };
    final requested = action.durationMs > 0 ? action.durationMs : fallback;
    return Duration(milliseconds: requested.clamp(min, max).toInt());
  }

  void _handleStudentInteraction(BoardStudentInteraction interaction) {
    if (interaction.kind == 'selection') {
      setState(() => _selectedActionId = interaction.actionId);
    }
    widget.onStudentInteraction?.call(interaction);
    if (interaction.kind == 'answer' &&
        interaction.actionId == _waitingForStudentActionId) {
      setState(() {
        _waitingForStudentActionId = null;
        _isPaused = false;
      });
      _resumeCompleter?.complete();
      _resumeCompleter = null;
    }
    _notifySnapshot();
  }

  void _resetToFit() {
    _viewportController.value = Matrix4.identity();
    setState(() {});
    _notifySnapshot();
  }

  void _onInkPointerDown(PointerDownEvent event) {
    if (!_drawingMode) return;
    final point = _viewportController.toScene(event.localPosition);
    if (_eraseMode) {
      _eraseStrokeAt(point);
      return;
    }
    setState(() {
      _studentInk.add(_StudentInkStroke(points: [point]));
      _redoInk.clear();
    });
    _notifySnapshot();
  }

  void _onInkPointerMove(PointerMoveEvent event) {
    if (!_drawingMode || _eraseMode || _studentInk.isEmpty) return;
    final point = _viewportController.toScene(event.localPosition);
    setState(() => _studentInk.last.points.add(point));
  }

  void _onInkPointerUp(PointerUpEvent event) {
    if (_drawingMode && !_eraseMode) _notifySnapshot();
  }

  void _eraseStrokeAt(Offset point) {
    const radiusSquared = 22.0 * 22.0;
    final index = _studentInk.lastIndexWhere(
      (stroke) => stroke.points.any(
        (candidate) => (candidate - point).distanceSquared <= radiusSquared,
      ),
    );
    if (index < 0) return;
    setState(() {
      _redoInk.add(_studentInk.removeAt(index));
    });
    _notifySnapshot();
  }

  void _undoInk() {
    if (_studentInk.isEmpty) return;
    setState(() => _redoInk.add(_studentInk.removeLast()));
    _notifySnapshot();
  }

  void _redoLastInk() {
    if (_redoInk.isEmpty) return;
    setState(() => _studentInk.add(_redoInk.removeLast()));
    _notifySnapshot();
  }

  void _clearInk() {
    if (_studentInk.isEmpty) return;
    setState(() {
      _redoInk.addAll(_studentInk);
      _studentInk.clear();
    });
    _notifySnapshot();
  }

  @override
  Widget build(BuildContext context) {
    final variant = _variantFor(widget.board, widget.variant);
    final boardPages = _boardPages();
    // LiveTeachingBoard is the canonical renderer. Unlike the prior dedicated
    // variant path, it receives the active controller and paints the current
    // action progressively.
    return Container(
      key: const Key('visual-tutor-canvas-board'),
      width: double.infinity,
      decoration: BoxDecoration(color: VisualTutorColors.boardPaper),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _boardWidth = constraints.maxWidth;
                return Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _onInkPointerDown,
                onPointerMove: _onInkPointerMove,
                onPointerUp: _onInkPointerUp,
                child: InteractiveViewer(
                  key: const Key('visual-tutor-board-viewport'),
                  transformationController: _viewportController,
                  minScale: 1,
                  maxScale: 3,
                  boundaryMargin: const EdgeInsets.all(120),
                  panEnabled: !_drawingMode,
                  scaleEnabled: !_drawingMode,
                  constrained: false,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: LiveTeachingBoard(
                            key: ValueKey(
                              _isReplaying
                                  ? 'live-teaching-replay-$_generation'
                                  : 'live-teaching-steady',
                            ),
                            board: widget.board,
                            actions: _currentBoardPageActions(),
                            variant: variant,
                            finalAnswerLocked: widget.finalAnswerLocked,
                            compact: widget.compact,
                            useLogicalCanvasScale: widget.useLogicalCanvasScale,
                            activeActionId: _activeActionId,
                            activeProgress: _strokeController,
                            reducedMotion:
                                _effectiveReducedMotion || !widget.animate,
                            // A resumed lesson is static by default, but an
                            // explicit replay re-enables calm board motion.
                            restored: widget.restored && !_isReplaying,
                            transitionsEnabled: !_isPlaying,
                            selectedActionId: _selectedActionId,
                            onStudentInteraction: _handleStudentInteraction,
                            onActionDiagnostic: widget.onActionDiagnostic,
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                key: const Key('student-ink-canvas'),
                                painter: _StudentInkPainter(
                                  List<_StudentInkStroke>.of(_studentInk),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                );
              },
            ),
          ),
          // Above the pan/zoom canvas: inside it, the ink Listener and
          // InteractiveViewer swallow the taps and the switcher would pan away
          // with the board.
          Positioned(
            top: AppBreakpoints.isPhone(context) ? 56 : 8,
            left: 8,
            child: _StudentBoardControls(
              drawingMode: _drawingMode,
              erasing: _eraseMode,
              canUndo: _studentInk.isNotEmpty,
              canRedo: _redoInk.isNotEmpty,
              onResetToFit: _resetToFit,
              onToggleDrawing: () => setState(() {
                _drawingMode = !_drawingMode;
                if (!_drawingMode) _eraseMode = false;
              }),
              onToggleErase: () => setState(() {
                _drawingMode = true;
                _eraseMode = !_eraseMode;
              }),
              onUndo: _undoInk,
              onRedo: _redoLastInk,
              onClear: _clearInk,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: _BoardPlaybackControls(
              isPaused: _isPaused,
              reducedMotion: _replayDisabled,
              waitingForStudent: _waitingForStudentActionId != null,
              onReplay: _replay,
              onTogglePlayback: _togglePlayback,
              onJumpToCurrentStep: widget.onJumpToCurrentStep ?? _resetToFit,
            ),
          ),
          if (widget.actions.any((action) => !isValidBoardAction(action)))
            Positioned(
              top: 96, right: 8,
              child: Semantics(
                liveRegion: true,
                child: const Text(
                  'One visual detail was skipped. Continue.',
                  key: Key('teaching-board-recovery-notice'),
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ),
            ),
          if (boardPages.length > 1)
            Positioned(
              top: 6,
              left: 0,
              right: 0,
              child: Center(
                child: BoardPageSwitcher(
                  pages: boardPages,
                  currentIndex: _visibleBoardPageIndex(boardPages),
                  onSelected: _selectBoardPage,
                ),
              ),
            ),
        ],
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
}

class _BoardPlaybackControls extends StatelessWidget {
  const _BoardPlaybackControls({
    required this.isPaused,
    required this.reducedMotion,
    required this.waitingForStudent,
    required this.onReplay,
    required this.onTogglePlayback,
    required this.onJumpToCurrentStep,
  });

  final bool isPaused;
  final bool reducedMotion;
  final bool waitingForStudent;
  final VoidCallback onReplay;
  final VoidCallback onTogglePlayback;
  final VoidCallback onJumpToCurrentStep;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final playLabel = waitingForStudent
        ? l10n.resumeTask
        : isPaused
        ? l10n.playBoardTimeline
        : l10n.pauseBoardTimeline;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VisualTutorColors.panel.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VisualTutorColors.cyan.withValues(alpha: .5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: const Key('visual-tutor-board-replay'),
            tooltip: l10n.replayBoard,
            icon: const Icon(Icons.replay_rounded, size: 18),
            color: VisualTutorColors.cyan,
            constraints: AppBreakpoints.touchTargetConstraints,
            onPressed: reducedMotion ? null : onReplay,
          ),
          IconButton(
            key: const Key('visual-tutor-board-jump-current'),
            tooltip: l10n.jumpToCurrentStep,
            icon: const Icon(Icons.my_location_rounded, size: 18),
            color: VisualTutorColors.cyan,
            constraints: AppBreakpoints.touchTargetConstraints,
            onPressed: onJumpToCurrentStep,
          ),
          Semantics(
            label: playLabel,
            button: true,
            child: ExcludeSemantics(
              child: IconButton(
                key: const Key('visual-tutor-board-play-pause'),
                tooltip: playLabel,
                icon: Icon(
                  isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  size: 18,
                ),
                color: VisualTutorColors.cyan,
                constraints: AppBreakpoints.touchTargetConstraints,
                onPressed: reducedMotion ? null : onTogglePlayback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentInkStroke {
  _StudentInkStroke({required this.points});

  final List<Offset> points;
}

class _StudentInkPainter extends CustomPainter {
  const _StudentInkPainter(this.strokes);

  final List<_StudentInkStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = VisualTutorColors.blueInk.withValues(alpha: .82)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      if (stroke.points.length == 1) {
        canvas.drawCircle(
          stroke.points.first,
          1.2,
          paint..style = PaintingStyle.fill,
        );
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (final point in stroke.points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StudentInkPainter oldDelegate) =>
      oldDelegate.strokes != strokes;
}

class _StudentBoardControls extends StatelessWidget {
  const _StudentBoardControls({
    required this.drawingMode,
    required this.erasing,
    required this.canUndo,
    required this.canRedo,
    required this.onResetToFit,
    required this.onToggleDrawing,
    required this.onToggleErase,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
  });

  final bool drawingMode;
  final bool erasing;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onResetToFit;
  final VoidCallback onToggleDrawing;
  final VoidCallback onToggleErase;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VisualTutorColors.panel.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VisualTutorColors.cyan.withValues(alpha: .45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: const Key('visual-tutor-board-reset-fit'),
            tooltip: l10n.resetBoardView,
            icon: const Icon(Icons.fit_screen_rounded, size: 18),
            color: VisualTutorColors.cyan,
            constraints: AppBreakpoints.touchTargetConstraints,
            onPressed: onResetToFit,
          ),
          IconButton(
            key: const Key('student-ink-pen'),
            tooltip: drawingMode ? l10n.stopDrawing : l10n.drawOnBoard,
            icon: Icon(
              Icons.edit_rounded,
              size: 18,
              color: drawingMode ? VisualTutorColors.cyan : null,
            ),
            color: VisualTutorColors.cyan,
            constraints: AppBreakpoints.touchTargetConstraints,
            onPressed: onToggleDrawing,
          ),
          IconButton(
            key: const Key('student-ink-erase'),
            tooltip: erasing ? l10n.stopErasing : l10n.eraseInk,
            icon: Icon(
              Icons.auto_fix_normal_rounded,
              size: 18,
              color: erasing ? VisualTutorColors.cyan : null,
            ),
            color: VisualTutorColors.cyan,
            constraints: AppBreakpoints.touchTargetConstraints,
            onPressed: onToggleErase,
          ),
          IconButton(
            key: const Key('student-ink-undo'),
            tooltip: l10n.undoInk,
            icon: const Icon(Icons.undo_rounded, size: 18),
            color: VisualTutorColors.cyan,
            constraints: AppBreakpoints.touchTargetConstraints,
            onPressed: canUndo ? onUndo : null,
          ),
          IconButton(
            key: const Key('student-ink-redo'),
            tooltip: l10n.redoInk,
            icon: const Icon(Icons.redo_rounded, size: 18),
            color: VisualTutorColors.cyan,
            constraints: AppBreakpoints.touchTargetConstraints,
            onPressed: canRedo ? onRedo : null,
          ),
          IconButton(
            key: const Key('student-ink-clear'),
            tooltip: l10n.clearInk,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: VisualTutorColors.cyan,
            constraints: AppBreakpoints.touchTargetConstraints,
            onPressed: canUndo ? onClear : null,
          ),
        ],
      ),
    );
  }
}

class _BoardStatusCluster extends StatelessWidget {
  const _BoardStatusCluster({required this.locked, required this.compact});

  final bool locked;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              locked ? l10n.guidedMode : l10n.answerReady,
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

class _CheckWorkHeader extends StatelessWidget {
  const _CheckWorkHeader({
    required this.onRetry,
    required this.compact,
  });

  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: VisualTutorColors.panelRaised,
        borderRadius: BorderRadius.circular(VisualTutorRadius.md),
        border: Border.all(color: VisualTutorColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.task_alt_rounded,
            color: VisualTutorColors.cyan,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).isKhmer
                  ? 'ពិនិត្យជំហានរបស់អ្នក'
                  : 'Check your step',
              style: TextStyle(
                color: VisualTutorColors.text,
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w800,
                fontFamilyFallback: VisualTutorTypography.fontFallback,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Retry the submitted tutor work',
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(AppLocalizations.of(context).retry),
            ),
          ),
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
                label: Text(AppLocalizations.of(context).retry),
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
    this.voiceMode = false,
    this.keyboardMode = false,
    this.onKeyboardToggle,
    this.isTutorMuted = false,
    this.onMuteToggle,
    this.onCancelRecording,
    this.onTargetedPractice,
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
  final bool voiceMode;
  final bool keyboardMode;
  final VoidCallback? onKeyboardToggle;
  final bool isTutorMuted;
  final VoidCallback? onMuteToggle;
  final VoidCallback? onTargetedPractice;
  final VoidCallback? onCancelRecording;

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
    final normalized = text
        .trim()
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll('‘', "'");
    if (normalized.contains('stuck') ||
        normalized.contains("don't understand") ||
        normalized.contains('dont understand') ||
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
    final openPractice = widget.onTargetedPractice;
    if (openPractice != null) return openPractice();
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
        onSelectProblem: (problem) {
          widget.onSubmit(
            VisualTutorStudentSubmission(
              message: problem,
              intent: 'new_problem',
              action: 'submit_problem',
              inputType: 'quick_action',
              metadata: const {'entry_point': 'unsupported_problem_chip'},
            ),
          );
        },
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
          if (widget.isListening && widget.onCancelRecording != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const Key('voice-cancel-recording'),
                onPressed: widget.onCancelRecording,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: Text(AppLocalizations.of(context).cancelRecording),
              ),
            ),
          ],
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
              voiceMode: widget.voiceMode,
              keyboardMode: widget.keyboardMode,
              onKeyboardToggle: widget.onKeyboardToggle,
              isTutorMuted: widget.isTutorMuted,
              onMuteToggle: widget.onMuteToggle,
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
              voiceMode: widget.voiceMode,
              keyboardMode: widget.keyboardMode,
              onKeyboardToggle: widget.onKeyboardToggle,
              isTutorMuted: widget.isTutorMuted,
              onMuteToggle: widget.onMuteToggle,
            ),
          ],
          // Inline quick-action chips — always visible, one-tap shortcuts
          // so students don't need to discover the radial menu.
          _QuickActionChipRow(
            actions: _actionItems(),
            inputEnabled: _inputEnabled,
          ),
        ],
      ),
    );
  }

  List<({Key key, IconData icon, String label, VoidCallback? onPressed})>
  _actionItems() {
    return [
      if (_allows('request_hint'))
        (
          key: const Key('quick-action-hint'),
          icon: Icons.lightbulb_outline,
          label: 'Hint',
          onPressed: _inputEnabled
              ? () => _submitQuickAction('request_hint')
              : null,
        ),
      if (_allows('stuck'))
        (
          key: const Key('quick-action-stuck'),
          icon: Icons.support_agent,
          label: "I'm stuck",
          onPressed: _inputEnabled ? () => _submitQuickAction('stuck') : null,
        ),
      if (_allows('show_visually'))
        (
          key: const Key('quick-action-show-visually'),
          icon: Icons.visibility_outlined,
          label: 'Visual',
          onPressed: _inputEnabled
              ? () => _submitQuickAction('show_visually')
              : null,
        ),
      if (_allows('check_work'))
        (
          key: const Key('quick-action-check-step'),
          icon: Icons.fact_check_outlined,
          label: 'Check',
          onPressed: _inputEnabled
              ? () => _submitQuickAction('check_work')
              : null,
        ),
      if (_allows('explain_differently'))
        (
          key: const Key('quick-action-explain-differently'),
          icon: Icons.swap_horiz_rounded,
          label: 'Explain',
          onPressed: _inputEnabled
              ? () => _submitQuickAction('explain_differently')
              : null,
        ),
      if (_allows('request_answer'))
        (
          key: const Key('quick-action-show-answer'),
          icon: widget.turn.finalAnswerLocked
              ? Icons.lock_outline_rounded
              : Icons.visibility_outlined,
          label: _isCheckWork ? 'Solution' : 'Answer',
          onPressed: _inputEnabled
              ? () => _submitQuickAction('request_answer')
              : null,
        ),
    ];
  }

  Widget _radialActionMenu() {
    final items = _actionItems();
    if (items.isEmpty) return const SizedBox.shrink();
    return _RadialActionMenu(
      key: const Key('radial-action-menu'),
      items: [
        for (final item in items)
          _RadialItem(
            key: item.key,
            icon: item.icon,
            label: item.label,
            onPressed: item.onPressed,
          ),
      ],
    );
  }

  // keep old _quickActions / _quickActionStrip stubs so no other caller breaks
  List<Widget> _quickActions() => [];
  Widget _quickActionStrip() => const SizedBox.shrink();
}

/// A horizontal scrollable row of quick-action chips shown below the text
/// input. Provides always-visible one-tap shortcuts for common student moves.
class _QuickActionChipRow extends StatelessWidget {
  const _QuickActionChipRow({
    required this.actions,
    required this.inputEnabled,
  });

  final List<({Key key, IconData icon, String label, VoidCallback? onPressed})>
  actions;
  final bool inputEnabled;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final action in actions) ...[
              _QuickChip(
                key: action.key,
                icon: action.icon,
                label: action.label,
                onPressed: action.onPressed,
                enabled: inputEnabled && action.onPressed != null,
              ),
              const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 160),
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: VisualTutorColors.cyan),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: VisualTutorColors.blueInk,
            fontFamilyFallback: VisualTutorTypography.fontFallback,
          ),
        ),
        onPressed: enabled ? onPressed : null,
        backgroundColor: VisualTutorColors.cyan.withValues(alpha: 0.08),
        side: BorderSide(
          color: VisualTutorColors.cyan.withValues(alpha: 0.3),
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
            label: Text(AppLocalizations.of(context).tryAgain),
            style:
                FilledButton.styleFrom(
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
                  elevation: WidgetStatePropertyAll(onTryAgain != null ? 6 : 0),
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
            label: Text(AppLocalizations.of(context).showMeWhy),
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
                  label: AppLocalizations.of(context).repeat,
                  onPressed: onRepeat,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FinalPanelButton(
                  key: const Key('final-show-summary-button'),
                  icon: Icons.menu_book_rounded,
                  label: AppLocalizations.of(context).showSummary,
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
            child: Text(AppLocalizations.of(context).nextPracticeProblem),
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
            child: Text(AppLocalizations.of(context).backToHome),
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
    this.onSelectProblem,
  });

  final String prompt;
  final bool compact;
  final String? notice;
  final VoidCallback onTryAnother;
  final ValueChanged<String>? onSelectProblem;

  static const String sampleLimits = r'\lim_{x \to 3} \frac{x^2 - 9}{x - 3}';
  static const String samplePhysics = 'v = u + at, u=0, a=2, t=5';
  static const String sampleChemistry = r'2H_2 + O_2 \to 2H_2O';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
          const SizedBox(height: 14),
          Text(
            loc.supportedGrade12TopicsPrompt,
            style: const TextStyle(
              color: VisualTutorColors.cyan,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                key: const Key('unsupported-chip-limits'),
                avatar: const Text('📐'),
                label: const Text(r'lim x→3 (x²-9)/(x-3)'),
                onPressed: () => onSelectProblem?.call(sampleLimits),
              ),
              ActionChip(
                key: const Key('unsupported-chip-physics'),
                avatar: const Text('⚡'),
                label: const Text('v = u + at, u=0, a=2, t=5'),
                onPressed: () => onSelectProblem?.call(samplePhysics),
              ),
              ActionChip(
                key: const Key('unsupported-chip-chemistry'),
                avatar: const Text('🧪'),
                label: const Text('2H₂ + O₂ → 2H₂O'),
                onPressed: () => onSelectProblem?.call(sampleChemistry),
              ),
            ],
          ),
          SizedBox(height: compact ? 14 : 18),
          FilledButton(
            key: const Key('unsupported-try-another-button'),
            onPressed: onTryAnother,
            style: VisualTutorButtonStyles.primary().copyWith(
              minimumSize: WidgetStatePropertyAll(
                Size.fromHeight(compact ? 48 : 54),
              ),
            ),
            child: Text(loc.tryAnotherProblem),
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
    required this.voiceMode,
    required this.keyboardMode,
    required this.onKeyboardToggle,
    required this.isTutorMuted,
    required this.onMuteToggle,
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
  final bool voiceMode;
  final bool keyboardMode;
  final VoidCallback? onKeyboardToggle;
  final bool isTutorMuted;
  final VoidCallback? onMuteToggle;

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
    if (voiceMode && !keyboardMode) {
      return _VoiceFirstDock(
        enabled: inputEnabled,
        isListening: isListening,
        muted: isTutorMuted,
        onVoiceInput: onVoiceInput,
        onOpenKeyboard: onKeyboardToggle,
        onMuteToggle: onMuteToggle,
      );
    }
    // ── Keyboard composer + secondary microphone ────────────────────────────
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            decoration: VisualTutorDecorations.interactionInputField(),
            child: TextField(
              key: const Key('tutor-message-field'),
              controller: controller,
              autofocus: voiceMode && keyboardMode,
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
                        tooltip: AppLocalizations.of(context).submit,
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        if (voiceMode) ...[
          Semantics(
            label: AppLocalizations.of(context).closeKeyboard,
            button: true,
            child: IconButton(
              key: const Key('voice-close-keyboard'),
              tooltip: AppLocalizations.of(context).closeKeyboard,
              onPressed: onKeyboardToggle,
              icon: const Icon(
                Icons.keyboard_hide_rounded,
                color: VisualTutorColors.textSubtle,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        // ── Cyan mic FAB ─────────────────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: voiceMode ? 46 : (compact ? 54 : 58),
          height: voiceMode ? 46 : (compact ? 54 : 58),
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
              disabledBackgroundColor: VisualTutorColors.panel,
              shape: const CircleBorder(),
            ),
            child: Semantics(
              label: isListening
                  ? 'Stop recording your voice response'
                  : 'Record a voice response',
              child: Icon(
                isListening ? Icons.stop_rounded : Icons.mic_rounded,
                size: voiceMode ? 22 : 26,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VoiceFirstDock extends StatelessWidget {
  const _VoiceFirstDock({
    required this.enabled,
    required this.isListening,
    required this.muted,
    required this.onVoiceInput,
    required this.onOpenKeyboard,
    required this.onMuteToggle,
  });

  final bool enabled;
  final bool isListening;
  final bool muted;
  final VoidCallback? onVoiceInput;
  final VoidCallback? onOpenKeyboard;
  final VoidCallback? onMuteToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muteLabel = muted ? l10n.unmuteAudio : l10n.muteAudio;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Semantics(
          label: muteLabel,
          button: true,
          child: IconButton.filledTonal(
            key: const Key('voice-mute-button'),
            tooltip: muteLabel,
            onPressed: onMuteToggle,
            icon: Icon(
              muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            ),
          ),
        ),
        SizedBox(
          width: 78,
          height: 78,
          child: FilledButton(
            key: const Key('voice-response-button'),
            onPressed: enabled ? onVoiceInput : null,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: enabled
                  ? VisualTutorColors.cyan
                  : VisualTutorColors.panel,
              foregroundColor: VisualTutorColors.shell,
              shape: const CircleBorder(),
            ),
            child: Semantics(
              label: isListening ? 'Stop recording' : 'Record',
              child: Icon(
                isListening ? Icons.stop_rounded : Icons.mic_rounded,
                size: 34,
              ),
            ),
          ),
        ),
        Semantics(
          label: l10n.openKeyboard,
          button: true,
          child: IconButton.filledTonal(
            key: const Key('voice-open-keyboard'),
            tooltip: l10n.openKeyboard,
            onPressed: onOpenKeyboard,
            icon: const Icon(Icons.keyboard_rounded),
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
                                    color: VisualTutorColors.cyan.withValues(
                                      alpha: .12,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: VisualTutorColors.cyan.withValues(
                                        alpha: .35,
                                      ),
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
                                    style:
                                        VisualTutorTypography.multiChoiceLabel,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              choice.value,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: VisualTutorTypography.multiChoiceAnswer
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
              boxShadow: enabled && isListening
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

// ── Data class for a single radial action ───────────────────────────────────
class _RadialItem {
  const _RadialItem({
    required this.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final Key key;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
}

// ── Radial action menu ───────────────────────────────────────────────────────
/// A single glowing circle trigger button that expands horizontally into a row
/// of circular icon-buttons when tapped, keeping the teaching board unobscured.
class _RadialActionMenu extends StatefulWidget {
  const _RadialActionMenu({super.key, required this.items});
  final List<_RadialItem> items;

  @override
  State<_RadialActionMenu> createState() => _RadialActionMenuState();
}

class _RadialActionMenuState extends State<_RadialActionMenu>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  void _handleAction(VoidCallback? cb) {
    if (cb == null) return;
    _toggle(); // close menu first
    cb();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Trigger circle ──────────────────────────────────────────────────
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _open
                  ? VisualTutorColors.cyan
                  : VisualTutorColors.cyan.withValues(alpha: .18),
              border: Border.all(
                color: VisualTutorColors.cyan.withValues(alpha: .6),
                width: 1.5,
              ),
              boxShadow: _open
                  ? [
                      BoxShadow(
                        color: VisualTutorColors.cyan.withValues(alpha: .35),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              _open ? Icons.close_rounded : Icons.bolt_rounded,
              color: _open ? VisualTutorColors.shell : VisualTutorColors.cyan,
              size: 22,
            ),
          ),
        ),
        // ── Expanding action buttons ────────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          child: _open
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 10),
                    ...widget.items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return FadeTransition(
                        opacity: _anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(-0.3 * (i + 1), 0),
                            end: Offset.zero,
                          ).animate(_anim),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: _CircleActionButton(
                              key: item.key,
                              icon: item.icon,
                              label: item.label,
                              onPressed: item.onPressed != null
                                  ? () => _handleAction(item.onPressed)
                                  : null,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// A single circular action button with icon + label underneath.
class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return AnimatedOpacity(
      opacity: disabled ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 180),
      child: GestureDetector(
        onTap: disabled ? null : onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VisualTutorColors.shellElevated,
                border: Border.all(
                  color: disabled
                      ? VisualTutorColors.border
                      : VisualTutorColors.cyan.withValues(alpha: .4),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: disabled
                    ? VisualTutorColors.textMuted
                    : VisualTutorColors.cyan,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: disabled
                    ? VisualTutorColors.textMuted
                    : VisualTutorColors.textSubtle,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: .3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A floating radial FAB anchored to the right side of the board.
/// Tap the trigger circle → action buttons fan upward with smooth animation.
class _FloatingRadialFab extends StatefulWidget {
  const _FloatingRadialFab({super.key, required this.items});
  final List<_RadialItem> items;

  @override
  State<_FloatingRadialFab> createState() => _FloatingRadialFabState();
}

class _FloatingRadialFabState extends State<_FloatingRadialFab>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  void _handleAction(VoidCallback? cb) {
    if (cb == null) return;
    setState(() => _open = false);
    _ctrl.reverse();
    cb();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── Expanded action items fanning upward ───────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          child: _open
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ...widget.items
                        .asMap()
                        .entries
                        .map((entry) {
                          final i = entry.key;
                          final item = entry.value;
                          final delay = i * 0.08;
                          final delayedAnim = CurvedAnimation(
                            parent: _ctrl,
                            curve: Interval(
                              delay.clamp(0.0, 0.9),
                              (delay + 0.5).clamp(0.0, 1.0),
                              curve: Curves.easeOutBack,
                            ),
                          );
                          return FadeTransition(
                            opacity: delayedAnim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.5),
                                end: Offset.zero,
                              ).animate(delayedAnim),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _FloatingActionItem(
                                  key: item.key,
                                  icon: item.icon,
                                  label: item.label,
                                  onPressed: item.onPressed != null
                                      ? () => _handleAction(item.onPressed)
                                      : null,
                                ),
                              ),
                            ),
                          );
                        })
                        .toList()
                        .reversed,
                  ],
                )
              : const SizedBox.shrink(),
        ),
        // ── Trigger button ─────────────────────────────────────────────────
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _open ? VisualTutorColors.cyan : const Color(0xFF1A2540),
              border: Border.all(
                color: VisualTutorColors.cyan.withValues(
                  alpha: _open ? 1 : 0.5,
                ),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: VisualTutorColors.cyan.withValues(
                    alpha: _open ? 0.45 : 0.2,
                  ),
                  blurRadius: _open ? 18 : 8,
                  spreadRadius: _open ? 2 : 0,
                ),
              ],
            ),
            child: Icon(
              _open ? Icons.close_rounded : Icons.bolt_rounded,
              color: _open ? const Color(0xFF0D1526) : VisualTutorColors.cyan,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

/// A single item in the floating radial FAB — circle icon + label to the left.
class _FloatingActionItem extends StatelessWidget {
  const _FloatingActionItem({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return GestureDetector(
      onTap: disabled ? null : onPressed,
      child: AnimatedOpacity(
        opacity: disabled ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2540),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: VisualTutorColors.cyan.withValues(
                    alpha: disabled ? 0.15 : 0.35,
                  ),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: disabled
                      ? VisualTutorColors.textMuted
                      : VisualTutorColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Icon circle
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A2540),
                border: Border.all(
                  color: disabled
                      ? VisualTutorColors.border
                      : VisualTutorColors.cyan.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: disabled
                    ? VisualTutorColors.textMuted
                    : VisualTutorColors.cyan,
              ),
            ),
          ],
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
                  tooltip: AppLocalizations.of(context).explainDifferently,
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
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  fontFamilyFallback: VisualTutorTypography.fontFallback,
                ),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).askAnyQuestionHint,
                  hintStyle: const TextStyle(
                    color: Color(0xFF777C91),
                    fontSize: 16,
                    height: 1.40,
                    fontFamilyFallback: VisualTutorTypography.fontFallback,
                  ),
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
