import 'package:flutter/services.dart';

/// OAuth **web** client id — the audience the backend validates
/// `POST /auth/google` tokens against (`GOOGLE_CLIENT_ID`). The Android app
/// requests an ID token minted for this id via `requestIdToken(...)`.
///
/// Override at build time with
/// `--dart-define=GOOGLE_WEB_CLIENT_ID=…` if it ever changes.
const String kGoogleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
  defaultValue:
      '1081633400296-fl03q2et1hasl33ejqgdqs50g902aa0g.apps.googleusercontent.com',
);

class GoogleAuthException implements Exception {
  GoogleAuthException(this.message);
  final String message;
  @override
  String toString() => 'GoogleAuthException: $message';
}

/// Native Google Sign-In bridge (`MainActivity.kt` + Play Services Auth).
/// There's no `google_sign_in` plugin on this Flutter SDK, so this launches
/// the real Google account chooser and returns the resulting ID token, which
/// the caller hands to `AuthController.loginWithGoogle` → `POST /auth/google`.
class GoogleAuth {
  GoogleAuth._();
  static const _channel = MethodChannel('plantpal/auth');

  /// Shows the Google account chooser. Returns the ID token, or `null` if the
  /// user backed out. Throws [GoogleAuthException] on a real failure.
  static Future<String?> signIn() async {
    try {
      return await _channel.invokeMethod<String>('signIn', {
        'webClientId': kGoogleWebClientId,
      });
    } on MissingPluginException {
      throw GoogleAuthException(
          'Google Sign-In needs a fresh app build — reinstall the APK.');
    } on PlatformException catch (e) {
      throw GoogleAuthException(e.message ?? 'Google sign-in failed.');
    }
  }

  /// Clears the cached Google account so the next sign-in shows the chooser.
  static Future<void> signOut() async {
    try {
      await _channel.invokeMethod('signOut');
    } on MissingPluginException {
      // nothing to do
    } on PlatformException {
      // ignore
    }
  }
}
