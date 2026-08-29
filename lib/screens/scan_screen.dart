import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/pp_theme.dart';
import 'diagnosis_screen.dart';
import 'scan_result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF20301F),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFC7D9AC), Color(0xFF93A87E), Color(0xFF3B4C36)],
                  stops: [0.0, 0.42, 1.0],
                ),
              ),
            ),
          ),
          Center(
            child: Icon(LucideIcons.sprout,
                size: 250, color: PP.bone.withValues(alpha: 0.55)),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _glassCircle(LucideIcons.chevronLeft,
                          onTap: () => Navigator.of(context).maybePop()),
                      const Text('Identify plant',
                          style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: PP.bone)),
                      _glassCircle(LucideIcons.settings2),
                    ],
                  ),
                ),
                const SizedBox(height: 34),
                _frame(),
                const SizedBox(height: 22),
                const Text('Frame the whole plant',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: PP.bone)),
                const SizedBox(height: 4),
                Text('Include leaves and pot for a better match',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: PP.bone.withValues(alpha: 0.7))),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 30),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _modePill('Identify', active: true),
                          const SizedBox(width: 9),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (_) => const DiagnosisScreen())),
                            child: _modePill('Diagnose', active: false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _squareGlass(LucideIcons.image),
                          _shutter(),
                          _squareGlass(LucideIcons.scanLine),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _frame() {
    return SizedBox(
      width: 290,
      height: 290,
      child: Stack(
        children: [
          _corner(top: 0, left: 0, tl: true),
          _corner(top: 0, right: 0, tr: true),
          _corner(bottom: 0, left: 0, bl: true),
          _corner(bottom: 0, right: 0, br: true),
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = (_c.value - 0.5) * 2; // -1..1
              return Align(
                alignment: Alignment(0, t * 0.84),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      PP.lime.withValues(alpha: 0),
                      PP.lime,
                      PP.lime.withValues(alpha: 0),
                    ]),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _corner({
    double? top,
    double? left,
    double? right,
    double? bottom,
    bool tl = false,
    bool tr = false,
    bool bl = false,
    bool br = false,
  }) {
    const side = BorderSide(color: PP.bone, width: 3);
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          border: Border(
            top: (tl || tr) ? side : BorderSide.none,
            bottom: (bl || br) ? side : BorderSide.none,
            left: (tl || bl) ? side : BorderSide.none,
            right: (tr || br) ? side : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: tl ? const Radius.circular(22) : Radius.zero,
            topRight: tr ? const Radius.circular(22) : Radius.zero,
            bottomLeft: bl ? const Radius.circular(22) : Radius.zero,
            bottomRight: br ? const Radius.circular(22) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _glassCircle(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: PP.ink.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 19, color: PP.bone),
      ),
    );
  }

  Widget _squareGlass(IconData icon) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: PP.bone.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, size: 22, color: PP.bone),
    );
  }

  Widget _shutter() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ScanResultScreen())),
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          color: PP.bone,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: PP.bone.withValues(alpha: 0.28), blurRadius: 0, spreadRadius: 6),
          ],
        ),
        child: Center(
          child: Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(color: PP.lime, shape: BoxShape.circle),
            child: const Icon(LucideIcons.scan, size: 28, color: PP.ink),
          ),
        ),
      ),
    );
  }

  Widget _modePill(String label, {required bool active}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: active ? PP.bone : PP.ink.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? PP.ink : PP.bone)),
    );
  }
}
