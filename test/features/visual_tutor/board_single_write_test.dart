/// The tutor writes a solution once, and every board of it holds work.
///
/// A streamed turn paints each action as it arrives, and `turn_complete` then
/// delivers the very same actions again. Reported symptom: the board wrote the
/// whole solution from board 1 to board 3, then started over from board 1 and
/// wrote all of it a second time -- after which board 2 was blank.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/data/models/visual_tutor_models.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/domain/repositories/visual_tutor_repository.dart';
import 'package:ai_tutor/screens/learning_selection/learning_selection_repository.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

VisualTutorTurnResponseModel _loadTurn(String fixture) {
  return VisualTutorTurnResponseModel.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(
            File(
              'test/features/visual_tutor/fixtures/$fixture.json',
            ).readAsStringSync(),
          )
          as Map,
    ),
  );
}

/// Audio and microphone plugins have no implementation in a widget test, and
/// they only report that once the real event loop runs.
void _silenceMediaPlugins() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Future<Object?> handle(MethodCall call) async {
    final playerId = call.arguments is Map
        ? (call.arguments as Map)['playerId']
        : null;
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

Future<void> _askTutor(
  WidgetTester tester,
  VisualTutorTurnResponseModel turn,
  String problem,
) async {
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
          repository: _StreamingTurnRepository(turn),
          userId: 'student-1',
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.enterText(find.byKey(const Key('tutor-message-field')), problem);
  await tester.tap(find.byKey(const Key('tutor-send-button')));
}

/// One slice of the lesson playing out. A drained SSE reader only finishes
/// closing on the real event loop, so let that run too.
Future<void> _playSlice(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 1)),
  );
}

void main() {
  testWidgets('a streamed solution is written once, not twice', (tester) async {
    // The phone the student reported this on: tall enough to page the board.
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    _silenceMediaPlugins();

    final turn = _loadTurn('worked_solution_turn');
    await _askTutor(tester, turn, 'lim x->3 (x^2-9)/(x-3)');

    final last = turn.boardActions.last.id;
    bool onBoard(String id) =>
        find.byKey(Key('teaching-board-action-$id')).evaluate().isNotEmpty;

    var everFinished = false;
    var erasedAfterFinishing = false;
    for (var slice = 0; slice < 200; slice++) {
      await _playSlice(tester);
      if (onBoard(last)) {
        everFinished = true;
      } else if (everFinished) {
        erasedAfterFinishing = true;
      }
    }

    expect(everFinished, isTrue, reason: 'the solution never finished');
    expect(
      erasedAfterFinishing,
      isFalse,
      reason: 'the finished answer left the board, so the tutor started over',
    );
  });

  testWidgets('every board of a finished solution has work on it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    _silenceMediaPlugins();

    final turn = _loadTurn('infinity_turn');
    await _askTutor(tester, turn, 'lim x->infinity (3x^2+1)/(2x^2-5)');

    final last = turn.boardActions.last.id;
    for (var slice = 0; slice < 200; slice++) {
      await _playSlice(tester);
      if (find.byKey(Key('teaching-board-action-$last')).evaluate().isNotEmpty) {
        break;
      }
    }

    final switcher = find.byKey(const Key('visual-tutor-board-pages'));
    expect(switcher, findsOneWidget, reason: 'this solution needs more boards');

    // Walk back to board 1, then read forward through every board.
    for (var back = 0; back < 8; back++) {
      final previous = find.byKey(const Key('visual-tutor-board-previous'));
      if (previous.evaluate().isEmpty) break;
      if (tester.widget<IconButton>(previous).onPressed == null) break;
      await tester.tap(previous);
      await tester.pump(const Duration(milliseconds: 400));
    }

    final viewport = tester.getRect(
      find.byKey(const Key('visual-tutor-board-viewport')),
    );
    for (var board = 1; board <= 8; board++) {
      final onThisBoard = find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'teaching-board-action-',
            ),
      );
      final keys = onThisBoard
          .evaluate()
          .map((element) => element.widget.key!)
          .toList();
      expect(
        keys.where(
          (key) => tester.getRect(find.byKey(key)).overlaps(viewport),
        ),
        isNotEmpty,
        reason: 'board $board is blank',
      );
      final next = find.byKey(const Key('visual-tutor-board-next'));
      if (next.evaluate().isEmpty) break;
      if (tester.widget<IconButton>(next).onPressed == null) break;
      await tester.tap(next);
      await tester.pump(const Duration(milliseconds: 400));
    }

    // Let the board's own settle timers finish before the test ends.
    for (var slice = 0; slice < 10; slice++) {
      await _playSlice(tester);
    }
  });
}

class _StreamingTurnRepository
    implements VisualTutorRepository, VisualTutorStreamingRepository {
  _StreamingTurnRepository(this.turn);

  final VisualTutorTurnResponseModel turn;

  @override
  Future<VisualTutorSessionEntity> createSession(
    VisualTutorSessionCreateRequestEntity request,
  ) async {
    return const VisualTutorSessionEntity(
      sessionId: 'session-1',
      userId: 'student-1',
      subject: 'Mathematics',
      topic: 'Limits of Functions',
      metadata: {'board_version': 0, 'base_board_version': 0},
    );
  }

  @override
  Future<VisualTutorSessionEntity> restoreSession(String sessionId) async {
    throw UnimplementedError('the streamed turn must not need a restore');
  }

  @override
  Future<VisualTutorTurnResponseEntity> sendTurn(
    VisualTutorTurnRequestEntity request,
  ) async => turn;

  @override
  Stream<VisualTutorStreamEventEntity> streamTurn(
    VisualTutorTurnRequestEntity request,
  ) async* {
    var sequence = 3;
    // The service writes a live preview line while it is still planning, and
    // the completed turn below does not carry it.
    yield VisualTutorStreamEventEntity(
      eventId: 'event-${sequence++}',
      sequence: sequence,
      type: VisualTutorStreamEventType.boardAction,
      sessionId: 'session-1',
      turnId: turn.turnId,
      boardVersion: 1,
      baseBoardVersion: 0,
      data: const {'provisional': true},
      boardAction: const VisualTutorBoardActionEntity(
        id: 'stream-preview-turn-1',
        type: 'write_text',
        sequenceIndex: 0,
        durationMs: 520,
        sectionId: 'stream-preview',
        text: 'Let us identify the important information first.',
        metadata: {'provisional': true, 'source': 'server_live_preview'},
      ),
    );
    for (final action in turn.boardActions) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      yield VisualTutorStreamEventEntity(
        eventId: 'event-${sequence++}',
        sequence: sequence,
        type: VisualTutorStreamEventType.boardAction,
        sessionId: 'session-1',
        turnId: turn.turnId,
        boardVersion: 1,
        baseBoardVersion: 0,
        data: const {},
        boardAction: action,
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
    yield VisualTutorStreamEventEntity(
      eventId: 'event-${sequence++}',
      sequence: sequence,
      type: VisualTutorStreamEventType.turnComplete,
      sessionId: 'session-1',
      turnId: turn.turnId,
      boardVersion: 1,
      baseBoardVersion: 0,
      data: const {},
      response: turn,
    );
  }
}
