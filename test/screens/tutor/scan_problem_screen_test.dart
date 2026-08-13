import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

import 'package:ai_tutor/features/visual_tutor/data/scan_problem_repository.dart';
import 'package:ai_tutor/screens/tutor/scan_problem_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class _ScanRepository extends ScanProblemRepository {
  _ScanRepository(this.handler);

  final Future<ScanProblemResult> Function() handler;

  @override
  Future<ScanProblemResult> scan({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) => handler();
}

Future<XFile> _validImage() async {
  return XFile.fromData(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLx4QAAAABJRU5ErkJggg==',
    ),
    name: 'visible-problem.png',
    mimeType: 'image/png',
  );
}

ScanProblemResult _result() => const ScanProblemResult(
  detectedText: 'ដោះស្រាយ 2x + 5 = 15',
  confidence: .91,
  language: 'mixed',
  mathExpressionCandidates: ['2x + 5 = 15'],
);

Widget _screen({
  required ScanProblemRepository repository,
  required Future<XFile?> Function(ImageSource) picker,
  Future<void> Function()? processingStarter,
}) => MaterialApp(
  home: ScanProblemScreen(
    repository: repository,
    imagePicker: picker,
    imageValidator: (_) async {},
    processingStarter: processingStarter,
  ),
);

Future<void> _chooseCamera(WidgetTester tester) async {
  await tester.tap(find.text('Use camera'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows a clear permission-denied recovery state', (tester) async {
    await tester.pumpWidget(
      _screen(
        repository: _ScanRepository(() async => _result()),
        picker: (_) async => throw Exception('permission denied'),
      ),
    );

    await _chooseCamera(tester);

    expect(find.byKey(const Key('scan-permission-denied')), findsOneWidget);
    expect(find.text('Choose photo'), findsOneWidget);
  });

  testWidgets('shows a local preview before it uploads an image', (tester) async {
    final image = await _validImage();
    await tester.pumpWidget(
      _screen(
        repository: _ScanRepository(() async => _result()),
        picker: (_) async => image,
      ),
    );

    await _chooseCamera(tester);

    expect(find.byKey(const Key('scan-preview')), findsOneWidget);
    expect(find.text('Read question'), findsOneWidget);
  });

  testWidgets('shows uploading before OCR processing begins', (tester) async {
    final image = await _validImage();
    final beginProcessing = Completer<void>();
    await tester.pumpWidget(
      _screen(
        repository: _ScanRepository(() async => _result()),
        picker: (_) async => image,
        processingStarter: () => beginProcessing.future,
      ),
    );
    await _chooseCamera(tester);
    await tester.tap(find.text('Read question'));
    await tester.pump();
    expect(find.byKey(const Key('scan-uploading')), findsOneWidget);

    beginProcessing.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('shows processing then editable correction and never creates a session', (tester) async {
    final image = await _validImage();
    final response = Completer<ScanProblemResult>();
    await tester.pumpWidget(
      _screen(
        repository: _ScanRepository(() => response.future),
        picker: (_) async => image,
      ),
    );
    await _chooseCamera(tester);

    await tester.tap(find.text('Read question'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const Key('scan-processing')), findsOneWidget);

    response.complete(_result());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scan-editable-correction')), findsOneWidget);
    expect(find.textContaining('OCR text, not solved or normalized math'), findsOneWidget);
    expect(find.byKey(const Key('scan-detected-text')), findsOneWidget);
    expect(find.text('Start tutoring'), findsOneWidget);
  });

  testWidgets('shows an unreadable-image state with retry and retake', (tester) async {
    final image = await _validImage();
    await tester.pumpWidget(
      _screen(
        repository: _ScanRepository(
          () async => throw const ScanProblemException(
            code: 'UNREADABLE_IMAGE',
            message: 'No visible question',
          ),
        ),
        picker: (_) async => image,
      ),
    );
    await _chooseCamera(tester);
    await tester.tap(find.text('Read question'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('scan-unreadable-image')), findsOneWidget);
    expect(find.text('Retry this image'), findsOneWidget);
    expect(find.text('Retake'), findsOneWidget);
  });

  testWidgets('shows AI-unavailable and generic failure states with retry', (tester) async {
    final image = await _validImage();
    final outcomes = <Object>[
      const ScanProblemException(code: 'AI_UNAVAILABLE', message: 'Unavailable'),
      const ScanProblemException(code: 'SCAN_FAILED', message: 'Failed'),
    ];
    var attempt = 0;
    await tester.pumpWidget(
      _screen(
        repository: _ScanRepository(() async => throw outcomes[attempt++]),
        picker: (_) async => image,
      ),
    );
    await _chooseCamera(tester);
    await tester.tap(find.text('Read question'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scan-ai-unavailable')), findsOneWidget);

    await tester.tap(find.text('Retry this image'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scan-failure')), findsOneWidget);
    expect(find.text('Retry this image'), findsOneWidget);
  });
}
