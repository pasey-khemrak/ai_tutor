import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final Object? body;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({
    required this.config,
    http.Client? httpClient,
    Future<String?> Function()? tokenProvider,
  }) : _httpClient = httpClient ?? http.Client(),
       _tokenProvider = tokenProvider;

  final AppConfig config;
  final http.Client _httpClient;
  final Future<String?> Function()? _tokenProvider;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final response = await _httpClient.get(
      config.backendUri(path, queryParameters),
      headers: await _headers(),
    );
    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    final response = await _httpClient.post(
      config.backendUri(path, queryParameters),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> postBytes(
    String path, {
    required Uint8List bytes,
    required String contentType,
    required String filename,
  }) async {
    final response = await _httpClient.post(
      config.backendUri(path),
      headers: {
        ...await _headers(),
        'Content-Type': contentType,
        'X-Upload-Filename': filename,
      },
      body: bytes,
    );
    return _decodeObject(response);
  }

  Future<Uint8List> postForBytes(String path, {required Object body}) async {
    final response = await _httpClient.post(
      config.backendUri(path), headers: await _headers(), body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _decodeObject(response);
    }
    return response.bodyBytes;
  }

  Future<Map<String, String>> _headers() async {
    final token = await _tokenProvider?.call();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    Object? decoded;
    if (response.body.isNotEmpty) {
      decoded = jsonDecode(response.body);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        message:
            _extractErrorMessage(decoded) ??
            response.reasonPhrase ??
            'Request failed',
        statusCode: response.statusCode,
        body: decoded,
      );
    }

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw ApiException(
      message: 'Expected a JSON object response.',
      statusCode: response.statusCode,
      body: decoded,
    );
  }

  String? _extractErrorMessage(Object? decoded) {
    if (decoded is Map<String, dynamic>) {
      final message =
          decoded['message'] ?? decoded['error'] ?? decoded['detail'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return null;
  }

  void close() => _httpClient.close();
}
