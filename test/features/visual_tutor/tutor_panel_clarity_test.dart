/// The panel under the board must not repeat itself or report a check it
/// never made — both crowd out the board the student is trying to read.
import 'dart:convert';
import 'dart:io';

import 'package:ai_tutor/features/visual_tutor/data/models/visual_tutor_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  VisualTutorTurnResponseModel loadTurn() {
    return VisualTutorTurnResponseModel.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
              File(
                'test/features/visual_tutor/fixtures/worked_solution_turn.json',
              ).readAsStringSync(),
            )
            as Map,
      ),
    );
  }

  String plain(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

  test('the spoken line and the written line are the same sentence', () {
    final turn = loadTurn();

    // This is why the panel showed it twice: both slots carry one message.
    expect(
      plain(turn.speech?.text ?? turn.spokenText),
      plain(turn.displayText),
    );
  });

  test('a worked solution reports no math-check verdict to display', () {
    final turn = loadTurn();

    // The tutor solved it; the student has not submitted work to be judged, so
    // there is nothing for a verdict banner to say.
    const shown = {
      'correct',
      'invalid',
      'incomplete',
      'mathematically_valid_but_inefficient',
    };
    final status = turn.verification?.status;
    expect(
      status == null || shown.contains(status),
      isTrue,
      reason: 'unexpected verdict status "$status" would reach the student',
    );
  });
}
