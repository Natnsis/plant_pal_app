import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/pp_theme.dart';
import '../widgets/pp_common.dart';
import 'diagnosis_screen.dart';

class PlantDetailScreen extends StatefulWidget {
  const PlantDetailScreen({super.key});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  static const _tabs = ['Care', 'Growth', 'Journal', 'Info'];
  String _tab = 'Care';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PP.bone,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _hero(context),
            Transform.translate(
              offset: const Offset(0, -24),
              child: _sheet(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return SizedBox(
      height: 440,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE7ECDB), Color(0xFFD3E0BD)],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Icon(LucideIcons.sprout,
                  size: 290, color: PP.forest.withValues(alpha: 0.4)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RoundIconButton(
                    icon: LucideIcons.chevronLeft,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const RoundIconButton(icon: LucideIcons.moreVertical),
                ],
              ),
            ),
          ),
          const Positioned(
            top: 132,
            right: 24,
            child: _GlassStat(
              icon: LucideIcons.droplet,
              label: 'Moisture\nlevel',
              value: '73%',
            ),
          ),
          const Positioned(
            top: 196,
            left: 22,
            child: _GlassStat(
              icon: LucideIcons.sprout,
              label: 'Growth\nstage',
              value: 'Mature',
            ),
          ),
          const Positioned(
            top: 286,
            right: 46,
            child: _GlassStat(
              icon: LucideIcons.sun,
              label: 'Light\nabsorption',
              value: '80%',
              light: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheet(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: PP.bone,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(38),
          bottom: Radius.circular(46),
        ),
        boxShadow: [
          BoxShadow(
            color: PP.inkA(0.10),
            blurRadius: 40,
            offset: const Offset(0, -18),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(0, -46),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: PP.bone.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.hand, size: 16, color: PP.forest),
                      SizedBox(width: 9),
                      Text('Easy care',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: PP.inkA(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.heart, size: 20, color: PP.forest),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fiddle Leaf Fig',
                              style: TextStyle(
                                  fontSize: 27,
                                  height: 1.05,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: PP.track(27, -0.035))),
                          const SizedBox(height: 2),
                          Text('Living Room',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                  color: PP.inkA(0.5))),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Health',
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: PP.inkA(0.45))),
                        Text('94',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: PP.track(24, -0.03),
                                color: PP.forest)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    Tag('Shade-lover'),
                    Tag('Pet-friendly'),
                    Tag('Air purifier'),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: PP.pale4,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(
                    children: [
                      for (final t in _tabs)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tab = t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: _tab == t
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              alignment: Alignment.center,
                              child: Text(t,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _tab == t
                                          ? PP.ink
                                          : PP.inkA(0.5))),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 96),
                  child: _panel(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: PrimaryButton(label: 'Log watering'),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const DiagnosisScreen())),
                      child: Container(
                        width: 62,
                        height: 58,
                        decoration: BoxDecoration(
                          color: PP.pale2,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child:
                            const Icon(LucideIcons.stethoscope, size: 21, color: PP.forest),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel() {
    switch (_tab) {
      case 'Growth':
        return _grid(const [
          _Cell('Height', '112 cm', 'in 30d +6 cm'),
          _Cell('New leaves', '3', 'this month'),
          _Cell('Rate', 'Steady'),
          _Cell('Repot', 'in 4 months'),
        ]);
      case 'Journal':
        return Column(
          children: const [
            _JournalRow('Watered', 'Aug 26 · 250 ml'),
            SizedBox(height: 8),
            _JournalRow('Photo note', 'Aug 21 · new leaf unfurling'),
            SizedBox(height: 8),
            _JournalRow('Fertilized', 'Aug 12 · liquid feed'),
          ],
        );
      case 'Info':
        return _grid(const [
          _Cell('Species', 'Ficus lyrata'),
          _Cell('Difficulty', 'Medium'),
          _Cell('Soil', 'Peat-based'),
          _Cell('Toxicity', 'Pet-safe'),
        ]);
      default:
        return _grid(const [
          _Cell('Watering', 'Every 7d', '250 ml, top soil'),
          _Cell('Light', 'Bright indirect'),
          _Cell('Temperature', '18–24 °C'),
          _Cell('Humidity', '50–60 %'),
        ]);
    }
  }

  Widget _grid(List<_Cell> cells) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.85,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: cells,
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.label, this.value, [this.sub]);
  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: PP.inkA(0.45))),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: PP.track(19, -0.02))),
          if (sub != null) ...[
            const SizedBox(height: 1),
            Text(sub!,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: PP.inkA(0.45))),
          ],
        ],
      ),
    );
  }
}

class _JournalRow extends StatelessWidget {
  const _JournalRow(this.title, this.date);
  final String title;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: PP.forest, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text(date,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: PP.inkA(0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassStat extends StatelessWidget {
  const _GlassStat({
    required this.icon,
    required this.label,
    required this.value,
    this.light = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final fg = light ? PP.ink : PP.bone;
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: light
            ? PP.bone.withValues(alpha: 0.72)
            : PP.forest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: light ? PP.lime.withValues(alpha: 0.9) : PP.lime,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: PP.lime.withValues(alpha: 0.28),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11.5,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: fg)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}
