import 'package:flutter/widgets.dart';

import '../api/api_client.dart';
import '../api/google_auth.dart';
import '../api/plantpal_api.dart';
import '../api/push_channel.dart';
import '../api/token_store.dart';
import '../models/models.dart';

enum AuthStatus { unknown, signedOut, signedIn }

/// App-wide auth state. Plain [ChangeNotifier] — no extra packages.
class AuthController extends ChangeNotifier {
  AuthController._();
  static final AuthController instance = AuthController._();

  final PlantPalApi _api = PlantPalApi.instance;

  AuthStatus status = AuthStatus.unknown;
  UserProfile? user;

  bool get isSignedIn => status == AuthStatus.signedIn;

  /// Wire the client's "refresh failed" hook to a forced sign-out, and keep
  /// the backend's copy of this device's FCM push token fresh.
  void bootstrapHooks() {
    ApiClient.instance.onAuthLost = () {
      status = AuthStatus.signedOut;
      user = null;
      notifyListeners();
    };
    // FCM can rotate the token mid-session; re-register when it does.
    PushChannel.onTokenRefresh.listen((token) {
      if (isSignedIn) {
        PlantPalApi.instance.registerDevice(token).catchError((_) {});
      }
    });
  }

  /// Best-effort: hand this device's current FCM token to the backend so it
  /// can push reminders while the app is closed. Never throws.
  Future<void> _syncPushToken() async {
    try {
      final token = await PushChannel.getToken();
      if (token != null) await _api.registerDevice(token);
    } catch (_) {
      // No Play Services, offline, bridge missing — push just stays off.
    }
  }

  Future<void> restore() async {
    await TokenStore.instance.load();
    if (!TokenStore.instance.hasSession) {
      status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    try {
      user = await _api.me();
      status = AuthStatus.signedIn;
      _syncPushToken();
    } catch (_) {
      // Token stale and refresh failed.
      await TokenStore.instance.clear();
      status = AuthStatus.signedOut;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _api.login(email: email, password: password);
    await _loadUserAndSignIn();
  }

  Future<void> register(String fullName, String email, String password) async {
    await _api.register(fullName: fullName, email: email, password: password);
    await _loadUserAndSignIn();
  }

  /// Exchange a Google ID token for a PlantPal session via `POST /auth/google`.
  /// The token has to come from a real Google Sign-In flow — see
  /// [LoginScreen] for why this build can't surface the native account
  /// picker itself.
  Future<void> loginWithGoogle(String idToken) async {
    await _api.googleLogin(idToken);
    await _loadUserAndSignIn();
  }

  /// Push a locally-changed profile (name / avatar URL) and refresh [user].
  Future<void> updateProfile({String? fullName, String? imageUrl}) async {
    user = await _api.updateMe(fullName: fullName, imageUrl: imageUrl);
    notifyListeners();
  }

  /// Replace the cached [user] (e.g. after an avatar upload returns the
  /// updated record).
  void setUser(UserProfile updated) {
    user = updated;
    notifyListeners();
  }

  Future<void> _loadUserAndSignIn() async {
    // Flip to signed-in as soon as we hold tokens so the UI can route to
    // Home immediately; the profile and push token load in the background
    // (Home reads `user` reactively and tolerates a null while it arrives).
    status = AuthStatus.signedIn;
    notifyListeners();
    _syncPushToken();
    try {
      user = await _api.me();
      notifyListeners();
    } catch (_) {
      user = null;
    }
  }

  Future<void> refreshUser() async {
    try {
      user = await _api.me();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    // Drop this device's push token first, while the access token is still
    // valid, then kill it locally so a shared device stops getting the
    // previous user's reminders.
    try {
      final token = await PushChannel.getToken();
      if (token != null) await _api.unregisterDevice(token);
    } catch (_) {}
    await PushChannel.deleteToken();

    try {
      await _api.logout();
    } catch (_) {}
    await GoogleAuth.signOut(); // so a later Google sign-in shows the chooser
    user = null;
    status = AuthStatus.signedOut;
    notifyListeners();
  }
}

/// Exposes [AuthController] to the tree and rebuilds dependents on change.
class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({super.key, required AuthController controller, required super.child})
      : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope missing from the widget tree');
    return scope!.notifier!;
  }

  static AuthController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AuthScope>();
    return scope?.notifier ?? AuthController.instance;
  }
}
