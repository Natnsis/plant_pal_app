import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Tiny key/value store for app-local preferences that aren't worth a
/// backend round-trip — same plain-JSON-file approach as `TokenStore`
/// (no `shared_preferences` on this Flutter SDK).
class AppPrefs {
  AppPrefs._();
  static final AppPrefs instance = AppPrefs._();

  static const _fileName = 'pp_prefs.json';

  Map<String, dynamic>? _cache;
  File? _cachedFile;

  Future<File> _file() async {
    if (_cachedFile != null) return _cachedFile!;
    Directory dir;
    try {
      dir = await getApplicationSupportDirectory();
    } catch (_) {
      dir = Directory.systemTemp;
    }
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return _cachedFile = File('${dir.path}/$_fileName');
  }

  Future<Map<String, dynamic>> _load() async {
    if (_cache != null) return _cache!;
    try {
      final f = await _file();
      if (f.existsSync()) {
        final m = jsonDecode(await f.readAsString());
        if (m is Map) return _cache = m.cast<String, dynamic>();
      }
    } catch (_) {}
    return _cache = {};
  }

  Future<void> _save() async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode(_cache ?? {}), flush: true);
    } catch (_) {}
  }

  Future<int> getInt(String key, [int fallback = 0]) async {
    final v = (await _load())[key];
    return v is int ? v : (v is num ? v.toInt() : fallback);
  }

  Future<String?> getString(String key) async {
    final v = (await _load())[key];
    return v?.toString();
  }

  Future<void> setInt(String key, int value) async {
    (await _load())[key] = value;
    await _save();
  }

  Future<void> setString(String key, String value) async {
    (await _load())[key] = value;
    await _save();
  }
}
