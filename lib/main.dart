import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'api/link_channel.dart';
import 'screens/community_post_screen.dart';
import 'screens/plant_detail_screen.dart';
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
    final segs =
        [uri.host, ...uri.pathSegments].where((s) => s.isNotEmpty).toList();
    if (segs.length < 2) return;
    final id = int.tryParse(segs[1]);
    final nav = navigatorKey.currentState;
    if (id == null || nav == null) return;
    switch (segs[0]) {
      case 'post':
        nav.push(MaterialPageRoute(
            builder: (_) => CommunityPostScreen(postId: id)));
      case 'plant':
        nav.push(MaterialPageRoute(
            builder: (_) => PlantDetailScreen(plantId: id)));
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

/// First screen the user sees while auth state is being restored. Uses the
/// full-bleed brand image (same asset as the native launch screen, so the
/// hand-off is seamless) with a quiet plant-themed loader near the bottom.
class _Splash extends StatefulWidget {
  const _Splash();

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Matches @color/splash_background in the Android launch theme.
    const ground = Color(0xFF0F2A09);
    return Scaffold(
      backgroundColor: ground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/img/splash.jpg', fit: BoxFit.cover),
          // Bottom scrim so the loader stays legible over any image.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC0F2A09)],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.72),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _GrowingSprout(progress: _c),
                const SizedBox(height: 16),
                Text(
                  'PlantPal',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: PP.bone,
                    letterSpacing: PP.track(17, 0.02),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Getting your garden ready…',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: PP.bone.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A sprout icon that "breathes" inside a soft ring whose sweep tracks the
/// animation — a calmer, on-theme substitute for a spinner.
class _GrowingSprout extends StatelessWidget {
  const _GrowingSprout({required this.progress});
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        // Ease in-out breathing between 0.86 and 1.06.
        final breathe =
            0.86 + 0.20 * (0.5 - 0.5 * math.cos(progress.value * 2 * math.pi));
        return SizedBox(
          width: 58,
          height: 58,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: CircularProgressIndicator(
                  value: null,
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    PP.lime.withValues(alpha: 0.9),
                  ),
                  backgroundColor: PP.bone.withValues(alpha: 0.12),
                ),
              ),
              Transform.scale(
                scale: breathe,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: PP.bone.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.sprout,
                      size: 20, color: PP.bone),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
