/// Renderer-safe mirror of the AI service teaching-plan schema v1.
///
/// This does not render UI. It lets future Flutter renderers reject an invalid
/// plan before a board action reaches a widget.
enum VisualTutorTeachingRepresentation {
  equationTransformation,
  balanceScale,
  workedExample,
  numberLine,
  coordinateGraph,
  table,
  conceptualExplanation,
  errorAnalysis;

  static VisualTutorTeachingRepresentation? fromWire(String value) {
    const values = {
      'equation_transformation':
          VisualTutorTeachingRepresentation.equationTransformation,
      'balance_scale': VisualTutorTeachingRepresentation.balanceScale,
      'worked_example': VisualTutorTeachingRepresentation.workedExample,
      'number_line': VisualTutorTeachingRepresentation.numberLine,
      'coordinate_graph': VisualTutorTeachingRepresentation.coordinateGraph,
      'table': VisualTutorTeachingRepresentation.table,
      'conceptual_explanation':
          VisualTutorTeachingRepresentation.conceptualExplanation,
      'error_analysis': VisualTutorTeachingRepresentation.errorAnalysis,
    };
    return values[value];
  }
}

class VisualTutorTeachingPlan {
  const VisualTutorTeachingPlan({
    required this.representation,
    required this.learningObjective,
    required this.teachingMessage,
    required this.boardActions,
    required this.allowedStudentActions,
    required this.hiddenAnswerPolicy,
    required this.nextStatePolicy,
  });

  static const schemaVersion = 1;
  final VisualTutorTeachingRepresentation representation;
  final String learningObjective;
  final String teachingMessage;
  final List<Map<String, dynamic>> boardActions;
  final List<String> allowedStudentActions;
  final Map<String, dynamic> hiddenAnswerPolicy;
  final Map<String, dynamic> nextStatePolicy;

  /// Returns null rather than exposing invalid or unsupported AI output to UI.
  static VisualTutorTeachingPlan? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    if (map['schema_version'] != schemaVersion) return null;
    final representation = VisualTutorTeachingRepresentation.fromWire(
      map['representation']?.toString() ?? '',
    );
    final objective = map['learning_objective']?.toString() ?? '';
    final message = map['teaching_message']?.toString() ?? '';
    final actions = _maps(map['board_actions']);
    final allowed = _strings(map['allowed_student_actions']);
    final policy = _map(map['hidden_answer_policy']);
    final next = _map(map['next_state_policy']);
    const allowedPlanKeys = {
      'schema_version',
      'representation',
      'learning_objective',
      'teaching_message',
      'board_actions',
      'allowed_student_actions',
      'hidden_answer_policy',
      'next_state_policy',
    };
    if (map.keys.any((key) => !allowedPlanKeys.contains(key)) ||
        representation == null ||
        !_safeText(objective) ||
        !_safeText(message) ||
        actions.isEmpty ||
        actions.length > 24 ||
        allowed.isEmpty ||
        allowed.length > 8 ||
        policy == null ||
        next == null ||
        !_validPolicy(policy, next)) {
      return null;
    }
    final ids = <String>{};
    final boxes = <({String id, num x, num y, num width, num height})>[];
    var tasks = 0;
    var finalReveal = false;
    for (final action in actions) {
      final id = action['id']?.toString() ?? '';
      final type = action['type']?.toString() ?? '';
      if (!RegExp(r'^[A-Za-z0-9_-]{1,120}$').hasMatch(id) ||
          !ids.add(id) ||
          !_actionTypes.contains(type) ||
          action['sequence_index'] is! int ||
          (action['sequence_index'] as int) < 0 ||
          (action['sequence_index'] as int) > 24 ||
          !_validAction(action, type)) {
        return null;
      }
      if (type == 'student_task') tasks++;
      if (type == 'final_answer_reveal') finalReveal = true;
      const overlays = {
        'highlight',
        'cross_out',
        'draw_arrow',
        'graph_annotation',
        'draw_axes',
        'plot_function',
      };
      if (!overlays.contains(type) &&
          action['x'] is num &&
          action['y'] is num &&
          action['width'] is num &&
          action['height'] is num) {
        final box = (
          id: id,
          x: action['x'] as num,
          y: action['y'] as num,
          width: action['width'] as num,
          height: action['height'] as num,
        );
        final overlaps = boxes.any(
          (other) =>
              box.x < other.x + other.width &&
              box.x + box.width > other.x &&
              box.y < other.y + other.height &&
              box.y + box.height > other.y,
        );
        if (overlaps) return null;
        boxes.add(box);
      }
    }
    if (tasks != 1 ||
        (finalReveal &&
            (policy['mode'] != 'reveal_allowed' ||
                policy['deterministic_policy_permits_final_reveal'] != true))) {
      return null;
    }
    if (!_validTeachingTimeline(actions)) return null;
    return VisualTutorTeachingPlan(
      representation: representation,
      learningObjective: objective.trim(),
      teachingMessage: message.trim(),
      boardActions: actions,
      allowedStudentActions: allowed,
      hiddenAnswerPolicy: policy,
      nextStatePolicy: next,
    );
  }

  /// Repairs individual public actions without widening the renderer contract.
  /// Private verifier fields are ignored, while malformed actions become a
  /// small feedback notice so valid siblings remain part of the lesson.
  static Map<String, dynamic>? recoverPublicPlan(Object? raw) {
    if (raw is! Map) return null;
    final plan = Map<String, dynamic>.from(raw);
    final rawActions = _maps(plan['board_actions']);
    if (rawActions.isEmpty) return null;
    final repaired = <Map<String, dynamic>>[];
    final ids = <String>{};
    Map<String, dynamic>? task;
    for (var index = 0; index < rawActions.length && index < 24; index++) {
      final rawAction = rawActions[index];
      final cleaned = _publicAction(rawAction);
      final type = cleaned['type']?.toString();
      final id = cleaned['id']?.toString() ?? '';
      final valid =
          _hasOnlyPublicOrPrivateActionFields(rawAction) &&
          RegExp(r'^[A-Za-z0-9_-]{1,120}$').hasMatch(id) &&
          ids.add(id) &&
          _actionTypes.contains(type) &&
          cleaned['sequence_index'] is int &&
          (cleaned['sequence_index'] as int) >= 0 &&
          (cleaned['sequence_index'] as int) <= 24 &&
          type != null &&
          _validAction(cleaned, type);
      if (valid && type == 'student_task' && task == null) {
        task = cleaned;
      } else if (valid && type != 'student_task') {
        repaired.add(cleaned);
      } else {
        final noticeId = 'board-recovery-$index';
        ids.add(noticeId);
        repaired.add(_boardRecoveryNotice(noticeId, index));
      }
    }
    task ??= {
      'id': 'board-recovery-task',
      'type': 'student_task',
      'sequence_index': repaired.length.clamp(0, 24) as int,
      'text': 'Please answer the current question or ask for a hint.',
      'requires_student_response': true,
      'task_type': 'conceptual_operation',
      'layout_zone': 'student_task',
      'layout_flow': 'vertical',
    };
    repaired.add(task);
    return {...plan, 'board_actions': repaired};
  }

  static Map<String, dynamic> _publicAction(Map<String, dynamic> action) {
    const allowed = {
      'id',
      'type',
      'sequence_index',
      'duration_ms',
      'wait_for_speech_marker',
      'x',
      'y',
      'width',
      'height',
      'text',
      'latex',
      'target_id',
      'graph',
      'points',
      'label',
      'number_line',
      'table',
      'section_id',
      'layout_zone',
      'layout_flow',
      'requires_student_response',
      'task_type',
      'explanation_required',
      'problem_instance_id',
      'active_step_id',
      'action_id',
      'board_version',
      'base_board_version',
    };
    return {
      for (final entry in action.entries)
        if (allowed.contains(entry.key)) entry.key: entry.value,
    };
  }

  static Map<String, dynamic> _boardRecoveryNotice(String id, int index) => {
    'id': id,
    'type': 'show_feedback',
    'sequence_index': index.clamp(0, 24) as int,
    'text': 'One board item could not be shown. Continue with this step.',
    'layout_zone': 'feedback',
    'layout_flow': 'vertical',
  };

  static bool _hasOnlyPublicOrPrivateActionFields(Map<String, dynamic> action) {
    const known = {
      'id', 'type', 'sequence_index', 'duration_ms',
      'wait_for_speech_marker', 'x', 'y', 'width', 'height', 'text',
      'latex', 'target_id', 'graph', 'points', 'label', 'number_line',
      'table', 'section_id', 'layout_zone', 'layout_flow',
      'requires_student_response', 'task_type', 'explanation_required',
      'problem_instance_id', 'active_step_id', 'action_id', 'board_version',
      'base_board_version',
      // Legal server-side fields which never reach the renderer.
      'accepted_answer_forms', 'expected_operation', 'expected_step', 'hidden',
      'metadata', 'verifier', 'answer', 'answer_key', 'solution',
    };
    return action.keys.every(known.contains);
  }

  static const _actionTypes = {
    'write_text',
    'write_equation',
    'transform_equation',
    'highlight',
    'cross_out',
    'fade_previous',
    'speak_marker',
    'pause_marker',
    'draw_rectangle',
    'circle',
    'draw_arrow',
    'draw_point',
    'show_hint',
    'show_feedback',
    'student_task',
    'show_number_line',
    'draw_axes',
    'show_graph',
    'plot_function',
    'graph_annotation',
    'show_table',
    'final_answer_reveal',
  };
  static const _textTypes = {
    'write_text',
    'write_equation',
    'transform_equation',
    'show_hint',
    'show_feedback',
    'student_task',
    'graph_annotation',
    'final_answer_reveal',
  };
  static final _unsafe = RegExp(
    r'<\s*/?\s*[a-z][^>]*>|\b(?:flutter|dart|javascript|typescript|html|css|svg)\b|\b(?:https?|javascript|data):|\b(?:widget|class|function)\s*\(',
    caseSensitive: false,
  );

  static bool _safeText(String value) =>
      value.trim().isNotEmpty &&
      value.length <= 1000 &&
      !_unsafe.hasMatch(value);
  static Map<String, dynamic>? _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;
  static List<Map<String, dynamic>> _maps(Object? value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : const [];
  static List<String> _strings(Object? value) => value is List
      ? value
            .whereType<String>()
            .where((item) => RegExp(r'^[a-z_]{1,50}$').hasMatch(item))
            .toList()
      : const [];

  static bool _validAction(Map<String, dynamic> action, String type) {
    // The public contract is intentionally narrower than the persisted plan.
    // Expected answers and arbitrary metadata are server-only and must never
    // be carried into a Flutter render model.
    const allowedActionKeys = {
      'id',
      'type',
      'sequence_index',
      'duration_ms',
      'wait_for_speech_marker',
      'x',
      'y',
      'width',
      'height',
      'text',
      'latex',
      'target_id',
      'graph',
      'points',
      'label',
      'number_line',
      'table',
      // Semantic layout is a renderer-safe public contract. Flutter owns the
      // final coordinates, so these cannot carry generated UI code.
      'section_id',
      'layout_zone',
      'layout_flow',
      'requires_student_response',
      'task_type',
      'explanation_required',
      // Schema-v2 public lesson identity. These are safe identifiers only;
      // expected answers and planner metadata remain server-side.
      'problem_instance_id',
      'active_step_id',
      'action_id',
      'board_version',
      'base_board_version',
    };
    if (action.keys.any((key) => !allowedActionKeys.contains(key))) {
      return false;
    }
    for (final key in ['problem_instance_id', 'active_step_id', 'action_id']) {
      final value = action[key];
      if (value != null &&
          (value is! String || value.trim().isEmpty || value.length > 240)) {
        return false;
      }
    }
    for (final key in ['board_version', 'base_board_version']) {
      final value = action[key];
      if (value != null && (value is! int || value < 0)) return false;
    }
    if (action['action_id'] != null && action['action_id'] != action['id']) {
      return false;
    }
    final sectionId = action['section_id'];
    if (sectionId != null &&
        (sectionId is! String ||
            !RegExp(r'^[A-Za-z0-9_-]{1,120}$').hasMatch(sectionId))) {
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
    if (action['layout_zone'] != null &&
        !layoutZones.contains(action['layout_zone'])) {
      return false;
    }
    const layoutFlows = {'vertical', 'horizontal', 'overlay', 'diagram'};
    if (action['layout_flow'] != null &&
        !layoutFlows.contains(action['layout_flow'])) {
      return false;
    }
    final duration = action['duration_ms'] ?? 0;
    if (duration is! int || duration < 0 || duration > 8000) return false;
    if (action['wait_for_speech_marker'] != null &&
        action['wait_for_speech_marker'] is! bool) {
      return false;
    }
    if (type == 'speak_marker' && duration != 0) return false;
    if (type == 'pause_marker' && (duration < 150 || duration > 8000)) {
      return false;
    }
    for (final key in ['x', 'y', 'width', 'height']) {
      final value = action[key];
      if (value != null &&
          (value is! num ||
              !value.isFinite ||
              value.abs() > 10000 ||
              ((key == 'width' || key == 'height') && value <= 0))) {
        return false;
      }
    }
    if (_textTypes.contains(type) &&
        !_safeText((action['text'] ?? action['latex'] ?? '').toString())) {
      return false;
    }
    if ((type == 'show_graph' || type == 'plot_function') &&
        !_validGraph(_map(action['graph']))) {
      return false;
    }
    if (!_validPoints(action['points'])) return false;
    final label = action['label'];
    if (label != null &&
        (label is! String || label.length > 120 || !_safeText(label))) {
      return false;
    }
    if (<String>{'draw_rectangle', 'circle'}.contains(type) &&
        (action['x'] is! num ||
            action['y'] is! num ||
            action['width'] is! num ||
            action['height'] is! num ||
            (action['width'] as num) <= 0 ||
            (action['height'] as num) <= 0)) {
      return false;
    }
    if (type == 'draw_arrow') {
      final hasBox =
          action['x'] is num &&
          action['y'] is num &&
          action['width'] is num &&
          action['height'] is num &&
          (action['width'] as num) > 0 &&
          (action['height'] as num) > 0;
      if (!hasBox &&
          (action['points'] is! List ||
              (action['points'] as List).length < 2)) {
        return false;
      }
    }
    if (type == 'draw_point' && (action['x'] is! num || action['y'] is! num)) {
      return false;
    }
    if (type == 'show_number_line' &&
        !_validNumberLine(_map(action['number_line']))) {
      return false;
    }
    if (type == 'show_table' && !_validTable(_map(action['table']))) {
      return false;
    }
    return type != 'student_task' ||
        (action['hidden'] != true &&
            action['requires_student_response'] == true);
  }

  static bool _validTeachingTimeline(List<Map<String, dynamic>> actions) {
    final ordered = [...actions]
      ..sort(
        (left, right) => (left['sequence_index'] as int).compareTo(
          right['sequence_index'] as int,
        ),
      );
    final hasMarkers = ordered.any(
      (action) =>
          action['type'] == 'speak_marker' || action['type'] == 'pause_marker',
    );
    // Old persisted plans did not have player markers. A newly timeline-aware
    // plan must be complete so the board plays deterministically.
    if (!hasMarkers) return true;
    const visualTypes = {
      'write_text',
      'write_equation',
      'transform_equation',
      'draw_rectangle',
      'circle',
      'draw_arrow',
      'draw_point',
      'show_number_line',
      'draw_axes',
      'show_graph',
      'plot_function',
      'show_table',
      'graph_annotation',
    };
    final indexes = <int>[];
    for (var index = 0; index < ordered.length; index++) {
      if (visualTypes.contains(ordered[index]['type'])) indexes.add(index);
    }
    if (indexes.length > 1) return false;
    if (indexes.isEmpty) return true;
    final visualIndex = indexes.single;
    return ordered
            .take(visualIndex)
            .any((action) => action['type'] == 'speak_marker') &&
        ordered
            .skip(visualIndex + 1)
            .any((action) => action['type'] == 'pause_marker');
  }

  static bool _validGraph(Map<String, dynamic>? graph) {
    if (graph == null) {
      return false;
    }
    const allowedGraphKeys = {
      'x_min',
      'x_max',
      'y_min',
      'y_max',
      'function_expression',
      'points',
      'labels',
      'domain',
      'annotations',
    };
    if (graph.keys.any((key) => !allowedGraphKeys.contains(key))) return false;
    final values = [
      'x_min',
      'x_max',
      'y_min',
      'y_max',
    ].map((key) => graph[key]).toList();
    if (values.any(
      (value) => value is! num || !value.isFinite || value.abs() > 10000,
    )) {
      return false;
    }
    if ((graph['x_min'] as num) >= (graph['x_max'] as num) ||
        (graph['y_min'] as num) >= (graph['y_max'] as num)) {
      return false;
    }
    final labels = graph['labels'];
    if (labels != null &&
        (labels is! List ||
            labels.length > 20 ||
            !labels.every((value) => value is String && _safeText(value)))) {
      return false;
    }
    final annotations = graph['annotations'];
    if (annotations != null &&
        (annotations is! List ||
            annotations.length > 20 ||
            !annotations.every(_validGraphAnnotation))) {
      return false;
    }
    final domain = graph['domain'];
    if (domain != null &&
        (domain is! List ||
            domain.length != 2 ||
            domain.any(
              (value) =>
                  value is! num || !value.isFinite || value.abs() > 10000,
            ) ||
            (domain[0] as num) >= (domain[1] as num))) {
      return false;
    }
    return _safeText(graph['function_expression']?.toString() ?? '') ||
        (graph['points'] is List &&
            (graph['points'] as List).isNotEmpty &&
            _validPoints(graph['points']));
  }

  static bool _validGraphAnnotation(Object? raw) {
    final annotation = _map(raw);
    const allowed = {'text', 'x', 'y'};
    if (annotation == null ||
        annotation.keys.any((key) => !allowed.contains(key))) {
      return false;
    }
    final text = annotation['text'];
    final x = annotation['x'];
    final y = annotation['y'];
    return text is String &&
        text.length <= 240 &&
        _safeText(text) &&
        x is num &&
        y is num &&
        x.isFinite &&
        y.isFinite &&
        x.abs() <= 10000 &&
        y.abs() <= 10000;
  }

  static bool _validPoints(Object? raw) {
    if (raw == null) return true;
    if (raw is! List || raw.length > 100) return false;
    for (final value in raw) {
      final point = _map(value);
      const allowed = {'x', 'y', 'label', 'open'};
      if (point == null || point.keys.any((key) => !allowed.contains(key))) {
        return false;
      }
      for (final key in ['x', 'y']) {
        final coordinate = point[key];
        if (coordinate is! num ||
            !coordinate.isFinite ||
            coordinate.abs() > 10000) {
          return false;
        }
      }
      final label = point['label'];
      if (label != null &&
          (label is! String || label.length > 120 || !_safeText(label)))
        return false;
      if (point['open'] != null && point['open'] is! bool) return false;
    }
    return true;
  }

  static bool _validNumberLine(Map<String, dynamic>? line) {
    const allowed = {'min', 'max', 'step', 'labels'};
    if (line == null || line.keys.any((key) => !allowed.contains(key)))
      return false;
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
              (value) =>
                  value is String && value.length <= 120 && _safeText(value),
            ));
  }

  static bool _validTable(Map<String, dynamic>? table) {
    const allowed = {'columns', 'rows'};
    if (table == null || table.keys.any((key) => !allowed.contains(key)))
      return false;
    final columns = table['columns'];
    final rows = table['rows'];
    bool cell(Object? value) => value is num
        ? value.isFinite && value.abs() <= 10000
        : value is String && value.length <= 160 && _safeText(value);
    return columns is List &&
        columns.isNotEmpty &&
        columns.length <= 6 &&
        columns.every(cell) &&
        rows is List &&
        rows.isNotEmpty &&
        rows.length <= 10 &&
        rows.every(
          (row) =>
              row is List && row.length == columns.length && row.every(cell),
        );
  }

  static bool _validPolicy(
    Map<String, dynamic> answer,
    Map<String, dynamic> next,
  ) {
    if (!{'hidden', 'partial', 'reveal_allowed'}.contains(answer['mode'])) {
      return false;
    }
    const values = {
      'continue',
      'reteach',
      'ask_for_work',
      'offer_practice',
      'reveal_progressively',
      'unsupported_recovery',
    };
    return [
      'correct',
      'invalid',
      'incomplete',
      'stuck',
      'hint',
      'explain_differently',
    ].every((key) => values.contains(next[key]));
  }
}
