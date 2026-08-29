import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'state/auth_scope.dart';
import 'theme/pp_theme.dart';
import 'screens/root_shell.dart';
import 'screens/welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: PP.bone,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  final auth = AuthController.instance..bootstrapHooks();
  auth.restore();

  runApp(PlantPalApp(auth: auth));
}

class PlantPalApp extends StatelessWidget {
  const PlantPalApp({super.key, required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: auth,
      child: MaterialApp(
        title: 'PlantPal',
        debugShowCheckedModeBanner: false,
        theme: buildPlantPalTheme(),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    switch (auth.status) {
      case AuthStatus.unknown:
        return const _Splash();
      case AuthStatus.signedIn:
        return const RootShell();
      case AuthStatus.signedOut:
        return const WelcomeScreen();
    }
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: PP.forest,
      body: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(strokeWidth: 2.6, color: PP.lime),
        ),
      ),
    );
  }
}
