import 'dart:async';

import '../../features/visual_tutor/domain/repositories/visual_tutor_repository.dart';

/// Owns the lifetime of the currently displayed tutor stream.
///
/// A new turn always advances [activeSerial] before replacing the iterator.
/// UI code can therefore cheaply reject delayed SSE frames from an older turn
/// without retaining transport concerns in its widget state.
class TutorStreamCoordinator {
  StreamIterator<VisualTutorStreamEventEntity>? _iterator;
  int _activeSerial = 0;

  int get activeSerial => _activeSerial;

  StreamIterator<VisualTutorStreamEventEntity> begin(
    Stream<VisualTutorStreamEventEntity> stream,
  ) {
    final iterator = StreamIterator(stream);
    _iterator = iterator;
    return iterator;
  }

  bool isCurrent(int serial) => serial == _activeSerial;

  void clear(StreamIterator<VisualTutorStreamEventEntity> iterator) {
    if (identical(_iterator, iterator)) _iterator = null;
  }

  /// Invalidates every frame from the previous stream and closes its reader.
  void invalidate() {
    _activeSerial++;
    final iterator = _iterator;
    _iterator = null;
    if (iterator != null) unawaited(iterator.cancel());
  }
}
