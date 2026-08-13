class VisualTutorVoiceRuntime {
  void speak(
    String text, {
    required String languageCode,
    void Function()? onStart,
    void Function()? onEnd,
    void Function()? onError,
  }) {
    onError?.call();
  }

  void stop() {}

  void dispose() {}
}
