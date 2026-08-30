import 'package:flutter/services.dart';

/// Thrown when the platform camera/gallery bridge fails for a real reason
/// (no camera app, permission denied, unreadable file). A user cancelling
/// is **not** an error — that returns `null`.
class MediaException implements Exception {
  MediaException(this.message);
  final String message;
  @override
  String toString() => 'MediaException: $message';
}

/// Talks to the native bridge in `MainActivity.kt`. There's no `image_picker`
/// plugin on this Flutter SDK, so capture is a hand-rolled `MethodChannel`
/// that launches the system camera app (via a FileProvider, no CAMERA
/// permission needed) or the system photo picker, and returns downscaled
/// JPEG bytes ready to upload.
class MediaChannel {
  MediaChannel._();
  static const _channel = MethodChannel('plantpal/media');

  /// Opens the device camera. Returns the photo's JPEG bytes, or `null` if
  /// the user backed out without taking a shot.
  static Future<Uint8List?> capture() => _invoke('camera');

  /// Opens the device photo picker. Returns JPEG bytes or `null` on cancel.
  static Future<Uint8List?> pickFromGallery() => _invoke('gallery');

  static Future<Uint8List?> _invoke(String method) async {
    try {
      final bytes = await _channel.invokeMethod<Uint8List>(method);
      return bytes;
    } on MissingPluginException {
      // The native bridge only exists in a freshly-built Android APK — a
      // hot-reloaded / stale install won't have it.
      throw MediaException(
          'Camera bridge not loaded. Reinstall the app (full rebuild).');
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'no_camera':
          throw MediaException('This device has no camera app.');
        case 'busy':
          throw MediaException('A photo capture is already in progress.');
        default:
          throw MediaException(e.message ?? 'Could not open the camera.');
      }
    }
  }
}
