import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_session.dart';

class TokenStorage {
  TokenStorage(this._storage);

  static const _accessTokenKey = 'access_token_v1';
  static const _refreshTokenKey = 'refresh_token_v1';
  static const _tokenTypeKey = 'token_type_v1';
  static const _expiresAtMillisKey = 'expires_at_millis_v1';

  final FlutterSecureStorage _storage;

  Future<AuthSession?> readSession({required String? hostUrl}) async {
    if (hostUrl == null || hostUrl.trim().isEmpty) return null;

    final accessToken = await _storage.read(key: _accessTokenKey);
    if (accessToken == null || accessToken.isEmpty) return null;

    final tokenType = await _storage.read(key: _tokenTypeKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final expiresAtMillis = await _storage.read(key: _expiresAtMillisKey);

    DateTime? expiresAt;
    if (expiresAtMillis != null && expiresAtMillis.isNotEmpty) {
      final parsed = int.tryParse(expiresAtMillis);
      if (parsed != null) {
        expiresAt = DateTime.fromMillisecondsSinceEpoch(
          parsed,
          isUtc: true,
        ).toLocal();
      }
    }

    return AuthSession(
      hostUrl: hostUrl.trim(),
      accessToken: accessToken,
      tokenType: (tokenType == null || tokenType.isEmpty)
          ? 'Bearer'
          : tokenType,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  Future<void> writeSession(AuthSession session) async {
    await _storage.write(key: _accessTokenKey, value: session.accessToken);
    await _storage.write(key: _tokenTypeKey, value: session.tokenType);
    await _storage.write(key: _refreshTokenKey, value: session.refreshToken);

    final expiresAt = session.expiresAt;
    if (expiresAt == null) {
      await _storage.delete(key: _expiresAtMillisKey);
    } else {
      await _storage.write(
        key: _expiresAtMillisKey,
        value: expiresAt.toUtc().millisecondsSinceEpoch.toString(),
      );
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _tokenTypeKey);
    await _storage.delete(key: _expiresAtMillisKey);
  }
}
