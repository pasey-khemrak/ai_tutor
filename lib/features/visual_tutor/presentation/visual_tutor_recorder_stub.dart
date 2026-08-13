import 'dart:typed_data';

class VisualTutorRecordedAudio {
  const VisualTutorRecordedAudio(this.bytes);
  final Uint8List bytes;
}

class VisualTutorRecorder {
  Future<bool> requestPermission() async => false;
  Future<void> start() =>
      throw UnsupportedError('Audio recording is unavailable in this browser.');
  Future<VisualTutorRecordedAudio?> stop() async => null;
  Future<void> cancel() async {}
  Future<void> dispose() async {}
}
