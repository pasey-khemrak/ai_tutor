// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

class VisualTutorVoiceRuntime {
  void speak(
    String text, {
    required String languageCode,
    void Function()? onStart,
    void Function()? onEnd,
    void Function()? onError,
  }) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) {
      onEnd?.call();
      return;
    }
    stop();
    final utterance = html.SpeechSynthesisUtterance(cleaned)
      ..lang = languageCode
      ..rate = .94
      ..pitch = 1.03;
    utterance.onStart.listen((_) => onStart?.call());
    utterance.onEnd.listen((_) => onEnd?.call());
    utterance.onError.listen((_) => onError?.call());
    html.window.speechSynthesis?.speak(utterance);
  }

  void stop() {
    try {
      html.window.speechSynthesis?.cancel();
    } catch (_) {
      // Browser speech synthesis is optional.
    }
  }

  void dispose() {
    stop();
  }
}
