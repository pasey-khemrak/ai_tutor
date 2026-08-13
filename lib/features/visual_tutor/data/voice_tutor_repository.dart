// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:typed_data';

import '../../../core/auth/auth_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';

class VoiceTutorRepository {
  VoiceTutorRepository({ApiClient? client})
    : _client =
          client ??
          ApiClient(
            config: AppConfig.current,
            tokenProvider: appAuthService.getAccessToken,
          );
  final ApiClient _client;
  final Set<_CancelableVoiceRequest<dynamic>> _activeRequests = {};

  Future<String> transcribe(Uint8List wavBytes) async {
    if (wavBytes.length < 44 || wavBytes.length > 12 * 1024 * 1024)
      throw const ApiException(
        message: 'Recording is too short or too large',
        statusCode: 413,
      );
    final response = await _withTimeout(
      _client.postBytes(
        '/tutor/voice/transcribe',
        bytes: wavBytes,
        filename: 'recording.wav',
        contentType: 'audio/wav',
      ),
    );
    final data = response['data'] is Map ? response['data'] as Map : response;
    final transcript = data['transcript']?.toString().trim() ?? '';
    if (transcript.isEmpty)
      throw const ApiException(
        message: 'We could not transcribe this recording',
        statusCode: 422,
      );
    return transcript;
  }

  Future<Uint8List> synthesize(String text, {String language = 'en'}) async {
    final clean = text.trim();
    if (clean.isEmpty || clean.length > 4000) {
      throw const ApiException(
        message: 'Tutor speech text is invalid',
        statusCode: 400,
      );
    }
    return _withTimeout(
      _client.postForBytes(
        '/tutor/voice/synthesize',
        body: {'text': clean, 'language': language},
      ),
    );
  }

  Future<T> _withTimeout<T>(Future<T> request) {
    final pending = _CancelableVoiceRequest<T>();
    _activeRequests.add(pending);
    pending.start(request, onDone: () => _activeRequests.remove(pending));
    return pending.future;
  }

  /// Cancels outstanding HTTP work, including the bounded STT/TTS timeout.
  /// Each TutorScreen owns its default repository, so closing it on dispose
  /// prevents an off-screen voice request from keeping browser tests or the
  /// student session alive.
  void close() {
    for (final pending in _activeRequests.toList()) {
      pending.cancel();
    }
    _activeRequests.clear();
    _client.close();
  }
}

class _CancelableVoiceRequest<T> {
  static const _timeout = Duration(seconds: 35);

  final Completer<T> _completer = Completer<T>();
  Timer? _timer;

  Future<T> get future => _completer.future;

  void start(Future<T> request, {required void Function() onDone}) {
    _timer = Timer(_timeout, () {
      if (!_completer.isCompleted) {
        _completer.completeError(
          const ApiException(
            message: 'Voice service timed out',
            statusCode: 504,
          ),
        );
      }
    });
    request
        .then(
          (value) {
            if (!_completer.isCompleted) _completer.complete(value);
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!_completer.isCompleted)
              _completer.completeError(error, stackTrace);
          },
        )
        .whenComplete(() {
          _timer?.cancel();
          onDone();
        });
  }

  void cancel() {
    _timer?.cancel();
    if (!_completer.isCompleted) {
      _completer.completeError(
        const ApiException(message: 'Voice request cancelled', statusCode: 499),
      );
    }
  }
}
