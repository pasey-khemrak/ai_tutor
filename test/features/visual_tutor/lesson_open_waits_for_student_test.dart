/// Opening a lesson must not answer a question the student has not asked.
///
/// Tapping "Learn this topic" used to submit the lesson's starter problem
/// immediately, so a student who had typed nothing landed on a finished board
/// with the finalanswer already on it. That is the one thing this tutor is
/// built not to do: the whole model is that the answer stays locked until the
/// student reaches it, and the deck says so.
///
/// The starter problem should be waiting in the input box instead, so opening
/// a topic offers the problem and the student chooses to start it.
library;

import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/domain/repositories/visual_tutor_repository.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records whether the screen asked the server for anything.
class _RecordingRepository implements VisualTutorRepository {
  final List<String> submitted = [];
  int sessionsCreated = 0;

  @override
  Future<VisualTutorSessionEntity> createSession(
    VisualTutorSessionCreateRequestEntity request,
  ) async {
    sessionsCreated++;
    return VisualTutorSessionEntity(
      sessionId: 'test-session',
      userId: request.userId,
      subject: request.subject,
      topic: request.topic,
    );
  }

  @override
  Future<VisualTutorSessionEntity> restoreSession(String sessionId) async {
    return VisualTutorSessionEntity(
      sessionId: sessionId,
      userId: 'student-1',
      subject: 'Mathematics',
      topic: 'Quadratics',
    );
  }

  @override
  Future<VisualTutorTurnResponseEntity> sendTurn(
    VisualTutorTurnRequestEntity request,
  ) async {
    submitted.add(request.message);
    return const VisualTutorTurnResponseEntity(
      turnId: 't1',
      sessionId: 'test-session',
      spokenText: 'unused',
      displayText: 'unused',
      teachingMode: 'step_check',
      finalAnswerLocked: true,
      studentTask: 'unused',
      board: VisualTutorBoardEntity(type: 'equation_steps', items: []),
    );
  }
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _silenceMediaPlugins();
  });
  const starter = r'x^2 - 5x + 6 = 0, find the roots';

  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.dark(),
    home: Scaffold(body: child),
  );

  /// The tutor screen lays out a board, a dock and a chat column, so it needs
  /// a realistic surface; the default test window is too small for it.
  void useDesktopSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('opening a topic offers the starter problem without solving it', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final repository = _RecordingRepository();
    await tester.pumpWidget(
      wrap(
        TutorScreen(
          repository: repository,
          userId: 'student-1',
          initialPrefill: starter,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      repository.submitted,
      isEmpty,
      reason: 'the tutor answered a problem the student never sent',
    );

    // The problem is waiting for them, so opening the topic still tells them
    // what it is about and starting it is one tap.
    final field = tester.widget<TextField>(
      find.byKey(const Key('tutor-message-field')),
    );
    expect(field.controller?.text, starter);
  });

  testWidgets('an explicit submission still runs on open', (tester) async {
    // Typing a question on the dashboard, or picking a problem, is the student
    // acting. That path must keep working exactly as before.
    useDesktopSurface(tester);
    final repository = _RecordingRepository();
    await tester.pumpWidget(
      wrap(
        TutorScreen(
          repository: repository,
          userId: 'student-1',
          initialSubmission: const VisualTutorStudentSubmission(
            message: 'Solve 2x + 3 = 9',
            intent: 'new_problem',
            action: 'submit_problem',
            inputType: 'text',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.submitted, contains('Solve 2x + 3 = 9'));
  });
}
