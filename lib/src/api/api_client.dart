import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../auth/auth_session.dart';

class ApiClient {
  ApiClient(this._client);

  final http.Client _client;

  Future<Map<String, dynamic>> getJson(
    AuthSession session, {
    required String path,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(session.hostUrl, path, queryParameters);
    if (kDebugMode) {
      debugPrint('GET $uri');
    }
    final response = await _client.get(uri, headers: _authHeaders(session));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(statusCode: response.statusCode, body: response.body);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(statusCode: 200, body: 'Invalid JSON');
    }
    return decoded;
  }

  Future<Object?> postJson(
    AuthSession session, {
    required String path,
    required Object body,
  }) async {
    final uri = _buildUri(session.hostUrl, path, null);
    final headers = <String, String>{
      ..._authHeaders(session),
      'Content-Type': 'application/json',
    };
    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(statusCode: response.statusCode, body: response.body);
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Map<String, String> _authHeaders(AuthSession session) => <String, String>{
    'Authorization': '${session.tokenType} ${session.accessToken}',
    'Accept': 'application/json',
  };

  Uri _buildUri(String hostUrl, String path, Map<String, String>? query) {
    final host = Uri.parse(hostUrl);
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return host.replace(
      path: _joinPath(host.path, normalizedPath),
      queryParameters: (query == null || query.isEmpty) ? null : query,
      fragment: '',
    );
  }

  String _joinPath(String basePath, String suffix) {
    final b = basePath.endsWith('/')
        ? basePath.substring(0, basePath.length - 1)
        : basePath;
    final s = suffix.startsWith('/') ? suffix : '/$suffix';
    return '$b$s';
  }
}

class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}
