import 'package:flutter/services.dart';

/// Result of asking for / checking notification permission.
enum NotifPermission {
  /// Allowed — real notifications will show on the phone.
  granted,

  /// Not allowed, but the OS will still show our prompt if asked again
  /// (user dismissed it once). Worth re-asking on a later app open.
  deniedCanRetry,

  /// Not allowed and asking again won't show a prompt (permanently denied,
  /// or the platform has no notion of this permission). Stay silent.
  denied,
}

/// Bridge to the native notification code in `MainActivity.kt`. There's no
/// `flutter_local_notifications` on this Flutter SDK, so this hand-rolls the
/// Android 13+ `POST_NOTIFICATIONS` permission flow and posts notifications
/// straight to the system shade.
class NotifChannel {
  NotifChannel._();
  static const _channel = MethodChannel('plantpal/notifications');

  static NotifPermission _parse(String? raw) {
    switch (raw) {
      case 'granted':
        return NotifPermission.granted;
      case 'denied_can_retry':
        return NotifPermission.deniedCanRetry;
      default:
        return NotifPermission.denied;
    }
  }

  /// Current permission state without prompting.
  static Future<NotifPermission> status() async {
    try {
      return _parse(await _channel.invokeMethod<String>('status'));
    } on MissingPluginException {
      return NotifPermission.denied; // non-Android build
    } on PlatformException {
      return NotifPermission.denied;
    }
  }

  /// Shows the OS permission prompt (Android 13+). Returns the resulting
  /// state. On older Android / other platforms this resolves to
  /// [NotifPermission.granted] / [NotifPermission.denied] without a prompt.
  static Future<NotifPermission> requestPermission() async {
    try {
      return _parse(await _channel.invokeMethod<String>('requestPermission'));
    } on MissingPluginException {
      return NotifPermission.denied;
    } on PlatformException {
      return NotifPermission.denied;
    }
  }

  /// Opens this app's notification-settings page in the OS so the user can
  /// flip the system toggle directly.
  static Future<void> openSettings() async {
    try {
      await _channel.invokeMethod('openSettings');
    } on MissingPluginException {
      // ignore
    } on PlatformException {
      // ignore
    }
  }

  /// Posts a notification to the phone. No-ops silently if not permitted.
  static Future<void> show({
    required String title,
    required String body,
    int? id,
  }) async {
    final args = <String, dynamic>{'title': title, 'body': body};
    if (id != null) args['id'] = id;
    try {
      await _channel.invokeMethod('show', args);
    } on MissingPluginException {
      // non-Android build — nothing to do
    } on PlatformException {
      // ignore
    }
  }
}
