import 'dart:convert';

import 'json_util.dart';

/// Everything the API layer throws. [statusCode] is 0 for transport failures.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode = 0, this.body});

  final String message;
  final int statusCode;
  final Object? body;

  bool get isNetwork => statusCode == 0;
  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;
  bool get isNotFound => statusCode == 404;
  bool get isRateLimited => statusCode == 429;
  bool get isBadRequest => statusCode == 400;
  bool get isServer => statusCode >= 500;

  factory ApiException.fromResponse(int status, String rawBody) {
    // Default is deliberately generic. The API always returns a JSON
    // `{"error": "..."}` on failure; anything else (a proxy / infra error
    // page) is NOT shown verbatim — it can carry the backend URL, and users
    // don't need to see internals.
    String msg = status >= 500
        ? 'The server had a problem. Please try again.'
        : 'Request failed ($status)';
    try {
      final decoded = rawBody.isEmpty ? null : jsonDecode(rawBody);
      final m = asMap(decoded);
      if (m.isNotEmpty) {
        final fromApi = asString(pick(m, ['error', 'message', 'msg']));
        if (fromApi.isNotEmpty && !_looksLikeUrl(fromApi)) msg = fromApi;
      }
    } catch (_) {
      // Non-JSON body — keep the generic message.
    }
    return ApiException(msg, statusCode: status, body: rawBody);
  }

  static bool _looksLikeUrl(String s) =>
      s.contains('://') ||
      s.contains('onrender.com') ||
      RegExp(r'\b[\w-]+\.[\w.-]+\.\w{2,}\b').hasMatch(s);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
