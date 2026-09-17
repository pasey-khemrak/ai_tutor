import '../../../core/network/api_client.dart';

/// Batches bounded operational signals. This type has no fields for lesson
/// text, equations, IDs, errors, or learner evidence by design.
class VisualTutorClientTelemetry {
  VisualTutorClientTelemetry(this._apiClient);
  final ApiClient _apiClient;
  final List<Map<String, Object>> _events = [];

  void action(String lifecycle, {int count = 1}) {
    const allowed = {'received', 'validated', 'queued', 'visible', 'rendered', 'skipped', 'off_screen'};
    if (!allowed.contains(lifecycle)) return;
    _events.add({'kind': 'action_lifecycle', 'lifecycle': lifecycle, 'count': count.clamp(0, 100)});
  }

  void latency(String metric, Duration value) {
    if (metric != 'stream_to_visible' && metric != 'student_to_visible') return;
    _events.add({'kind': 'latency', 'metric': metric, 'duration_ms': value.inMilliseconds.clamp(0, 600000)});
  }

  void outcome(String kind, String outcome) {
    if (!{'board_conflict', 'recovery'}.contains(kind) || !{'success', 'failure', 'conflict'}.contains(outcome)) return;
    _events.add({'kind': kind, 'outcome': outcome});
  }

  Future<void> flush({required String deviceClass, required String viewportBucket, required bool reducedMotion}) async {
    if (_events.isEmpty) return;
    final events = List<Map<String, Object>>.from(_events.take(50));
    _events.removeRange(0, events.length);
    try {
      await _apiClient.post('/tutor/telemetry', body: {
        'events': events,
        'device_class': deviceClass,
        'viewport_bucket': viewportBucket,
        'reduced_motion': reducedMotion,
      });
    } catch (_) {
      // Telemetry is best effort: never delay, fail, or retry the lesson.
    }
  }
}
