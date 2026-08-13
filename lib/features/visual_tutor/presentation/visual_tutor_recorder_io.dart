import 'dart:io';
import 'dart:typed_data';

import 'package:record/record.dart';

class VisualTutorRecordedAudio {
  const VisualTutorRecordedAudio(this.bytes);
  final Uint8List bytes;
}

class VisualTutorRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  String? _path;

  Future<bool> requestPermission() => _recorder.hasPermission();

  Future<void> start() async {
    _path =
        '${Directory.systemTemp.path}/visual-tutor-${DateTime.now().microsecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _path!,
    );
  }

  Future<VisualTutorRecordedAudio?> stop() async {
    final path = await _recorder.stop() ?? _path;
    _path = null;
    if (path == null) return null;
    final file = File(path);
    try {
      return VisualTutorRecordedAudio(await file.readAsBytes());
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> cancel() async {
    final path = await _recorder.stop() ?? _path;
    _path = null;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> dispose() async {
    await cancel();
    _recorder.dispose();
  }
}
