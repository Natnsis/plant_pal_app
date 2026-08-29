import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/pp_theme.dart';
import '../widgets/pp_common.dart';
import 'root_shell.dart';

class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({super.key});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen>
    with SingleTickerProviderStateMixin {
  final _nickname = TextEditingController(text: 'Figgy');
  String _room = 'Living Room';
  static const _rooms = ['Living Room', 'Bedroom', 'Balcony', '+ New'];

  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _nickname.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PP.bone,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
          children: [
            Row(
              children: [
                SquircleIconButton(
                  icon: LucideIcons.x,
                  radius: 16,
                  size: 44,
                  iconSize: 19,
                  background: PP.card.withValues(alpha: 0.8),
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const Expanded(
                  child: Center(
                    child: Text('Identified',
                        style: TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 230,
              child: Stack(
                children: [
                  PlantImage(
                      height: 230,
                      width: double.infinity,
                      radius: 32,
                      iconSize: 130),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: PP.ink,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FadeTransition(
                            opacity: Tween(begin: 0.4, end: 1.0).animate(_glow),
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                  color: PP.lime, shape: BoxShape.circle),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('97% confidence',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: PP.bone)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('Ficus lyrata',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.25,
                    color: PP.inkA(0.45))),
            const SizedBox(height: 2),
            Text('Fiddle Leaf Fig',
                style: TextStyle(
                    fontSize: 30,
                    height: 1.05,
                    fontWeight: FontWeight.w600,
                    letterSpacing: PP.track(30, -0.035))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                Tag('Medium care'),
                Tag('Bright indirect'),
                Tag('Water every 7d'),
              ],
            ),
            const SizedBox(height: 16),
            SurfaceCard(
              radius: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Name it and place it',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nickname,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: PP.field,
                      hintText: 'Nickname',
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in _rooms)
                        GestureDetector(
                          onTap: () => setState(() => _room = r),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            decoration: BoxDecoration(
                              color: _room == r ? PP.ink : PP.field,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(r,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: _room == r
                                        ? PP.bone
                                        : PP.inkA(0.6))),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: PP.pale1,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_rounded, size: 18, color: PP.forest),
                      SizedBox(width: 10),
                      Text("We'll set up automatically",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: PP.forest)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final line in const [
                    '· Care plan with light, soil and temperature',
                    '· Watering reminder every 7 days at 8:00',
                    '· Monthly fertilizing reminder',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Text(line,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: PP.forest)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Add to my plants',
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const RootShell(initialIndex: 1)),
                (_) => false,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text('Not this plant? See other matches',
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: PP.inkA(0.55))),
            ),
          ],
        ),
      ),
    );
  }
}
