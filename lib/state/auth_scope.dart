import 'package:flutter/widgets.dart';

import '../api/api_client.dart';
import '../api/plantpal_api.dart';
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

  /// Wire the client's "refresh failed" hook to a forced sign-out.
  void bootstrapHooks() {
    ApiClient.instance.onAuthLost = () {
      status = AuthStatus.signedOut;
      user = null;
      notifyListeners();
    };
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
    try {
      user = await _api.me();
    } catch (_) {
      user = null;
    }
    status = AuthStatus.signedIn;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      user = await _api.me();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
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
