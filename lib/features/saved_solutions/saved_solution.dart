import '../visual_tutor/domain/entities/visual_tutor_entities.dart';

/// A finished board a student chose to keep.
///
/// The board actions are stored already normalized, exactly as the renderer
/// holds them, so reopening one paints the same solution without asking the
/// planner or the LLM for anything.
class SavedSolution {
  const SavedSolution({
    required this.id,
    required this.problemText,
    required this.subject,
    required this.topic,
    required this.answerSummary,
    required this.verificationStatus,
    required this.verified,
    required this.savedAt,
    required this.boardActions,
  });

  final String id;
  final String problemText;
  final String subject;
  final String topic;

  /// The tutor's closing line, shown in the list so a student recognises it.
  final String answerSummary;

  /// Kept alongside the board so the chip on a reopened solution reports what
  /// was actually true when it was solved, never a fresh guess.
  final String verificationStatus;
  final bool verified;

  final DateTime savedAt;
  final List<VisualTutorBoardActionEntity> boardActions;

  SavedSolution copyWith({
    String? id,
    String? problemText,
    String? subject,
    String? topic,
    String? answerSummary,
    String? verificationStatus,
    bool? verified,
    DateTime? savedAt,
    List<VisualTutorBoardActionEntity>? boardActions,
  }) => SavedSolution(
    id: id ?? this.id,
    problemText: problemText ?? this.problemText,
    subject: subject ?? this.subject,
    topic: topic ?? this.topic,
    answerSummary: answerSummary ?? this.answerSummary,
    verificationStatus: verificationStatus ?? this.verificationStatus,
    verified: verified ?? this.verified,
    savedAt: savedAt ?? this.savedAt,
    boardActions: boardActions ?? this.boardActions,
  );

  /// The worked solution as plain text, for a student who wants it outside the
  /// app — pasted into notes, or sent to a classmate.
  String toShareText() {
    final lines = <String>[problemText.trim(), ''];
    for (final action in boardActions) {
      final text = action.text?.trim();
      final latex = action.latex?.trim();
      if (text != null && text.isNotEmpty) lines.add(text);
      if (latex != null && latex.isNotEmpty) lines.add('    $latex');
    }
    if (answerSummary.trim().isNotEmpty) {
      lines
        ..add('')
        ..add(answerSummary.trim());
    }
    return lines.join('\n');
  }

  Map<String, dynamic> toStoredJson() => {
    'id': id,
    'problem_text': problemText,
    'subject': subject,
    'topic': topic,
    'answer_summary': answerSummary,
    'verification_status': verificationStatus,
    'verified': verified,
    'saved_at': savedAt.toUtc().toIso8601String(),
    'board_actions': boardActions.map(encodeBoardAction).toList(),
  };

  static SavedSolution? fromStoredJson(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final id = map['id'];
    final savedAt = DateTime.tryParse('${map['saved_at']}');
    if (id is! String || id.isEmpty || savedAt == null) return null;
    final rawActions = map['board_actions'];
    return SavedSolution(
      id: id,
      problemText: '${map['problem_text'] ?? ''}',
      subject: '${map['subject'] ?? ''}',
      topic: '${map['topic'] ?? ''}',
      answerSummary: '${map['answer_summary'] ?? ''}',
      verificationStatus: '${map['verification_status'] ?? 'cannot_verify'}',
      verified: map['verified'] == true,
      savedAt: savedAt,
      boardActions: rawActions is List
          ? rawActions
                .map(decodeBoardAction)
                .whereType<VisualTutorBoardActionEntity>()
                .toList(growable: false)
          : const [],
    );
  }
}

/// Writes the renderer's own entity fields.
///
/// Deliberately not the wire contract's `fromJson`, which normalizes number
/// lines, tables and molecule points into metadata. These actions are already
/// normalized, so re-running that would be lossy.
Map<String, dynamic> encodeBoardAction(VisualTutorBoardActionEntity action) => {
  'id': action.id,
  'type': action.type,
  'sequence_index': action.sequenceIndex,
  'duration_ms': action.durationMs,
  'wait_for_speech_marker': action.waitForSpeechMarker,
  'requires_student_response': action.requiresStudentResponse,
  if (action.groupId != null) 'group_id': action.groupId,
  if (action.sectionId != null) 'section_id': action.sectionId,
  if (action.layoutZone != null) 'layout_zone': action.layoutZone,
  if (action.layoutFlow != null) 'layout_flow': action.layoutFlow,
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

VisualTutorBoardActionEntity? decodeBoardAction(Object? raw) {
  if (raw is! Map) return null;
  final map = Map<String, dynamic>.from(raw);
  final id = map['id'];
  final type = map['type'];
  if (id is! String || id.isEmpty || type is! String || type.isEmpty) {
    return null;
  }
  return VisualTutorBoardActionEntity(
    id: id,
    type: type,
    sequenceIndex: _int(map['sequence_index']),
    durationMs: _int(map['duration_ms']),
    waitForSpeechMarker: map['wait_for_speech_marker'] == true,
    requiresStudentResponse: map['requires_student_response'] == true,
    groupId: _string(map['group_id']),
    sectionId: _string(map['section_id']),
    layoutZone: _string(map['layout_zone']),
    layoutFlow: _string(map['layout_flow']),
    x: _double(map['x']),
    y: _double(map['y']),
    width: _double(map['width']),
    height: _double(map['height']),
    text: _string(map['text']),
    latex: _string(map['latex']),
    points: _mapList(map['points']),
    graph: map['graph'] is Map
        ? Map<String, dynamic>.from(map['graph'] as Map)
        : null,
    targetId: _string(map['target_id']),
    style: map['style'] is Map
        ? Map<String, dynamic>.from(map['style'] as Map)
        : const {},
    locked: map['locked'] == true,
    hidden: map['hidden'] == true,
    revealPolicy: _string(map['reveal_policy']),
    metadata: map['metadata'] is Map
        ? Map<String, dynamic>.from(map['metadata'] as Map)
        : const {},
  );
}

int _int(Object? value) => value is num ? value.toInt() : 0;
double? _double(Object? value) => value is num ? value.toDouble() : null;
String? _string(Object? value) => value is String && value.isNotEmpty
    ? value
    : null;
List<Map<String, dynamic>> _mapList(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false)
    : const [];
