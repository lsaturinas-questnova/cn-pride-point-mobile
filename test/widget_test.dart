import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cn_pride_point_mobile/src/auth/auth_api.dart';
import 'package:cn_pride_point_mobile/src/auth/auth_repository.dart';
import 'package:cn_pride_point_mobile/src/auth/host_storage.dart';
import 'package:cn_pride_point_mobile/src/auth/token_storage.dart';
import 'package:cn_pride_point_mobile/src/models/entities.dart';
import 'package:cn_pride_point_mobile/src/repositories/offline_attendance_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('normalizeHostUrl prepends http when missing scheme', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = AuthRepository(
      api: AuthApi(client: http.Client(), clientId: 'id', clientSecret: 'secret'),
      tokenStorage: TokenStorage(const FlutterSecureStorage()),
      hostStorage: HostStorage(prefs),
    );

    final uri = repo.normalizeHostUrl('192.168.0.10:8080');
    expect(uri.scheme, 'http');
    expect(uri.host, '192.168.0.10');
    expect(uri.port, 8080);
  });

  test('AuthApi parses OAuth token response', () async {
    final client = _FakeClient(
      handler: (request) async {
        return http.Response(
          jsonEncode(
            {
              'access_token': 'a',
              'refresh_token': 'r',
              'token_type': 'Bearer',
              'expires_in': 10,
            },
          ),
          200,
          headers: {'content-type': 'application/json'},
        );
      },
    );

    final api = AuthApi(client: client, clientId: 'id', clientSecret: 'secret');
    final token = await api.passwordGrant(
      hostUri: Uri.parse('http://example.com'),
      username: 'admin',
      password: 'admin',
    );

    expect(token.accessToken, 'a');
    expect(token.refreshToken, 'r');
    expect(token.tokenType, 'Bearer');
    expect(token.expiresIn, 10);
  });

  test('buildMobileReference uses username and timestamp', () {
    expect(buildMobileReference(username: 'admin', timestampMillis: 123), 'admin-123');
    expect(buildMobileReference(username: '  ', timestampMillis: 123), 'unknown-123');
  });

  test('resolveSyncResponse matches by mobileReference', () {
    final pending = [
      OfflineAttendance(
        localId: 1,
        programId: 'p',
        activityId: 'a',
        attendeeId: 't',
        mobileReference: 'admin-1',
        checkedInAt: DateTime(2026, 1, 1),
        status: 'PRESENT',
        syncStatus: SyncStatus.pending,
      ),
      OfflineAttendance(
        localId: 2,
        programId: 'p',
        activityId: 'a',
        attendeeId: 't',
        mobileReference: 'admin-2',
        checkedInAt: DateTime(2026, 1, 1),
        status: 'PRESENT',
        syncStatus: SyncStatus.pending,
      ),
    ];

    final response = {
      'attendanceList': [
        {'id': 'uuid-1', 'mobileReference': 'admin-1', 'notes': null},
        {'id': null, 'mobileReference': 'admin-2', 'notes': 'Bad record'},
      ],
      'errors': true,
    };

    final r = resolveSyncResponse(pending: pending, response: response);
    expect(r.hasErrors, true);
    expect(r.updated, 2);
    expect(r.remoteIdByLocalId[1], 'uuid-1');
    expect(r.errorByLocalId[2], 'Bad record');
  });
}

class _FakeClient extends http.BaseClient {
  _FakeClient({required this.handler});

  final Future<http.Response> Function(http.BaseRequest request) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      request: request,
    );
  }
}
