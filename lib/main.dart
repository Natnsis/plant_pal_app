import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api/link_channel.dart';
import 'screens/community_post_screen.dart';
import 'screens/root_shell.dart';
import 'screens/welcome_screen.dart';
import 'state/auth_scope.dart';
import 'theme/pp_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

class PlantPalApp extends StatefulWidget {
  const PlantPalApp({super.key, required this.auth});

  final AuthController auth;

  @override
  State<PlantPalApp> createState() => _PlantPalAppState();
}

class _PlantPalAppState extends State<PlantPalApp> {
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    // Deep links: plantpal://post/<id> opens that community post.
    LinkChannel.initial().then(_handleLink);
    _linkSub = LinkChannel.stream.listen(_handleLink);
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  void _handleLink(Uri? uri) {
    if (uri == null || uri.scheme != 'plantpal') return;
    final segs = [uri.host, ...uri.pathSegments].where((s) => s.isNotEmpty).toList();
    if (segs.length >= 2 && segs[0] == 'post') {
      final id = int.tryParse(segs[1]);
      final nav = navigatorKey.currentState;
      if (id != null && nav != null) {
        nav.push(MaterialPageRoute(
            builder: (_) => CommunityPostScreen(postId: id)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: widget.auth,
      child: MaterialApp(
        title: 'PlantPal',
        navigatorKey: navigatorKey,
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
