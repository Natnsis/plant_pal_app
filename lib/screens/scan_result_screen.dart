import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../api/plantpal_api.dart';
import '../models/models.dart';
import '../theme/pp_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/pp_common.dart';
import 'root_shell.dart';

class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({super.key, required this.result});

  final ScanResult result;

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen>
    with SingleTickerProviderStateMixin {
  final _api = PlantPalApi.instance;
  final _nickname = TextEditingController();
  String _room = 'Living Room';
  static const _rooms = ['Living Room', 'Bedroom', 'Kitchen', 'Balcony', 'Office'];
  bool _saving = false;

  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _nickname.text = widget.result.commonName == 'Identified plant'
        ? ''
        : widget.result.commonName;
  }

  @override
  void dispose() {
    _nickname.dispose();
    _glow.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final r = widget.result;
    if (r.id == 0) {
      showPPSnack(context,
          'This identification has no saved scan id to confirm against.',
          error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.confirmScan(
        r.id,
        nickname: _nickname.text.trim().isEmpty
            ? r.commonName
            : _nickname.text.trim(),
        location: _room,
      );
      if (!mounted) return;
      showPPSnack(context, 'Added to your plants');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => const RootShell(initialIndex: 1)),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (mounted) showPPSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
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
                  if (r.confidencePercent > 0)
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
                              opacity:
                                  Tween(begin: 0.4, end: 1.0).animate(_glow),
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                    color: PP.lime, shape: BoxShape.circle),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${r.confidencePercent}% confidence',
                                style: const TextStyle(
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
            if (r.scientificName.isNotEmpty)
              Text(r.scientificName,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.25,
                      color: PP.inkA(0.45))),
            const SizedBox(height: 2),
            Text(r.commonName,
                style: TextStyle(
                    fontSize: 30,
                    height: 1.05,
                    fontWeight: FontWeight.w600,
                    letterSpacing: PP.track(30, -0.035))),
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
                      for (final room in _rooms)
                        GestureDetector(
                          onTap: () => setState(() => _room = room),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            decoration: BoxDecoration(
                              color: _room == room ? PP.ink : PP.field,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(room,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: _room == room
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
                    '· Watering and fertilizing reminders',
                    '· A journal timeline for this plant',
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
              label: _saving ? 'Saving…' : 'Add to my plants',
              background: _saving ? PP.inkA(0.4) : PP.ink,
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Text('Not this plant? Scan again',
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: PP.inkA(0.55))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
