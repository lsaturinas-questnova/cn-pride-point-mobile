import 'package:http/http.dart' as http;

import 'auth_api.dart';
import 'auth_session.dart';
import 'host_storage.dart';
import 'token_storage.dart';

class AuthRepository {
  AuthRepository({
    required AuthApi api,
    required TokenStorage tokenStorage,
    required HostStorage hostStorage,
  }) : _api = api,
       _tokenStorage = tokenStorage,
       _hostStorage = hostStorage;

  final AuthApi _api;
  final TokenStorage _tokenStorage;
  final HostStorage _hostStorage;

  String? getLastHost() => _hostStorage.getLastHost();
  List<String> getHostHistory() => _hostStorage.getHistory();
  String? getLastUsername() => _hostStorage.getLastUsername();

  Future<AuthSession?> loadSession() async {
    final host = _hostStorage.getLastHost();
    final session = await _tokenStorage.readSession(hostUrl: host);
    if (session == null) return null;
    return refreshIfExpired(session);
  }

  Future<AuthSession> login({
    required String hostUrl,
    required String username,
    required String password,
  }) async {
    final hostUri = normalizeHostUrl(hostUrl);
    final token = await _api.passwordGrant(
      hostUri: hostUri,
      username: username,
      password: password,
    );

    final expiresAt = token.expiresIn == null
        ? null
        : DateTime.now().add(Duration(seconds: token.expiresIn!));

    final session = AuthSession(
      hostUrl: hostUri.toString(),
      accessToken: token.accessToken,
      tokenType: token.tokenType,
      refreshToken: token.refreshToken,
      expiresAt: expiresAt,
    );

    await _tokenStorage.writeSession(session);
    await _hostStorage.persistHostOnSuccessfulLogin(session.hostUrl);
    await _hostStorage.persistUsernameOnSuccessfulLogin(username);
    return session;
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
  }

  Future<AuthSession?> refreshIfExpired(AuthSession session) async {
    if (!session.isExpired) return session;
    final refreshToken = session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return session;

    try {
      final hostUri = Uri.parse(session.hostUrl);
      final refreshed = await _api.refreshGrant(
        hostUri: hostUri,
        refreshToken: refreshToken,
      );
      final expiresAt = refreshed.expiresIn == null
          ? null
          : DateTime.now().add(Duration(seconds: refreshed.expiresIn!));

      final next = AuthSession(
        hostUrl: session.hostUrl,
        accessToken: refreshed.accessToken,
        tokenType: refreshed.tokenType,
        refreshToken: refreshed.refreshToken ?? refreshToken,
        expiresAt: expiresAt,
      );

      await _tokenStorage.writeSession(next);
      return next;
    } on AuthApiException catch (e) {
      if (e.statusCode == 400 || e.statusCode == 401) {
        await _tokenStorage.clear();
        return null;
      }
      rethrow;
    }
  }

  Uri normalizeHostUrl(String rawHost) {
    final trimmed = rawHost.trim();
    if (trimmed.isEmpty) throw const FormatException('HOST_URL is empty');

    final withScheme = trimmed.contains('://') ? trimmed : 'http://$trimmed';
    final uri = Uri.parse(withScheme);

    if (uri.host.isEmpty) throw const FormatException('Invalid HOST_URL');

    return uri.replace(
      path: uri.path.endsWith('/')
          ? uri.path.substring(0, uri.path.length - 1)
          : uri.path,
      query: '',
      fragment: '',
    );
  }
}

class AppHttpClient {
  AppHttpClient(this.client);

  final http.Client client;
}
