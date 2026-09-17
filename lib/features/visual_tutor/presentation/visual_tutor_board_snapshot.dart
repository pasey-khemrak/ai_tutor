import 'dart:ui';

import '../domain/entities/visual_tutor_entities.dart';
import 'live_board_state.dart';

/// Device-persisted presentation state for one student board.
///
/// This is deliberately separate from the server-authoritative lesson state:
/// it stores only renderer state and student ink. AI actions remain validated
/// data and are checked again before a snapshot can restore them.
class VisualTutorBoardSnapshot {
  const VisualTutorBoardSnapshot({
    required this.sessionId,
    required this.boardStateId,
    required this.actions,
    this.schemaVersion = currentSchemaVersion,
    this.visibleActionIds = const [],
    this.hiddenActionIds = const [],
    this.fadedActionIds = const [],
    this.focusedActionId,
    this.studentInk = const [],
    this.playheadIndex = 0,
    this.playbackPaused = false,
    this.viewport = const VisualTutorBoardViewport(),
  });

  static const currentSchemaVersion = 2;
  static const _maxActions = 120;
  static const _maxStrokes = 200;
  static const _maxPointsPerStroke = 1000;

  final int schemaVersion;
  final String sessionId;
  final String boardStateId;
  final List<VisualTutorBoardActionEntity> actions;
  final List<String> visibleActionIds;
  final List<String> hiddenActionIds;
  final List<String> fadedActionIds;
  final String? focusedActionId;
  final List<VisualTutorStudentInkStroke> studentInk;
  final int playheadIndex;
  final bool playbackPaused;
  final VisualTutorBoardViewport viewport;

  /// Corrupt, unsafe, or unknown future snapshots are ignored by callers.
  /// Version one is migrated into the current value object without playback.
  static VisualTutorBoardSnapshot? tryFromJson(Object? raw) {
    try {
      if (raw is! Map) return null;
      final json = Map<String, dynamic>.from(raw);
      final version = json['schema_version'];
      if (version is! int || version < 1 || version > currentSchemaVersion) {
        return null;
      }
      final sessionId = _id(json['session_id']);
      final boardStateId = _id(json['board_state_id']);
      if (sessionId == null || boardStateId == null) return null;
      final rawActions = json['actions'];
      if (rawActions is! List || rawActions.length > _maxActions) return null;
      final actions = <VisualTutorBoardActionEntity>[];
      for (final rawAction in rawActions) {
        final action = _action(rawAction);
        if (action == null || !isValidBoardAction(action)) return null;
        actions.add(action);
      }
      final ids = actions.map((action) => action.id).toSet();
      if (ids.length != actions.length) return null;

      final boardState = json['board_state'] is Map
          ? Map<String, dynamic>.from(json['board_state'] as Map)
          : const <String, dynamic>{};
      final visible = _ids(boardState['visible_action_ids'], ids);
      final hidden = _ids(boardState['hidden_action_ids'], ids);
      final faded = _ids(boardState['faded_action_ids'], ids);
      final focused = _nullableId(boardState['focused_action_id'], ids);
      final ink = _ink(json['student_ink']);
      if (ink == null) return null;
      final playback = json['playback'] is Map
          ? Map<String, dynamic>.from(json['playback'] as Map)
          : const <String, dynamic>{};
      final playhead = playback['playhead_index'] is int
          ? playback['playhead_index'] as int
          : 0;
      if (playhead < 0 || playhead > actions.length) return null;
      final paused = playback['is_paused'] is bool
          ? playback['is_paused'] as bool
          : false;
      final viewport = VisualTutorBoardViewport.tryFromJson(json['viewport']);
      if (viewport == null) return null;
      return VisualTutorBoardSnapshot(
        schemaVersion: currentSchemaVersion,
        sessionId: sessionId,
        boardStateId: boardStateId,
        actions: actions,
        visibleActionIds: visible,
        hiddenActionIds: hidden,
        fadedActionIds: faded,
        focusedActionId: focused,
        studentInk: ink,
        // Restore is always instant. The saved position is retained for an
        // explicit replay UI, never used to silently resume animation.
        playheadIndex: playhead,
        playbackPaused: paused,
        viewport: viewport,
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'schema_version': currentSchemaVersion,
    'session_id': sessionId,
    'board_state_id': boardStateId,
    'actions': actions.map(_actionJson).toList(growable: false),
    'board_state': {
      'visible_action_ids': visibleActionIds,
      'hidden_action_ids': hiddenActionIds,
      'faded_action_ids': fadedActionIds,
      if (focusedActionId != null) 'focused_action_id': focusedActionId,
    },
    'student_ink': studentInk
        .map((stroke) => stroke.toJson())
        .toList(growable: false),
    'playback': {'playhead_index': playheadIndex, 'is_paused': playbackPaused},
    'viewport': viewport.toJson(),
  };

  static VisualTutorBoardActionEntity? _action(Object? raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    final id = _id(json['id']);
    final type = json['type'];
    final sequence = json['sequence_index'];
    if (id == null || type is! String || sequence is! int || sequence < 0) {
      return null;
    }
    double? number(String key, {bool positive = false}) {
      final value = json[key];
      if (value == null) {
        return null;
      }
      if (value is! num ||
          !value.isFinite ||
          value.abs() > 10000 ||
          (positive && value <= 0)) {
        return double.nan;
      }
      return value.toDouble();
    }

    final x = number('x');
    final y = number('y');
    final width = number('width', positive: true);
    final height = number('height', positive: true);
    if ([x, y, width, height].any((value) => value?.isNaN == true)) {
      return null;
    }
    final duration = json['duration_ms'] ?? 0;
    if (duration is! int || duration < 0 || duration > 8000) return null;
    final points = _maps(json['points']);
    if (points == null) return null;
    return VisualTutorBoardActionEntity(
      id: id,
      type: type,
      sequenceIndex: sequence,
      durationMs: duration,
      waitForSpeechMarker: json['wait_for_speech_marker'] == true,
      requiresStudentResponse: json['requires_student_response'] == true,
      groupId: _text(json['group_id']),
      sectionId: _text(json['section_id']),
      x: x,
      y: y,
      width: width,
      height: height,
      text: _text(json['text']),
      latex: _text(json['latex']),
      points: points,
      graph: json['graph'] is Map
          ? Map<String, dynamic>.from(json['graph'] as Map)
          : null,
      targetId: _text(json['target_id']),
      style: json['style'] is Map
          ? Map<String, dynamic>.from(json['style'] as Map)
          : const {},
      locked: json['locked'] == true,
      hidden: json['hidden'] == true,
      revealPolicy: _text(json['reveal_policy']),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
    );
  }

  static Map<String, dynamic> _actionJson(
    VisualTutorBoardActionEntity action,
  ) => {
    'id': action.id,
    'type': action.type,
    'sequence_index': action.sequenceIndex,
    'duration_ms': action.durationMs,
    'wait_for_speech_marker': action.waitForSpeechMarker,
    'requires_student_response': action.requiresStudentResponse,
    if (action.groupId != null) 'group_id': action.groupId,
    if (action.sectionId != null) 'section_id': action.sectionId,
    if (action.x != null) 'x': action.x,
    if (action.y != null) 'y': action.y,
    if (action.width != null) 'width': action.width,
    if (action.height != null) 'height': action.height,
    if (action.text != null) 'text': action.text,
    if (action.latex != null) 'latex': action.latex,
    if (action.points.isNotEmpty) 'points': action.points,
    if (action.graph != null) 'graph': action.graph,
    if (action.targetId != null) 'target_id': action.targetId,
    if (action.style.isNotEmpty) 'style': action.style,
    'locked': action.locked,
    'hidden': action.hidden,
    if (action.revealPolicy != null) 'reveal_policy': action.revealPolicy,
    if (action.metadata.isNotEmpty) 'metadata': action.metadata,
  };

  static String? _id(Object? value) =>
      value is String && RegExp(r'^[A-Za-z0-9_-]{1,120}$').hasMatch(value)
      ? value
      : null;
  static String? _text(Object? value) =>
      value is String && value.length <= 1000 ? value : null;
  static List<String> _ids(Object? value, Set<String> allowed) => value is List
      ? value
            .whereType<String>()
            .where(allowed.contains)
            .toSet()
            .toList(growable: false)
      : const [];
  static String? _nullableId(Object? value, Set<String> allowed) =>
      value is String && allowed.contains(value) ? value : null;
  static List<Map<String, dynamic>>? _maps(Object? value) {
    if (value == null) return const [];
    if (value is! List || value.length > 100) return null;
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static List<VisualTutorStudentInkStroke>? _ink(Object? value) {
    if (value == null) return const [];
    if (value is! List || value.length > _maxStrokes) return null;
    final strokes = <VisualTutorStudentInkStroke>[];
    for (final rawStroke in value) {
      final stroke = VisualTutorStudentInkStroke.tryFromJson(
        rawStroke,
        maxPoints: _maxPointsPerStroke,
      );
      if (stroke == null) return null;
      strokes.add(stroke);
    }
    return strokes;
  }
}

class VisualTutorStudentInkStroke {
  const VisualTutorStudentInkStroke(this.points);
  final List<Offset> points;

  static VisualTutorStudentInkStroke? tryFromJson(
    Object? raw, {
    required int maxPoints,
  }) {
    if (raw is! Map || raw['points'] is! List) return null;
    final values = raw['points'] as List;
    if (values.isEmpty || values.length > maxPoints) return null;
    final points = <Offset>[];
    for (final value in values) {
      if (value is! Map || value['x'] is! num || value['y'] is! num) {
        return null;
      }
      final x = (value['x'] as num).toDouble();
      final y = (value['y'] as num).toDouble();
      if (!x.isFinite || !y.isFinite || x.abs() > 10000 || y.abs() > 10000) {
        return null;
      }
      points.add(Offset(x, y));
    }
    return VisualTutorStudentInkStroke(points);
  }

  Map<String, dynamic> toJson() => {
    'points': points
        .map((point) => {'x': point.dx, 'y': point.dy})
        .toList(growable: false),
  };
}

class VisualTutorBoardViewport {
  const VisualTutorBoardViewport({
    this.scale = 1,
    this.translateX = 0,
    this.translateY = 0,
  });
  final double scale;
  final double translateX;
  final double translateY;

  static VisualTutorBoardViewport? tryFromJson(Object? raw) {
    if (raw == null) return const VisualTutorBoardViewport();
    if (raw is! Map) return null;
    double? number(String key, double fallback) {
      final value = raw[key] ?? fallback;
      if (value is! num || !value.isFinite || value.abs() > 10000) return null;
      return value.toDouble();
    }

    final scale = number('scale', 1);
    final x = number('translate_x', 0);
    final y = number('translate_y', 0);
    if (scale == null || x == null || y == null || scale < 1 || scale > 3) {
      return null;
    }
    return VisualTutorBoardViewport(scale: scale, translateX: x, translateY: y);
  }

  Map<String, dynamic> toJson() => {
    'scale': scale,
    'translate_x': translateX,
    'translate_y': translateY,
  };
}
