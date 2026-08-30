import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'token_store.dart';

/// Base URL for the PlantPal backend. Override at build time with
/// `--dart-define=PLANTPAL_API=https://…`.
const String kPlantPalBaseUrl = String.fromEnvironment(
  'PLANTPAL_API',
  defaultValue: 'https://plant-hzgf.onrender.com',
);

typedef Json = Map<String, dynamic>;

/// Thin HTTP wrapper: attaches the bearer token, decodes JSON, maps errors,
/// and transparently refreshes the token once on a 401.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final http.Client _http = http.Client();
  final TokenStore _tokens = TokenStore.instance;

  /// Called when refresh fails — the app should route back to sign-in.
  void Function()? onAuthLost;

  Future<T> getJson<T>(String path, {Map<String, String>? query}) =>
      _send<T>('GET', path, query: query);

  Future<T> postJson<T>(String path, {Object? body}) =>
      _send<T>('POST', path, body: body);

  Future<T> putJson<T>(String path, {Object? body}) =>
      _send<T>('PUT', path, body: body);

  Future<T> patchJson<T>(String path, {Object? body}) =>
      _send<T>('PATCH', path, body: body);

  Future<T> deleteJson<T>(String path, {Object? body}) =>
      _send<T>('DELETE', path, body: body);

  /// Multipart upload (used by `/scan` and `/diagnosis`).
  Future<T> uploadImage<T>(
    String path, {
    required Uint8List bytes,
    required String filename,
    String field = 'image',
    String contentType = 'image/jpeg',
  }) =>
      uploadMultipart<T>(
        path,
        imageBytes: bytes,
        filename: filename,
        imageField: field,
      );

  /// Multipart request with arbitrary text fields plus an optional image
  /// file. Used by `/journal` (text fields + optional photo), `/scan` and
  /// `/diagnosis` (image only, via [uploadImage]), and `PUT /plants/{id}/photo`
  /// / `PUT /users/me/avatar`.
  Future<T> uploadMultipart<T>(
    String path, {
    String method = 'POST',
    Map<String, String> fields = const {},
    Uint8List? imageBytes,
    String filename = 'image.jpg',
    String imageField = 'image',
  }) async {
    Future<http.Response> attempt() async {
      final req = http.MultipartRequest(method, _uri(path, null));
      req.headers.addAll(_authHeaders(json: false));
      req.fields.addAll(fields);
      if (imageBytes != null) {
        req.files.add(http.MultipartFile.fromBytes(
          imageField,
          imageBytes,
          filename: filename,
        ));
      }
      final streamed = await _http.send(req).timeout(const Duration(seconds: 60));
      return http.Response.fromStream(streamed);
    }

    var res = await _guard(attempt);
    if (res.statusCode == 401 && await _tryRefresh()) {
      res = await _guard(attempt);
    }
    return _decode<T>(res);
  }

  // ── internals ─────────────────────────────────────────────────────────────

  Future<T> _send<T>(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    Future<http.Response> attempt() {
      final uri = _uri(path, query);
      final headers = _authHeaders(json: true);
      final encoded = body == null ? null : jsonEncode(body);
      final f = switch (method) {
        'GET' => _http.get(uri, headers: headers),
        'POST' => _http.post(uri, headers: headers, body: encoded),
        'PUT' => _http.put(uri, headers: headers, body: encoded),
        'PATCH' => _http.patch(uri, headers: headers, body: encoded),
        'DELETE' => _http.delete(uri, headers: headers, body: encoded),
        _ => throw ArgumentError('method $method'),
      };
      return f.timeout(const Duration(seconds: 60));
    }

    // Only auto-retry idempotent reads; retrying a POST/PUT/etc could double
    // a create or a "mark done".
    var res = method == 'GET'
        ? await _guardRetrying(attempt)
        : await _guard(attempt);
    if (res.statusCode == 401 && await _tryRefresh()) {
      res = await _guard(attempt);
    }
    return _decode<T>(res);
  }

  /// Turns any transport failure into a generic, user-safe message. Never
  /// surfaces the raw exception — a `SocketException` / `http.ClientException`
  /// includes the backend URL, and that shouldn't be shown to users.
  Never _throwTransport(Object e) {
    if (e is TimeoutException) {
      throw ApiException(
        'The server took too long to respond. It may be waking up — try again.',
      );
    }
    if (e is SocketException) {
      throw ApiException(
        'No connection. Check your internet and try again.',
      );
    }
    if (e is HandshakeException || e is TlsException) {
      throw ApiException('Secure connection failed. Try again.');
    }
    throw ApiException('Something went wrong. Please try again.');
  }

  Future<http.Response> _guard(Future<http.Response> Function() run) async {
    try {
      return await run();
    } catch (e) {
      _throwTransport(e);
    }
  }

  /// Like [_guard] but transparently retries once on a transient failure — a
  /// timeout, a network blip, or a 5xx from the (free-tier, sometimes
  /// overloaded / cold) backend. One extra attempt after a short delay hides
  /// the vast majority of "failed to fetch …" flakes.
  Future<http.Response> _guardRetrying(
      Future<http.Response> Function() run) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final res = await run();
        if (res.statusCode >= 500 && res.statusCode != 501 && attempt == 0) {
          await Future.delayed(const Duration(milliseconds: 1400));
          continue;
        }
        return res;
      } catch (e) {
        if (attempt == 0) {
          await Future.delayed(const Duration(milliseconds: 800));
          continue;
        }
        _throwTransport(e);
      }
    }
    // Unreachable — the loop either returns or throws on the last attempt.
    return run();
  }

  Uri _uri(String path, Map<String, String>? query) {
    final clean = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$kPlantPalBaseUrl$clean').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
  }

  Map<String, String> _authHeaders({required bool json}) {
    final h = <String, String>{'Accept': 'application/json'};
    if (json) h['Content-Type'] = 'application/json';
    final tok = _tokens.accessToken;
    if (tok != null && tok.isNotEmpty) h['Authorization'] = 'Bearer $tok';
    return h;
  }

  Completer<bool>? _refreshing;

  Future<bool> _tryRefresh() {
    if (_refreshing != null) return _refreshing!.future;
    final c = _refreshing = Completer<bool>();
    () async {
      final rt = _tokens.refreshToken;
      if (rt == null || rt.isEmpty) {
        c.complete(false);
      } else {
        try {
          final res = await _http
              .post(
                _uri('/refresh', null),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'refresh_token': rt}),
              )
              .timeout(const Duration(seconds: 30));
          if (res.statusCode == 200) {
            final m = jsonDecode(res.body) as Map<String, dynamic>;
            await _tokens.save(
              m['access_token'] as String? ?? '',
              m['refresh_token'] as String? ?? rt,
            );
            c.complete(true);
          } else {
            await _tokens.clear();
            onAuthLost?.call();
            c.complete(false);
          }
        } catch (_) {
          c.complete(false);
        }
      }
      _refreshing = null;
    }();
    return c.future;
  }

  T _decode<T>(http.Response res) {
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    if (!ok) throw ApiException.fromResponse(res.statusCode, res.body);
    if (T == _Void || res.body.isEmpty) return _empty<T>();
    final Object? decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (_) {
      if (T == String) return res.body as T;
      throw ApiException('Malformed response from server.',
          statusCode: res.statusCode, body: res.body);
    }
    if (decoded is T) return decoded;
    // Allow callers asking for Map/List to get an empty one rather than crash.
    return _coerce<T>(decoded);
  }

  T _empty<T>() {
    if (T.toString().startsWith('List')) return <dynamic>[] as T;
    if (T.toString().startsWith('Map')) return <String, dynamic>{} as T;
    return null as T;
  }

  T _coerce<T>(Object? decoded) {
    if (T.toString().startsWith('List') && decoded is! List) {
      return <dynamic>[] as T;
    }
    if (T.toString().startsWith('Map') && decoded is! Map) {
      return <String, dynamic>{} as T;
    }
    return decoded as T;
  }
}

class _Void {}
