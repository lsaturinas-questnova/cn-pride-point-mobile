import 'dart:convert';

import 'package:http/http.dart' as http;

class OAuthTokenResponse {
  const OAuthTokenResponse({
    required this.accessToken,
    required this.tokenType,
    this.refreshToken,
    this.expiresIn,
  });

  final String accessToken;
  final String tokenType;
  final String? refreshToken;
  final int? expiresIn;
}

class AuthApi {
  AuthApi({
    required http.Client client,
    required String clientId,
    required String clientSecret,
  }) : _client = client,
       _clientId = clientId,
       _clientSecret = clientSecret;

  final http.Client _client;
  final String _clientId;
  final String _clientSecret;

  Future<OAuthTokenResponse> passwordGrant({
    required Uri hostUri,
    required String username,
    required String password,
  }) async {
    return _postToken(
      hostUri: hostUri,
      fields: {
        'grant_type': 'password',
        'username': username,
        'password': password,
      },
    );
  }

  Future<OAuthTokenResponse> refreshGrant({
    required Uri hostUri,
    required String refreshToken,
  }) async {
    return _postToken(
      hostUri: hostUri,
      fields: {'grant_type': 'refresh_token', 'refresh_token': refreshToken},
    );
  }

  Future<OAuthTokenResponse> _postToken({
    required Uri hostUri,
    required Map<String, String> fields,
  }) async {
    final tokenUri = hostUri.replace(
      path: _joinPath(hostUri.path, '/oauth2/token'),
    );

    final credentials = base64Encode(utf8.encode('$_clientId:$_clientSecret'));
    final headers = <String, String>{
      'Authorization': 'Basic $credentials',
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json',
    };

    final response = await _client.post(
      tokenUri,
      headers: headers,
      body: fields,
      encoding: utf8,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AuthApiException(statusCode: 200, body: 'Invalid JSON');
    }

    final accessToken = decoded['access_token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const AuthApiException(
        statusCode: 200,
        body: 'Missing access_token',
      );
    }

    final tokenType = decoded['token_type'];
    final refreshToken = decoded['refresh_token'];
    final expiresIn = decoded['expires_in'];

    return OAuthTokenResponse(
      accessToken: accessToken,
      tokenType: (tokenType is String && tokenType.isNotEmpty)
          ? tokenType
          : 'Bearer',
      refreshToken: refreshToken is String ? refreshToken : null,
      expiresIn: expiresIn is num ? expiresIn.toInt() : null,
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

class AuthApiException implements Exception {
  const AuthApiException({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}
