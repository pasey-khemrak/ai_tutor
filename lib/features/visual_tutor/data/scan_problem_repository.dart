import 'dart:typed_data';
import 'dart:async';

import '../../../core/config/app_config.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/network/api_client.dart';

class ScanProblemResult {
  const ScanProblemResult({
    required this.detectedText,
    required this.confidence,
    required this.language,
    this.mathExpressionCandidates = const [],
  });

  final String detectedText;
  final double confidence;
  final String language;
  final List<String> mathExpressionCandidates;

  factory ScanProblemResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return ScanProblemResult(
      detectedText: (data['detected_text'] as String? ?? '').trim(),
      confidence: (data['confidence'] as num? ?? 0).toDouble(),
      language: (data['language'] as String? ?? 'unknown').trim(),
      mathExpressionCandidates:
          (data['math_expression_candidates'] as List? ?? const [])
              .whereType<String>()
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList(),
    );
  }
}

class ScanProblemRepository {
  ScanProblemRepository({ApiClient? apiClient})
    : _apiClient =
          apiClient ??
          ApiClient(
            config: AppConfig.current,
            tokenProvider: appAuthService.getAccessToken,
          );

  final ApiClient _apiClient;

  Future<ScanProblemResult> scan({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    try {
      final response = await _apiClient
          .postBytes(
            '/tutor/scan',
            bytes: bytes,
            filename: filename,
            contentType: contentType,
          )
          .timeout(const Duration(seconds: 35));
      return ScanProblemResult.fromJson(response);
    } on TimeoutException {
      throw const ScanProblemException(
        code: 'OCR_TIMEOUT',
        message: 'Image reading took too long. Please try again.',
      );
    } on ApiException catch (error) {
      throw ScanProblemException.fromApi(error);
    }
  }
}

class ScanProblemException implements Exception {
  const ScanProblemException({required this.code, required this.message});

  final String code;
  final String message;

  factory ScanProblemException.fromApi(ApiException error) {
    final body = error.body;
    final errorMap = body is Map ? body['error'] : null;
    final code = errorMap is Map && errorMap['code'] is String
        ? errorMap['code'] as String
        : '';
    if (error.statusCode == 503 || code == 'AI_SERVICE_UNAVAILABLE') {
      return const ScanProblemException(
        code: 'AI_UNAVAILABLE',
        message:
            'Image reading is temporarily unavailable. Please try again shortly.',
      );
    }
    if (error.statusCode == 422 || code == 'OCR_EMPTY_RESULT') {
      return const ScanProblemException(
        code: 'UNREADABLE_IMAGE',
        message: 'We could not read a question. Use a sharper, well-lit image.',
      );
    }
    return ScanProblemException(
      code: code.isEmpty ? 'SCAN_FAILED' : code,
      message: error.message,
    );
  }
}
