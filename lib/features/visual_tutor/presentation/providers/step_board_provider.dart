import 'package:flutter/foundation.dart';

import '../../domain/entities/visual_tutor_entities.dart';
import '../../domain/repositories/visual_tutor_repository.dart';

/// Holds one subject-expert lesson sequence and its submit/loading state.
class StepBoardProvider extends ChangeNotifier {
  StepBoardProvider({required VisualTutorStepRepository repository})
    : _repository = repository;

  final VisualTutorStepRepository _repository;
  VisualTutorStepTurnResponseEntity? _response;
  bool _isLoading = false;
  String? _error;
  String _userId = '';

  VisualTutorStepTurnResponseEntity? get response => _response;
  VisualTutorStepEntity? get currentStep => _response?.currentStep;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentStepNumber => (_response?.currentStepIndex ?? 0) + 1;
  int get totalSteps => _response?.totalSteps ?? 0;

  Future<void> load({
    required String userId,
    required String sessionId,
    required String subject,
  }) {
    _userId = userId;
    return _send(
      VisualTutorStepTurnRequestEntity(
        userId: userId,
        sessionId: sessionId,
        subject: subject,
      ),
    );
  }

  Future<void> submit(String answer) => _submitWithAction('submit', answer);
  Future<void> requestHint() => _submitWithAction('hint', '');
  Future<void> skip() => _submitWithAction('skip', '');

  Future<void> _submitWithAction(String action, String message) async {
    final current = _response;
    if (current == null) return;
    await _send(
      VisualTutorStepTurnRequestEntity(
        userId: _userId,
        sessionId: current.sessionId,
        subject: current.subject,
        stepId: current.currentStep.stepId,
        message: message.trim(),
        action: action,
      ),
    );
  }

  Future<void> _send(VisualTutorStepTurnRequestEntity request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _response = await _repository.submitStepResponse(request);
    } catch (_) {
      _error = 'Unable to load the next teaching step. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
