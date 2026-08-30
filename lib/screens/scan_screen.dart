import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Uint8List, rootBundle;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../api/media_channel.dart';
import '../api/plantpal_api.dart';
import '../theme/pp_theme.dart';
import '../widgets/async_view.dart';
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

  final _api = PlantPalApi.instance;
  bool _diagnoseMode = false;
  bool _busy = false;
  String? _retakeHint;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Real capture via the hand-rolled platform bridge (no image_picker on
  /// this SDK). Falls back to the bundled sample only when the bridge is
  /// genuinely unavailable (desktop builds).
  Future<Uint8List?> _grab({required bool camera}) async {
    try {
      final bytes = camera
          ? await MediaChannel.capture()
          : await MediaChannel.pickFromGallery();
      return bytes; // null = user cancelled
    } on MediaException catch (e) {
      if (!mounted) return null;
      if (e.message.contains('platform')) {
        showPPSnack(context,
            'No camera on this build — sending a sample photo instead.');
        final data = await rootBundle.load('assets/img/sample_plant.jpg');
        return data.buffer.asUint8List();
      }
      showPPSnack(context, e.message, error: true);
      return null;
    }
  }

  Future<void> _run({required bool camera}) async {
    if (_busy) return;
    final bytes = await _grab(camera: camera);
    if (bytes == null || !mounted) return;

    setState(() {
      _busy = true;
      _retakeHint = null;
    });
    try {
      if (_diagnoseMode) {
        final session = await _api.startDiagnosis(bytes);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => DiagnosisScreen(sessionId: session.id)));
        return;
      }

      final result = await _api.scan(bytes);
      if (!mounted) return;
      if (result.retake) {
        setState(() => _retakeHint =
            "Couldn't confidently identify that${result.confidencePercent > 0 ? ' (${result.confidencePercent}% match)' : ''}. "
            'Get closer, fill the frame with the plant, and use daylight.');
        return;
      }
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ScanResultScreen(result: result)));
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isBadRequest && e.message.toLowerCase().contains('blur')) {
        setState(() => _retakeHint =
            'That photo was too blurry to read. Hold still and tap again.');
      } else if (e.isRateLimited) {
        showPPSnack(
            context,
            _diagnoseMode
                ? "You've used today's 5 diagnoses. Try again tomorrow."
                : "You've used today's 3 scans. Try again tomorrow.",
            error: true);
      } else if (e.isServer) {
        setState(() => _retakeHint =
            "The identifier couldn't read that image. Try a clear, well-lit shot of the whole plant.");
      } else {
        showPPSnack(context, e.message, error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                  child: Row(
                    children: [
                      _glassCircle(LucideIcons.chevronLeft,
                          onTap: () => Navigator.of(context).maybePop()),
                      const SizedBox(width: 14),
                      Text(_diagnoseMode ? 'Diagnose a plant' : 'Identify a plant',
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: PP.bone)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: _busy ? null : () => _run(camera: true),
                  child: _frame(),
                ),
                const SizedBox(height: 22),
                Text(
                    _diagnoseMode
                        ? 'Photograph the affected leaves'
                        : 'Frame the whole plant',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: PP.bone)),
                const SizedBox(height: 4),
                Text('Tap the circle to open your camera',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: PP.bone.withValues(alpha: 0.7))),
                if (_retakeHint != null) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: PP.amberBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.triangleAlert,
                              size: 18, color: PP.amberFg),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_retakeHint!,
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.45,
                                    fontWeight: FontWeight.w600,
                                    color: PP.amberFg)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 30),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                setState(() => _diagnoseMode = false),
                            child: _modePill('Identify', active: !_diagnoseMode),
                          ),
                          const SizedBox(width: 9),
                          GestureDetector(
                            onTap: () => setState(() => _diagnoseMode = true),
                            child: _modePill('Diagnose', active: _diagnoseMode),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _squareGlass(LucideIcons.image, 'Gallery',
                              onTap: _busy ? null : () => _run(camera: false)),
                          _shutter(),
                          // Balances the row so the shutter stays centred.
                          const SizedBox(width: 54),
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
        alignment: Alignment.center,
        children: [
          _corner(top: 0, left: 0, tl: true),
          _corner(top: 0, right: 0, tr: true),
          _corner(bottom: 0, left: 0, bl: true),
          _corner(bottom: 0, right: 0, br: true),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_busy ? LucideIcons.loader : LucideIcons.camera,
                  size: 64, color: PP.bone.withValues(alpha: 0.9)),
              const SizedBox(height: 10),
              Text(_busy ? 'Reading…' : 'Tap to open camera',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: PP.bone.withValues(alpha: 0.8))),
            ],
          ),
          if (!_busy)
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = (_c.value - 0.5) * 2;
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

  Widget _squareGlass(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: PP.bone.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 22, color: PP.bone),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: PP.bone.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _shutter() {
    return GestureDetector(
      onTap: _busy ? null : () => _run(camera: true),
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          color: PP.bone,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: PP.bone.withValues(alpha: 0.28),
                blurRadius: 0,
                spreadRadius: 6),
          ],
        ),
        child: Center(
          child: Container(
            width: 66,
            height: 66,
            decoration:
                const BoxDecoration(color: PP.lime, shape: BoxShape.circle),
            child: _busy
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                        strokeWidth: 2.6, color: PP.ink),
                  )
                : Icon(_diagnoseMode ? LucideIcons.stethoscope : LucideIcons.camera,
                    size: 28, color: PP.ink),
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
