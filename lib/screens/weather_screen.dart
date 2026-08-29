import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/pp_theme.dart';
import '../widgets/pp_common.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PP.bone,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
          children: [
            Row(
              children: [
                SquircleIconButton(
                  icon: LucideIcons.chevronLeft,
                  background: PP.card.withValues(alpha: 0.8),
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const Expanded(
                  child: Center(
                    child: Text('Addis Ababa',
                        style: TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 42),
              ],
            ),
            const SizedBox(height: 16),
            _bigCard(),
            const SizedBox(height: 14),
            _nextHours(),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: PP.pale2,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.sprout, size: 19, color: PP.forest),
                      const SizedBox(width: 10),
                      Text('WHAT THIS MEANS',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: PP.forest)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Dry air today. Mist the Peace Lily and move the Aloe back from the window between 12:00 and 15:00 — the UV peak can scorch its tips.',
                    style: TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                        color: PP.forest),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _forecastRow('Sat', LucideIcons.cloud, 0.18, 0.26, '14°', '23°'),
            const SizedBox(height: 9),
            _forecastRow(
                'Sun', LucideIcons.cloudDrizzle, 0.12, 0.34, '13°', '20°'),
            const SizedBox(height: 9),
            _forecastRow('Mon', LucideIcons.sun, 0.22, 0.16, '15°', '25°'),
          ],
        ),
      ),
    );
  }

  Widget _bigCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -1),
          end: Alignment(0.5, 1),
          colors: [PP.forestMid, PP.forest],
        ),
        borderRadius: BorderRadius.circular(36),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('21°',
                        style: TextStyle(
                            fontSize: 64,
                            height: 0.9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: PP.track(64, -0.05),
                            color: PP.bone)),
                    const SizedBox(height: 8),
                    Text('Partly sunny · feels 22°',
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: PP.bone.withValues(alpha: 0.75))),
                  ],
                ),
              ),
              const Icon(LucideIcons.sun, size: 56, color: PP.lime),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: const [
              Expanded(child: _WStat('Humidity', '58%')),
              SizedBox(width: 10),
              Expanded(child: _WStat('UV index', '6')),
              SizedBox(width: 10),
              Expanded(child: _WStat('Rain', '20%')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nextHours() {
    const hours = [
      ('10:00', '21°'),
      ('12:00', '23°'),
      ('14:00', '24°'),
      ('16:00', '22°'),
      ('18:00', '19°'),
    ];
    return SurfaceCard(
      radius: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Next hours',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final h in hours)
                Column(
                  children: [
                    Text(h.$1,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: PP.inkA(0.45))),
                    const SizedBox(height: 8),
                    Text(h.$2,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _forecastRow(String day, IconData icon, double left, double right,
      String lo, String hi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(day,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 14),
          Icon(icon, size: 19, color: PP.forest),
          const SizedBox(width: 14),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                return Stack(
                  children: [
                    Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: PP.pale1,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    Positioned(
                      left: w * left,
                      right: w * right,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: PP.forest,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 14),
          Text('$lo $hi',
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _WStat extends StatelessWidget {
  const _WStat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: PP.bone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: PP.bone.withValues(alpha: 0.6))),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w700, color: PP.bone)),
        ],
      ),
    );
  }
}
