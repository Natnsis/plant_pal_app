import 'dart:async';

import 'package:flutter/services.dart';

/// Receives `plantpal://…` deep links from the native side
/// (`MainActivity.kt`). Used for shared community-post links
/// (`plantpal://post/<id>`).
class LinkChannel {
  LinkChannel._();
  static const _channel = MethodChannel('plantpal/links');

  static final _controller = StreamController<Uri>.broadcast();
  static bool _wired = false;

  /// Deep links received while the app is already running.
  static Stream<Uri> get stream {
    _wire();
    return _controller.stream;
  }

  static void _wire() {
    if (_wired) return;
    _wired = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'link' && call.arguments is String) {
        final uri = Uri.tryParse(call.arguments as String);
        if (uri != null) _controller.add(uri);
      }
    });
  }

  /// The link the app was cold-started from, if any. Consumed once.
  static Future<Uri?> initial() async {
    _wire();
    try {
      final raw = await _channel.invokeMethod<String>('getInitial');
      return raw == null ? null : Uri.tryParse(raw);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
