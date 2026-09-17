import '../domain/entities/visual_tutor_entities.dart';

/// Privacy-safe lifecycle states for declarative board actions. These events
/// intentionally contain no tutor text, equations, or student input.
enum BoardActionLifecycle {
  received,
  schemaValid,
  queued,
  visible,
  rendered,
  skipped,
}

class BoardActionDiagnostic {
  const BoardActionDiagnostic({
    required this.actionId,
    required this.lifecycle,
    this.reason,
  });

  final String actionId;
  final BoardActionLifecycle lifecycle;
  final String? reason;
}

typedef BoardActionDiagnosticListener =
    void Function(BoardActionDiagnostic diagnostic);

enum BoardPatchOp { add, update, highlight, fade, focus, hide, reveal, remove }

const _renderableBoardActionTypes = <String>{
  'write_text',
  'write_equation',
  'draw_line',
  'draw_rectangle',
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
  'final_answer_reveal',
  'draw_free_body_diagram',
  'draw_molecule',
  'draw_wave',
  'draw_atom_model',
  'draw_particle_diagram',
  'draw_circuit_diagram',
  'show_reaction_layout',
};

// These actions mutate existing board state and deliberately have no visual
// widget of their own. They are valid in a patch, but must not be treated as a
// drawable action in a complete teaching frame.
const _boardControlActionTypes = <String>{
  // Legacy graph hints have no deterministic primitive; the backend should
  // send show_graph/plot_function instead.
  'draw_graph_hint',
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
};

const visualTutorBoardSchemaVersion = 1;

/// Determines how long a streamed action waits before it is added to the
/// provisional board. The typed contract is authoritative; legacy metadata is
/// considered only when a visible action has no typed duration.
int streamedBoardRevealDelayMs(VisualTutorBoardActionEntity action) {
  final isMarker =
      action.type == 'speak_marker' || action.type == 'pause_marker';
  if (isMarker) return action.durationMs.clamp(0, 8000).toInt();
  final legacyDuration = action.metadata['duration_ms'];
  final fallback = legacyDuration is int ? legacyDuration : 400;
  final requested = action.durationMs > 0 ? action.durationMs : fallback;
  return requested.clamp(150, 1200).toInt();
}

/// A live preview line the service writes while it is still planning. The
/// completed turn does not carry it, so it is a presentation hint and never
/// part of the board's content.
bool isProvisionalBoardAction(VisualTutorBoardActionEntity action) =>
    action.metadata['provisional'] == true;

/// The board widget is rebuilt from nothing whenever its identity changes, and
/// a rebuilt board writes every action again from the first line. Streaming
/// paints each action as it arrives and `turn_complete` then delivers the same
/// actions a second time, so the identity has to survive that hand-off: it may
/// change only when the arriving board drops something already written.
bool boardIdentityMustChange({
  required Iterable<String> renderedActionIds,
  required Iterable<String> nextActionIds,
}) {
  final next = nextActionIds.toSet();
  return renderedActionIds.any((actionId) => !next.contains(actionId));
}

/// A provisional streamed action is safe to queue only for the exact board
/// snapshot that requested it. This prevents delayed events from an old turn
/// appearing after retry, cancellation, or a newer board response.
bool isCurrentStreamedBoardAction({
  required int requestBoardVersion,
  required int currentBoardVersion,
  required int? eventBoardVersion,
  required int? eventBaseBoardVersion,
}) {
  return eventBaseBoardVersion == requestBoardVersion &&
      currentBoardVersion == requestBoardVersion &&
      eventBoardVersion != null &&
      eventBoardVersion >= currentBoardVersion;
}

bool isValidBoardAction(VisualTutorBoardActionEntity action) {
  if (!RegExp(r'^[A-Za-z0-9_-]{1,120}$').hasMatch(action.id) ||
      !_renderableBoardActionTypes.contains(action.type)) {
    return false;
  }
  if (action.sequenceIndex < 0 ||
      action.sequenceIndex > 10000 ||
      action.durationMs < 0 ||
      action.durationMs > 8000) {
    return false;
  }
  if (action.type == 'pause_marker' &&
      (action.durationMs < 150 || action.durationMs > 8000)) {
    return false;
  }
  if (action.type == 'speak_marker' && action.durationMs != 0) return false;
  if (action.targetId != null &&
      !RegExp(r'^[A-Za-z0-9_-]{1,120}$').hasMatch(action.targetId!)) {
    return false;
  }
  const layoutZones = {
    'problem',
    'working',
    'visual',
    'student_task',
    'reference',
    'feedback',
  };
  const layoutFlows = {'vertical', 'horizontal', 'overlay', 'diagram'};
  final usesSemanticLayout = action.layoutZone != null;
  if (usesSemanticLayout && !layoutZones.contains(action.layoutZone)) {
    return false;
  }
  if (action.layoutFlow != null && !layoutFlows.contains(action.layoutFlow)) {
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
        'final_answer_reveal',
      }.contains(action.type) &&
      (action.text ?? '').trim().isEmpty &&
      (action.latex ?? '').trim().isEmpty) {
    return false;
  }
  if (<String>{'draw_rectangle', 'circle'}.contains(action.type) &&
      !usesSemanticLayout &&
      (action.x == null ||
          action.y == null ||
          action.width == null ||
          action.height == null ||
          action.width! <= 0 ||
          action.height! <= 0)) {
    return false;
  }
  if (action.type == 'draw_arrow') {
    final hasBox =
        action.x != null &&
        action.y != null &&
        action.width != null &&
        action.height != null &&
        action.width! > 0 &&
        action.height! > 0;
    if (!usesSemanticLayout && !hasBox && action.points.length < 2) {
      return false;
    }
  }
  if (action.type == 'draw_point' &&
      !usesSemanticLayout &&
      (action.x == null || action.y == null)) {
    return false;
  }
  if (!_isValidPoints(action.points)) return false;
  // Legacy actions carried number-line/table data in graph/metadata. Keep
  // accepting those persisted sessions; newly decoded public actions use the
  // typed, normalized values above.
  if (action.type == 'show_number_line' &&
      action.metadata['number_line'] != null &&
      !_isValidNumberLine(action.metadata['number_line'])) {
    return false;
  }
  if (action.type == 'show_table' &&
      action.metadata['table'] != null &&
      !_isValidTable(action.metadata['table'])) {
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
      !usesSemanticLayout &&
      (action.width == null ||
          action.height == null ||
          action.width! <= 0 ||
          action.height! <= 0)) {
    return false;
  }
  if (action.type == 'final_answer_reveal' && action.hidden) return false;
  if (<String>{'show_graph', 'plot_function'}.contains(action.type) &&
      !_isValidGraphPayload(action.graph)) {
    return false;
  }
  if (action.type == 'draw_free_body_diagram' &&
      !_isValidForces(action.metadata['forces'])) {
    return false;
  }
  if (action.type == 'draw_atom_model' &&
      !_isValidAtomModel(action.metadata['atom_model'])) {
    return false;
  }
  if (action.type == 'draw_particle_diagram' &&
      !_isValidParticleDiagram(action.metadata['particle_diagram'])) {
    return false;
  }
  if (action.type == 'draw_circuit_diagram' &&
      !_isValidCircuitDiagram(action.metadata['circuit_diagram'])) {
    return false;
  }
  if (action.type == 'show_reaction_layout' &&
      !_isValidReactionLayout(action.metadata['reaction_layout'])) {
    return false;
  }
  return true;
}

bool _isValidForces(Object? raw) =>
    raw is List &&
    raw.isNotEmpty &&
    raw.length <= 8 &&
    raw.every(
      (force) =>
          force is Map &&
          force.keys.every((key) => key == 'direction' || key == 'label') &&
          const {'up', 'down', 'left', 'right'}.contains(force['direction']) &&
          force['label'] is String &&
          (force['label'] as String).isNotEmpty &&
          (force['label'] as String).length <= 80,
    );

bool _isValidAtomModel(Object? raw) {
  if (raw is! Map ||
      raw.keys.any(
        (key) =>
            key != 'symbol' &&
            key != 'protons' &&
            key != 'neutrons' &&
            key != 'electrons_per_shell',
      )) {
    return false;
  }
  final shells = raw['electrons_per_shell'];
  return raw['symbol'] is String &&
      RegExp(r'^[A-Z][a-z]?$').hasMatch(raw['symbol'] as String) &&
      raw['protons'] is int &&
      (raw['protons'] as int) >= 1 &&
      (raw['protons'] as int) <= 118 &&
      raw['neutrons'] is int &&
      (raw['neutrons'] as int) >= 0 &&
      (raw['neutrons'] as int) <= 180 &&
      shells is List &&
      shells.isNotEmpty &&
      shells.length <= 7 &&
      shells.every((shell) => shell is int && shell >= 0 && shell <= 32);
}

bool _isValidParticleDiagram(Object? raw) =>
    raw is Map &&
    raw.keys.every(
      (key) =>
          key == 'state' || key == 'particle_count' || key == 'particle_label',
    ) &&
    const {'solid', 'liquid', 'gas'}.contains(raw['state']) &&
    raw['particle_count'] is int &&
    (raw['particle_count'] as int) >= 1 &&
    (raw['particle_count'] as int) <= 36 &&
    raw['particle_label'] is String &&
    (raw['particle_label'] as String).isNotEmpty &&
    (raw['particle_label'] as String).length <= 80;

bool _isValidCircuitDiagram(Object? raw) {
  if (raw is! Map ||
      raw.keys.any((key) => key != 'components') ||
      raw['components'] is! List) {
    return false;
  }
  final components = raw['components'] as List;
  return components.length >= 2 &&
      components.length <= 6 &&
      components.every(
        (component) =>
            component is Map &&
            component.keys.every((key) => key == 'kind' || key == 'label') &&
            const {
              'cell',
              'resistor',
              'lamp',
              'switch',
            }.contains(component['kind']) &&
            (component['label'] == null ||
                component['label'] is String &&
                    (component['label'] as String).length <= 80),
      ) &&
      components.any((component) => component['kind'] == 'cell');
}

bool _isValidReactionLayout(Object? raw) {
  if (raw is! Map ||
      raw.keys.any(
        (key) =>
            key != 'reactants' && key != 'products' && key != 'coefficients',
      )) {
    return false;
  }
  final reactants = raw['reactants'];
  final products = raw['products'];
  final coefficients = raw['coefficients'];
  return reactants is List &&
      products is List &&
      reactants.isNotEmpty &&
      products.isNotEmpty &&
      reactants.length <= 4 &&
      products.length <= 4 &&
      [...reactants, ...products].every(
        (formula) =>
            formula is String && formula.isNotEmpty && formula.length <= 80,
      ) &&
      (coefficients == null ||
          coefficients is List &&
              coefficients.length == reactants.length + products.length &&
              coefficients.every(
                (value) => value is int && value >= 1 && value <= 99,
              ));
}

bool _isValidPoints(List<Map<String, dynamic>> points) {
  if (points.length > 100) return false;
  for (final point in points) {
    const allowed = {'x', 'y', 'label', 'open'};
    if (point.keys.any((key) => !allowed.contains(key))) return false;
    final x = point['x'];
    final y = point['y'];
    if (x is! num ||
        y is! num ||
        !x.isFinite ||
        !y.isFinite ||
        x.abs() > 10000 ||
        y.abs() > 10000) {
      return false;
    }
    final label = point['label'];
    if (label != null && (label is! String || label.length > 120)) return false;
    if (point['open'] != null && point['open'] is! bool) return false;
  }
  return true;
}

bool _isValidNumberLine(Object? raw) {
  if (raw is! Map) return false;
  final line = Map<String, dynamic>.from(raw);
  const allowed = {'min', 'max', 'step', 'labels'};
  if (line.keys.any((key) => !allowed.contains(key))) return false;
  final min = line['min'];
  final max = line['max'];
  final step = line['step'];
  if (min is! num ||
      max is! num ||
      step is! num ||
      !min.isFinite ||
      !max.isFinite ||
      !step.isFinite ||
      min.abs() > 10000 ||
      max.abs() > 10000 ||
      step <= 0 ||
      min >= max) {
    return false;
  }
  final labels = line['labels'];
  return labels == null ||
      (labels is List &&
          labels.length <= 20 &&
          labels.every(
            (item) =>
                item is String && item.trim().isNotEmpty && item.length <= 120,
          ));
}

bool _isValidTable(Object? raw) {
  if (raw is! Map) return false;
  final table = Map<String, dynamic>.from(raw);
  const allowed = {'columns', 'rows'};
  if (table.keys.any((key) => !allowed.contains(key))) return false;
  final columns = table['columns'];
  final rows = table['rows'];
  bool validCell(Object? value) => value is num
      ? value.isFinite && value.abs() <= 10000
      : value is String && value.trim().isNotEmpty && value.length <= 160;
  return columns is List &&
      columns.isNotEmpty &&
      columns.length <= 6 &&
      columns.every(validCell) &&
      rows is List &&
      rows.isNotEmpty &&
      rows.length <= 10 &&
      rows.every(
        (row) =>
            row is List && row.length == columns.length && row.every(validCell),
      );
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
  if (action.type == 'final_answer_reveal' && finalAnswerLocked) return false;
  if (action.type == 'pause_marker' || action.type == 'speak_marker') {
    return false;
  }
  if (_boardControlActionTypes.contains(action.type)) return false;
  final hasExplicitPatchOp = action.metadata['patch_op'] != null;
  final op = hasExplicitPatchOp ? boardPatchOpFor(action) : null;
  if (op != null && op != BoardPatchOp.add && op != BoardPatchOp.update) {
    return false;
  }
  return true;
}
