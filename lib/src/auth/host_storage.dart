import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class HostStorage {
  HostStorage(this._prefs);

  static const _historyKey = 'host_url_history_v1';
  static const _lastKey = 'host_url_last_v1';
  static const _lastUsernameKey = 'last_username_v1';

  final SharedPreferences _prefs;

  String? getLastHost() => _prefs.getString(_lastKey);
  String? getLastUsername() => _prefs.getString(_lastUsernameKey);

  List<String> getHistory() {
    final raw = _prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded.whereType<String>().toList(growable: false);
  }

  Future<void> persistHostOnSuccessfulLogin(String hostUrl) async {
    final normalized = hostUrl.trim();
    if (normalized.isEmpty) return;

    final history = getHistory().toList();
    history.removeWhere((h) => h == normalized);
    history.insert(0, normalized);

    await _prefs.setString(_historyKey, jsonEncode(history));
    await _prefs.setString(_lastKey, normalized);
  }

  Future<void> persistUsernameOnSuccessfulLogin(String username) async {
    final normalized = username.trim();
    if (normalized.isEmpty) return;
    await _prefs.setString(_lastUsernameKey, normalized);
  }
}
