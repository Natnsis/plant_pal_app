import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Persists the JWT pair to a JSON file in the app support directory.
///
/// `shared_preferences` / `flutter_secure_storage` can't be resolved on this
/// Flutter SDK (missing `flutter_web_plugins`), so this is a plain file store.
/// Fine for a demo build; swap for secure storage on a full SDK.
class TokenStore {
  TokenStore._();
  static final TokenStore instance = TokenStore._();

  static const _fileName = 'pp_tokens.json';

  String? accessToken;
  String? refreshToken;

  bool get hasSession => (accessToken ?? '').isNotEmpty;

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

  Future<void> load() async {
    try {
      final f = await _file();
      if (!f.existsSync()) return;
      final m = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      accessToken = m['access_token'] as String?;
      refreshToken = m['refresh_token'] as String?;
    } catch (_) {
      // Corrupt or unreadable — treat as logged out.
    }
  }

  Future<void> save(String access, String refresh) async {
    accessToken = access;
    refreshToken = refresh;
    try {
      final f = await _file();
      await f.writeAsString(
        jsonEncode({'access_token': access, 'refresh_token': refresh}),
        flush: true,
      );
    } catch (_) {}
  }

  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    try {
      final f = await _file();
      if (f.existsSync()) await f.delete();
    } catch (_) {}
  }
}
