import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ai_tutor/core/localization/app_language_controller.dart';
import 'package:ai_tutor/core/localization/app_localizations.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/data/models/visual_tutor_models.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/domain/repositories/visual_tutor_repository.dart';
import 'package:ai_tutor/screens/learning_selection/learning_selection_repository.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

VisualTutorTurnResponseModel _loadTurn(String fixture) {
  return VisualTutorTurnResponseModel.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(
            File('test/features/visual_tutor/fixtures/$fixture.json')
                .readAsStringSync(),
          ) as Map,
    ),
  );
}

void _silenceMediaPlugins() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Future<Object?> handle(MethodCall call) async {
    final playerId = call.arguments is Map ? (call.arguments as Map)['playerId'] : null;
    if (playerId is String) {
      messenger.setMockStreamHandler(
        EventChannel('xyz.luan/audioplayers/events/$playerId'),
        MockStreamHandler.inline(onListen: (arguments, sink) {}),
      );
    }
    return null;
  }

  for (final channel in const [
    'xyz.luan/audioplayers.global',
    'xyz.luan/audioplayers',
    'com.llfbandit.record/messages',
  ]) {
    messenger.setMockMethodCallHandler(MethodChannel(channel), handle);
  }
  messenger.setMockStreamHandler(
    const EventChannel('xyz.luan/audioplayers.global/events'),
    MockStreamHandler.inline(onListen: (arguments, sink) {}),
  );
}

Future<void> _playSlice(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 1)),
  );
}

class _TwoTurnJourneyRepository
    implements VisualTutorRepository, VisualTutorStreamingRepository {
  _TwoTurnJourneyRepository({required this.turn1, required this.turn2});

  final VisualTutorTurnResponseModel turn1;
  final VisualTutorTurnResponseModel turn2;

  int callCount = 0;
  final List<String> restoredSessions = [];
  final List<VisualTutorTurnRequestEntity> sentTurns = [];

  @override
  Future<VisualTutorSessionEntity> createSession(
    VisualTutorSessionCreateRequestEntity request,
  ) async {
    return const VisualTutorSessionEntity(
      sessionId: 'session-journey-1',
      userId: 'student-1',
      subject: 'Mathematics',
      topic: 'Limits of Functions',
      problemText: r'\lim_{x \to 3} \frac{x^2 - 9}{x - 3}',
      metadata: {'board_version': 0, 'base_board_version': 0},
    );
  }

  @override
  Future<VisualTutorSessionEntity> restoreSession(String sessionId) async {
    restoredSessions.add(sessionId);
    return VisualTutorSessionEntity(
      sessionId: sessionId,
      userId: 'student-1',
      subject: 'Mathematics',
      topic: 'Limits of Functions',
      problemText: r'\lim_{x \to 3} \frac{x^2 - 9}{x - 3}',
      normalizedProblem: r'\lim_{x \to 3} \frac{x^2 - 9}{x - 3}',
      currentStepIndex: 3,
      hintCount: 0,
      wrongAttempts: 0,
      metadata: const {
        'board_version': 2,
        'base_board_version': 1,
      },
    );
  }

  @override
  Future<VisualTutorTurnResponseEntity> sendTurn(
    VisualTutorTurnRequestEntity request,
  ) async {
    sentTurns.add(request);
    callCount++;
    return callCount == 1 ? turn1 : turn2;
  }

  @override
  Stream<VisualTutorStreamEventEntity> streamTurn(
    VisualTutorTurnRequestEntity request,
  ) async* {
    sentTurns.add(request);
    callCount++;
    final activeTurn = callCount == 1 ? turn1 : turn2;
    var sequence = 1;

    yield VisualTutorStreamEventEntity(
      eventId: 'event-${sequence++}',
      sequence: sequence,
      type: VisualTutorStreamEventType.boardAction,
      sessionId: 'session-journey-1',
      turnId: activeTurn.turnId,
      boardVersion: callCount,
      baseBoardVersion: callCount - 1,
      data: const {'provisional': true},
      boardAction: const VisualTutorBoardActionEntity(
        id: 'stream-preview-turn',
        type: 'write_text',
        sequenceIndex: 0,
        durationMs: 400,
        sectionId: 'stream-preview',
        text: 'Let us identify the important information first.',
        metadata: {'provisional': true, 'source': 'server_live_preview'},
      ),
    );

    for (final action in activeTurn.boardActions) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      yield VisualTutorStreamEventEntity(
        eventId: 'event-${sequence++}',
        sequence: sequence,
        type: VisualTutorStreamEventType.boardAction,
        sessionId: 'session-journey-1',
        turnId: activeTurn.turnId,
        boardVersion: callCount,
        baseBoardVersion: callCount - 1,
        data: const {},
        boardAction: action,
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 10));
    yield VisualTutorStreamEventEntity(
      eventId: 'event-${sequence++}',
      sequence: sequence,
      type: VisualTutorStreamEventType.turnComplete,
      sessionId: 'session-journey-1',
      turnId: activeTurn.turnId,
      boardVersion: callCount,
      baseBoardVersion: callCount - 1,
      data: const {},
      response: activeTurn,
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLanguageController.setLanguage('en');
  });

  group('Full Student Journey & Fragile Joins', () {
    testWidgets(
      'phone layout: solution writes once -> paging -> follow-up appends history without wiping',
      (tester) async {
        tester.view.physicalSize = const Size(430, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        _silenceMediaPlugins();

        final turn1 = _loadTurn('worked_solution_turn');

        // Turn 2 is a follow-up answer about factoring (x^2 - 9).
        // Server sends the follow-up section with board_update_mode: 'replace'.
        final followUpAction = VisualTutorBoardActionEntity(
          id: 'ws-reply-why_factor-15',
          type: 'write_text',
          sequenceIndex: 15,
          durationMs: 500,
          sectionId: 'reply-why_factor',
          text: 'We factor x^2 - 9 into (x-3)(x+3) to cancel the zero denominator.',
        );
        final nextTaskAction = VisualTutorBoardActionEntity(
          id: 'ws-next-16',
          type: 'student_task',
          sequenceIndex: 16,
          durationMs: 0,
          sectionId: 'next',
          text: 'Does that explain why we factored it?',
          requiresStudentResponse: true,
        );

        final turn2 = VisualTutorTurnResponseModel(
          turnId: 'turn-2',
          sessionId: 'session-journey-1',
          screenState: 'asking_question',
          tutorStatus: 'Waiting for you',
          spokenText: 'We factor x^2 - 9 to cancel the factor that causes 0/0.',
          displayText: 'We factor x^2 - 9 to cancel the factor that causes 0/0.',
          teachingMode: 'full_solution',
          finalAnswerLocked: false,
          studentTask: 'Does that explain why we factored it?',
          board: turn1.board,
          boardActions: [
            ...turn1.boardActions.where((a) => a.type != 'student_task'),
            followUpAction,
            nextTaskAction,
          ],
          speech: const VisualTutorSpeechEntity(
            text: 'We factor x^2 - 9 to cancel the factor that causes 0/0.',
            language: 'en',
          ),
          interaction: turn1.interaction,
          allowedActions: turn1.allowedActions,
          quickActions: turn1.quickActions,
          metadata: {
            ...turn1.metadata,
            'board_version': 2,
            'base_board_version': 1,
            'board_update_mode': 'replace', // The server sends replace!
            'problem_text': r'\lim_{x \to 3} \frac{x^2 - 9}{x - 3}',
          },
        );

        final repository = _TwoTurnJourneyRepository(turn1: turn1, turn2: turn2);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: TutorScreen(
                context: const LearningContext(
                  grade: 12,
                  subject: 'Mathematics',
                  topic: 'Limits of Functions',
                ),
                repository: repository,
                userId: 'student-1',
              ),
            ),
          ),
        );
        await tester.pump();

        // 1. Submit initial problem
        await tester.enterText(
          find.byKey(const Key('tutor-message-field')),
          r'\lim_{x \to 3} \frac{x^2 - 9}{x - 3}',
        );
        await tester.tap(find.byKey(const Key('tutor-send-button')));

        // 2. Stream plays out: verify single write
        final lastActionId1 = turn1.boardActions.last.id;
        for (var i = 0; i < 150; i++) {
          await _playSlice(tester);
          if (find.byKey(Key('teaching-board-action-$lastActionId1')).evaluate().isNotEmpty) {
            break;
          }
        }
        expect(
          find.byKey(Key('teaching-board-action-$lastActionId1')),
          findsOneWidget,
          reason: 'Initial turn actions completed on whiteboard',
        );

        // 3. Board pagination: walk back and forward
        final switcher = find.byKey(const Key('visual-tutor-board-pages'));
        if (switcher.evaluate().isNotEmpty) {
          final previous = find.byKey(const Key('visual-tutor-board-previous'));
          if (previous.evaluate().isNotEmpty && tester.widget<IconButton>(previous).onPressed != null) {
            await tester.tap(previous);
            await tester.pump(const Duration(milliseconds: 300));
            final next = find.byKey(const Key('visual-tutor-board-next'));
            await tester.tap(next);
            await tester.pump(const Duration(milliseconds: 300));
          }
        }

        // 4. Ask a follow-up question
        await tester.enterText(
          find.byKey(const Key('tutor-message-field')),
          'Why did you factor x^2 - 9?',
        );
        await tester.tap(find.byKey(const Key('tutor-send-button')));

        // Let the follow-up stream and complete
        for (var i = 0; i < 150; i++) {
          await _playSlice(tester);
          if (find.byKey(const Key('teaching-board-action-ws-reply-why_factor-15')).evaluate().isNotEmpty) {
            break;
          }
        }

        // Verify follow-up reply was appended to board
        expect(
          find.byKey(const Key('teaching-board-action-ws-reply-why_factor-15')),
          findsOneWidget,
          reason: 'Follow-up reply is visible on the whiteboard',
        );

        // Verify earlier steps were NOT erased: walk back to Board 1 and verify
        for (var back = 0; back < 8; back++) {
          final previous = find.byKey(const Key('visual-tutor-board-previous'));
          if (previous.evaluate().isEmpty) break;
          if (tester.widget<IconButton>(previous).onPressed == null) break;
          await tester.tap(previous);
          await tester.pump(const Duration(milliseconds: 400));
        }
        for (var slice = 0; slice < 10; slice++) {
          await _playSlice(tester);
        }

        final onBoard = find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith('teaching-board-action-'),
        );
        expect(onBoard, findsWidgets, reason: 'Earlier solution steps are preserved in board history on Board 1');
        expect(
          find.byKey(const Key('teaching-board-action-ws-step-read-0')),
          findsWidgets,
          reason: 'Step 0 is preserved in board history on Board 1',
        );
      },
    );

    testWidgets('tablet rotation mid-lesson safely re-paginates without blank board', (tester) async {
      // 1. Start in tablet portrait (768 x 1024)
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      _silenceMediaPlugins();

      final turn1 = _loadTurn('infinity_turn');
      final repository = _TwoTurnJourneyRepository(turn1: turn1, turn2: turn1);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: TutorScreen(
              context: const LearningContext(
                grade: 12,
                subject: 'Mathematics',
                topic: 'Limits of Functions',
              ),
              repository: repository,
              userId: 'student-1',
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('tutor-message-field')),
        'lim x->infinity (3x^2+1)/(2x^2-5)',
      );
      await tester.tap(find.byKey(const Key('tutor-send-button')));

      final lastId = turn1.boardActions.last.id;
      for (var i = 0; i < 150; i++) {
        await _playSlice(tester);
        if (find.byKey(Key('teaching-board-action-$lastId')).evaluate().isNotEmpty) {
          break;
        }
      }

      // 2. Rotate tablet to landscape (1024 x 768)
      tester.view.physicalSize = const Size(1024, 768);
      await tester.pump(const Duration(milliseconds: 300));
      for (var i = 0; i < 5; i++) {
        await _playSlice(tester);
      }

      // Viewport remains valid and has work on it
      final viewport = tester.getRect(
        find.byKey(const Key('visual-tutor-board-viewport')),
      );
      expect(viewport.width, greaterThan(0));
      expect(viewport.height, greaterThan(0));

      final onBoard = find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith('teaching-board-action-'),
      );
      expect(onBoard, findsWidgets, reason: 'Board has visible content after rotation');
    });

    testWidgets('desktop wide layout renders board alongside side controls', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      _silenceMediaPlugins();

      final turn = _loadTurn('worked_solution_turn');
      final repository = _TwoTurnJourneyRepository(turn1: turn, turn2: turn);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: TutorScreen(
              context: const LearningContext(
                grade: 12,
                subject: 'Mathematics',
                topic: 'Limits of Functions',
              ),
              repository: repository,
              userId: 'student-1',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('visual-tutor-canvas-board')), findsOneWidget);
      expect(find.byKey(const Key('tutor-message-field')), findsOneWidget);
    });

    testWidgets('language switching mid-lesson updates locale and requests correctly', (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      _silenceMediaPlugins();

      final turn = _loadTurn('worked_solution_turn');
      final repository = _TwoTurnJourneyRepository(turn1: turn, turn2: turn);
      addTearDown(() => AppLanguageController.setLanguage('km'));

      await tester.pumpWidget(
        ValueListenableBuilder<Locale>(
          valueListenable: AppLanguageController.currentLocale,
          builder: (context, locale, _) => MaterialApp(
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.dark(),
            home: Scaffold(
              body: TutorScreen(
                context: const LearningContext(
                  grade: 12,
                  subject: 'Mathematics',
                  topic: 'Limits of Functions',
                ),
                repository: repository,
                userId: 'student-1',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state is English
      expect(AppLanguageController.isKhmer, isFalse);

      // Toggle language
      AppLanguageController.toggleLanguage();
      await tester.pumpAndSettle();

      expect(AppLanguageController.isKhmer, isTrue);

      // Submit a question in Khmer
      await tester.enterText(
        find.byKey(const Key('tutor-message-field')),
        'សូមពន្យល់ជំហាននេះ',
      );
      await tester.tap(find.byKey(const Key('tutor-send-button')));

      final lastId = turn.boardActions.last.id;
      for (var i = 0; i < 150; i++) {
        await _playSlice(tester);
        if (find.byKey(Key('teaching-board-action-$lastId')).evaluate().isNotEmpty) {
          break;
        }
      }
      for (var i = 0; i < 5; i++) {
        await _playSlice(tester);
      }

      // The sent request carried the toggled Khmer language mode
      expect(repository.sentTurns.last.languageMode, 'khmer');
    });

    testWidgets('leaving the app and resuming restores persisted session', (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      _silenceMediaPlugins();

      final turn = _loadTurn('worked_solution_turn');
      final repository = _TwoTurnJourneyRepository(turn1: turn, turn2: turn);

      // Open screen with an existing initialSessionId
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: TutorScreen(
              context: const LearningContext(
                grade: 12,
                subject: 'Mathematics',
                topic: 'Limits of Functions',
                lessonId: 'math.g12.lesson1.limits-of-functions',
              ),
              initialSessionId: 'persisted-student-session-42',
              repository: repository,
              userId: 'student-1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that the persisted session was restored without creating a new session
      expect(repository.restoredSessions, ['persisted-student-session-42']);
      expect(find.byKey(const Key('visual-tutor-canvas-board')), findsOneWidget);
    });
  });
}
