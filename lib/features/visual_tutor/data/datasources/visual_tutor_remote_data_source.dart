import '../../../../core/network/api_client.dart';
import '../models/visual_tutor_models.dart';

class VisualTutorRemoteDataSource {
  const VisualTutorRemoteDataSource({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<VisualTutorSessionModel> createSession(
    VisualTutorSessionCreateRequestModel request,
  ) async {
    final json = await _apiClient.post(
      '/tutor/sessions',
      body: request.toJson(),
    );
    return VisualTutorSessionModel.fromJson(json);
  }

  Future<VisualTutorTurnResponseModel> sendTurn(
    VisualTutorTurnRequestModel request,
  ) async {
    final json = await _apiClient.post('/tutor/turn', body: request.toJson());
    return VisualTutorTurnResponseModel.fromJson(json);
  }

  Future<VisualTutorSessionModel> restoreSession(String sessionId) async {
    final json = await _apiClient.get('/tutor/sessions/$sessionId');
    return VisualTutorSessionModel.fromJson(json);
  }
}
