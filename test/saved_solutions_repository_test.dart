import 'package:ai_tutor/features/saved_solutions/saved_solution.dart';
import 'package:ai_tutor/features/saved_solutions/saved_solutions_repository.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _actions = [
  VisualTutorBoardActionEntity(
    id: 'ws-step-step1-0',
    type: 'write_text',
    sequenceIndex: 0,
    durationMs: 450,
    sectionId: 'step-step1',
    layoutZone: 'working',
    layoutFlow: 'vertical',
    text: 'Step 1 · Isolate the variable term.',
    metadata: {'problem_instance_id': 'problem-1'},
  ),
  VisualTutorBoardActionEntity(
    id: 'ws-step-step1-1',
    type: 'write_equation',
    sequenceIndex: 1,
    durationMs: 550,
    sectionId: 'step-step1',
    latex: r'3x + 7 - 7 = 22 - 7',
    style: {'size': 27},
  ),
  VisualTutorBoardActionEntity(
    id: 'ws-answer-2',
    type: 'write_text',
    sequenceIndex: 2,
    text: 'Answer · x = 5',
    graph: {'x_min': -1, 'x_max': 6, 'y_min': -1, 'y_max': 1},
    points: [
      {'x': 5, 'y': 0, 'label': 'x = 5'},
    ],
  ),
];

SavedSolution _solution({String id = 'saved-1'}) => SavedSolution(
  id: id,
  problemText: 'Solve 3x + 7 = 22',
  subject: 'Mathematics',
  topic: 'Linear Equations',
  answerSummary: 'x = 5',
  verificationStatus: 'correct',
  verified: true,
  savedAt: DateTime.utc(2026, 9, 27, 10, 30),
  boardActions: _actions,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('a saved board comes back with every action intact', () async {
    final repository = SavedSolutionsRepository();
    await repository.save(_solution());

    final restored = await repository.loadAll();
    expect(restored, hasLength(1));

    final actions = restored.single.boardActions;
    expect(actions.map((a) => a.id), _actions.map((a) => a.id));
    expect(actions.map((a) => a.type), _actions.map((a) => a.type));
    expect(actions[0].text, 'Step 1 · Isolate the variable term.');
    expect(actions[1].latex, r'3x + 7 - 7 = 22 - 7');
    expect(actions[1].style['size'], 27);
    expect(actions[1].sectionId, 'step-step1');
    expect(actions[0].durationMs, 450);
    expect(actions[0].metadata['problem_instance_id'], 'problem-1');
    expect(actions[2].graph, isNotNull);
    expect(actions[2].graph!['x_max'], 6);
    expect(actions[2].points.single['label'], 'x = 5');
  });

  test('the verification verdict survives, so the chip cannot lie later', () async {
    final repository = SavedSolutionsRepository();
    await repository.save(_solution());
    await repository.save(
      SavedSolution(
        id: 'saved-2',
        problemText: 'Find the domain of f(x) = 1/(x-3)',
        subject: 'Mathematics',
        topic: 'Functions',
        answerSummary: 'all reals except x = 3',
        verificationStatus: 'cannot_verify',
        verified: false,
        savedAt: DateTime.utc(2026, 9, 27, 11),
        boardActions: _actions,
      ),
    );

    final all = await repository.loadAll();
    final byId = {for (final item in all) item.id: item};
    expect(byId['saved-1']!.verified, isTrue);
    expect(byId['saved-1']!.verificationStatus, 'correct');
    expect(byId['saved-2']!.verified, isFalse);
    expect(byId['saved-2']!.verificationStatus, 'cannot_verify');
  });

  test('newest is listed first', () async {
    final repository = SavedSolutionsRepository();
    await repository.save(
      _solution(id: 'older').copyWith(savedAt: DateTime.utc(2026, 9, 1)),
    );
    await repository.save(
      _solution(id: 'newer').copyWith(savedAt: DateTime.utc(2026, 9, 26)),
    );

    final all = await repository.loadAll();
    expect(all.map((item) => item.id), ['newer', 'older']);
  });

  test('saving the same problem twice replaces it rather than duplicating', () async {
    final repository = SavedSolutionsRepository();
    await repository.save(_solution());
    await repository.save(_solution().copyWith(answerSummary: 'x = 5 (rechecked)'));

    final all = await repository.loadAll();
    expect(all, hasLength(1));
    expect(all.single.answerSummary, 'x = 5 (rechecked)');
  });

  test('a student can remove one', () async {
    final repository = SavedSolutionsRepository();
    await repository.save(_solution());
    await repository.remove('saved-1');
    expect(await repository.loadAll(), isEmpty);
  });

  test('the store is bounded so it cannot grow without limit', () async {
    final repository = SavedSolutionsRepository();
    for (var i = 0; i < SavedSolutionsRepository.maxEntries + 6; i++) {
      await repository.save(
        _solution(id: 'saved-$i').copyWith(
          savedAt: DateTime.utc(2026, 1, 1).add(Duration(minutes: i)),
        ),
      );
    }

    final all = await repository.loadAll();
    expect(all, hasLength(SavedSolutionsRepository.maxEntries));
    // The oldest entries are the ones dropped.
    expect(all.first.id, 'saved-${SavedSolutionsRepository.maxEntries + 5}');
    expect(all.map((item) => item.id), isNot(contains('saved-0')));
  });

  test('unreadable stored data yields an empty list rather than throwing', () async {
    SharedPreferences.setMockInitialValues({
      SavedSolutionsRepository.storageKey: 'not json at all',
    });
    expect(await SavedSolutionsRepository().loadAll(), isEmpty);
  });

  test('an exported solution is readable text a student can paste', () async {
    final text = _solution().toShareText();
    expect(text, contains('Solve 3x + 7 = 22'));
    expect(text, contains('Step 1 · Isolate the variable term.'));
    expect(text, contains(r'3x + 7 - 7 = 22 - 7'));
    expect(text, contains('x = 5'));
    expect(text.trim(), isNotEmpty);
  });
}
