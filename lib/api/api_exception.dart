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
    String msg = 'Request failed ($status)';
    try {
      final decoded = rawBody.isEmpty ? null : jsonDecode(rawBody);
      final m = asMap(decoded);
      if (m.isNotEmpty) {
        msg = asString(pick(m, ['error', 'message', 'msg']), msg);
      } else if (rawBody.isNotEmpty && rawBody.length < 200) {
        msg = rawBody;
      }
    } catch (_) {
      if (rawBody.isNotEmpty && rawBody.length < 200) msg = rawBody;
    }
    return ApiException(msg, statusCode: status, body: rawBody);
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
