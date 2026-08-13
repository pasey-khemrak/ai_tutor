import '../domain/entities/visual_tutor_entities.dart';

enum BoardPatchOp { add, update, highlight, fade, focus, hide, reveal, remove }

const _renderableBoardActionTypes = <String>{
  'write_text',
  'write_equation',
  'draw_line',
  'draw_arrow',
  'draw_point',
  'draw_axes',
  'draw_graph_hint',
  'highlight',
  'circle',
  'cross_out',
  'show_graph',
  'show_table',
  'create_blank',
  'fade_previous',
  'clear_section',
  'focus_element',
  'reveal_answer',
  'erase',
  'focus',
  'reveal',
  'hide',
  'pause_marker',
  'speak_marker',
  'update',
  'transform_equation',
  'show_number_line',
  'plot_function',
  'graph_annotation',
  'show_hint',
  'show_feedback',
  'student_task',
};

const visualTutorBoardSchemaVersion = 1;

bool isValidBoardAction(VisualTutorBoardActionEntity action) {
  if (action.id.trim().isEmpty ||
      !_renderableBoardActionTypes.contains(action.type)) {
    return false;
  }
  final numbers = [action.x, action.y, action.width, action.height];
  if (numbers.any(
    (value) => value != null && (!value.isFinite || value.abs() > 10000),
  )) {
    return false;
  }
  if (<String>{
        'write_text',
        'write_equation',
        'transform_equation',
        'graph_annotation',
        'show_hint',
        'show_feedback',
        'student_task',
      }.contains(action.type) &&
      (action.text ?? '').trim().isEmpty &&
      (action.latex ?? '').trim().isEmpty) {
    return false;
  }
  if (<String>{
        'highlight',
        'show_graph',
        'show_table',
        'show_number_line',
        'plot_function',
        'create_blank',
      }.contains(action.type) &&
      (action.width == null ||
          action.height == null ||
          action.width! <= 0 ||
          action.height! <= 0)) {
    return false;
  }
  if (<String>{'show_graph', 'plot_function'}.contains(action.type) &&
      !_isValidGraphPayload(action.graph)) {
    return false;
  }
  return true;
}

bool _isValidGraphPayload(Map<String, dynamic>? graph) {
  if (graph == null) return false;
  double? number(String key) {
    final value = graph[key];
    return value is num ? value.toDouble() : null;
  }

  final xMin = number('x_min');
  final xMax = number('x_max');
  final yMin = number('y_min');
  final yMax = number('y_max');
  if (xMin == null ||
      xMax == null ||
      yMin == null ||
      yMax == null ||
      !xMin.isFinite ||
      !xMax.isFinite ||
      !yMin.isFinite ||
      !yMax.isFinite ||
      xMin.abs() > 10000 ||
      xMax.abs() > 10000 ||
      yMin.abs() > 10000 ||
      yMax.abs() > 10000) {
    return false;
  }
  if (xMin >= xMax || yMin >= yMax) return false;
  final expression = graph['function_expression']?.toString().trim() ?? '';
  final points = graph['points'];
  if (expression.isEmpty && (points is! List || points.isEmpty)) {
    return false;
  }
  if (points is List &&
      points.any((point) {
        if (point is! Map) return true;
        final x = point['x'];
        final y = point['y'];
        return x is! num || y is! num || !x.isFinite || !y.isFinite;
      })) {
    return false;
  }
  return true;
}

BoardPatchOp? boardPatchOpFor(VisualTutorBoardActionEntity action) {
  final explicit = action.metadata['patch_op']?.toString().trim().toLowerCase();
  if (explicit != null && explicit.isNotEmpty) {
    return switch (explicit) {
      'add' => BoardPatchOp.add,
      'update' => BoardPatchOp.update,
      'highlight' => BoardPatchOp.highlight,
      'fade' => BoardPatchOp.fade,
      'focus' => BoardPatchOp.focus,
      'hide' => BoardPatchOp.hide,
      'reveal' => BoardPatchOp.reveal,
      'remove' || 'erase' => BoardPatchOp.remove,
      _ => null,
    };
  }
  return switch (action.type) {
    'highlight' => BoardPatchOp.highlight,
    'fade' || 'fade_previous' => BoardPatchOp.fade,
    'focus' => BoardPatchOp.focus,
    'hide' => BoardPatchOp.hide,
    'reveal' => BoardPatchOp.reveal,
    'erase' => BoardPatchOp.remove,
    _ => null,
  };
}

List<VisualTutorBoardActionEntity> applyVisualTutorBoardPatch(
  List<VisualTutorBoardActionEntity> current,
  List<VisualTutorBoardActionEntity> patchActions,
) {
  final byId = <String, VisualTutorBoardActionEntity>{
    for (final action in current) action.id: action,
  };
  final order = <String>[for (final action in current) action.id];

  void put(VisualTutorBoardActionEntity action) {
    if (!byId.containsKey(action.id)) {
      order.add(action.id);
    }
    byId[action.id] = action;
  }

  for (final patch in patchActions) {
    try {
      final op = boardPatchOpFor(patch);
      final targetId = (patch.targetId == null || patch.targetId!.isEmpty)
          ? patch.id
          : patch.targetId!;
      switch (op) {
        case BoardPatchOp.highlight:
          final existing = byId[targetId];
          if (existing != null) {
            byId[targetId] = existing.copyWith(
              metadata: {...existing.metadata, 'highlighted': true},
            );
          }
        case BoardPatchOp.fade:
          final existing = byId[targetId];
          if (existing != null) {
            byId[targetId] = existing.copyWith(
              metadata: {...existing.metadata, 'faded': true},
            );
          }
        case BoardPatchOp.focus:
          final existing = byId[targetId];
          if (existing != null) {
            final multiFocus = patch.metadata['multi_focus'] == true;
            if (!multiFocus) {
              for (final entry in byId.entries.toList()) {
                byId[entry.key] = entry.value.copyWith(
                  metadata: {...entry.value.metadata, 'focused': false},
                );
              }
            }
            byId[targetId] = existing.copyWith(
              metadata: {...existing.metadata, 'focused': true},
            );
          }
        case BoardPatchOp.hide:
          final existing = byId[targetId];
          if (existing != null) {
            byId[targetId] = existing.copyWith(hidden: true);
          }
        case BoardPatchOp.reveal:
          final existing = byId[targetId];
          if (existing != null) {
            byId[targetId] = existing.copyWith(
              hidden: false,
              metadata: {
                ...existing.metadata,
                if (patch.metadata['preserve_faded'] != true) 'faded': false,
                if (patch.metadata['preserve_highlighted'] != true)
                  'highlighted': false,
              },
            );
          }
        case BoardPatchOp.remove:
          byId.remove(targetId);
          order.remove(targetId);
        case BoardPatchOp.update:
          final existing = byId[targetId];
          if (existing != null) {
            byId[targetId] = mergeBoardAction(existing, patch, id: targetId);
          }
        case BoardPatchOp.add:
        case null:
          put(patch);
      }
    } catch (_) {
      // Patch application is intentionally best-effort; malformed patch actions
      // must never break the tutor surface.
      continue;
    }
  }

  final result = [
    for (final id in order)
      if (byId[id] != null) byId[id]!,
  ];
  result.sort((a, b) {
    final sequence = a.sequenceIndex.compareTo(b.sequenceIndex);
    if (sequence != 0) return sequence;
    return order.indexOf(a.id).compareTo(order.indexOf(b.id));
  });
  return result;
}

VisualTutorBoardActionEntity mergeBoardAction(
  VisualTutorBoardActionEntity existing,
  VisualTutorBoardActionEntity patch, {
  String? id,
}) {
  return existing.copyWith(
    id: id,
    type: patch.type == 'update' ? existing.type : patch.type,
    sequenceIndex: patch.sequenceIndex,
    durationMs: patch.durationMs,
    waitForSpeechMarker: patch.waitForSpeechMarker,
    requiresStudentResponse: patch.requiresStudentResponse,
    groupId: patch.groupId,
    sectionId: patch.sectionId,
    x: patch.x,
    y: patch.y,
    width: patch.width,
    height: patch.height,
    text: patch.text,
    latex: patch.latex,
    points: patch.points.isEmpty ? existing.points : patch.points,
    graph: patch.graph ?? existing.graph,
    targetId: patch.targetId,
    style: patch.style.isEmpty
        ? existing.style
        : {...existing.style, ...patch.style},
    locked: patch.locked,
    hidden: patch.hidden,
    revealPolicy: patch.revealPolicy,
    metadata: {...existing.metadata, ...patch.metadata},
  );
}

bool isRenderableBoardAction(
  VisualTutorBoardActionEntity action, {
  required bool finalAnswerLocked,
}) {
  if (!isValidBoardAction(action)) return false;
  if (action.hidden) return false;
  if (action.locked && finalAnswerLocked) return false;
  if (action.type == 'pause_marker' || action.type == 'speak_marker') {
    return false;
  }
  final hasExplicitPatchOp = action.metadata['patch_op'] != null;
  final op = hasExplicitPatchOp ? boardPatchOpFor(action) : null;
  if (op != null && op != BoardPatchOp.add && op != BoardPatchOp.update) {
    return false;
  }
  return true;
}
