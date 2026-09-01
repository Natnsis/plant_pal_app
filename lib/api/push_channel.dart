import 'dart:async';

import 'package:flutter/services.dart';

/// Bridge to the FCM code in `MainActivity.kt` /
/// `PlantPalFirebaseMessagingService.kt`. There's no `firebase_messaging`
/// plugin on this Flutter SDK (same `flutter_web_plugins` resolver wall as
/// the other stripped plugins), so token handling is a hand-rolled
/// `MethodChannel` over the native Firebase Android SDK.
///
/// Delivery of the messages themselves is fully native: the backend sends
/// data-only pushes and the Kotlin service posts them straight to the
/// system shade, so Dart is only involved in registering the device token.
class PushChannel {
  PushChannel._();

  static const _channel = MethodChannel('plantpal/push');

  static bool _handlerSet = false;
  static final StreamController<String> _tokenRefresh =
      StreamController<String>.broadcast(
    onListen: _ensureHandler,
  );

  /// Fires when FCM rotates the registration token while the app is running.
  /// Callers should re-register the new value with the backend.
  static Stream<String> get onTokenRefresh => _tokenRefresh.stream;

  static void _ensureHandler() {
    if (_handlerSet) return;
    _handlerSet = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onToken') {
        final token = call.arguments as String?;
        if (token != null && token.isNotEmpty) _tokenRefresh.add(token);
      }
    });
  }

  /// Current FCM registration token, or `null` if Play Services / Firebase
  /// can't produce one (e.g. an emulator without Google APIs).
  static Future<String?> getToken() async {
    _ensureHandler();
    try {
      final token = await _channel.invokeMethod<String>('getToken');
      return (token == null || token.isEmpty) ? null : token;
    } on MissingPluginException {
      return null; // non-Android build / stale install without the bridge
    } on PlatformException {
      return null;
    }
  }

  /// Deletes the current token so the device stops receiving pushes. Call on
  /// logout, after telling the backend to drop it.
  static Future<void> deleteToken() async {
    try {
      await _channel.invokeMethod('deleteToken');
    } on MissingPluginException {
      // nothing to do
    } on PlatformException {
      // ignore
    }
  }
}
