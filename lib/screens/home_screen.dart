import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/demo.dart';
import '../theme/pp_theme.dart';
import '../widgets/pp_common.dart';
import 'notifications_screen.dart';
import 'plant_detail_screen.dart';
import 'reminders_screen.dart';
import 'weather_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Map<String, bool> _done = {
    for (final t in demoTasks) t.key: t.initiallyDone,
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 120),
        children: [
          _header(context),
          const SizedBox(height: 22),
          Text('Two plants need\nyou today.',
              style: TextStyle(
                  fontSize: 33,
                  height: 1.04,
                  fontWeight: FontWeight.w700,
                  letterSpacing: PP.track(33))),
          const SizedBox(height: 18),
          _healthCard(),
          const SizedBox(height: 26),
          SectionHeader('Today’s care',
              trailing: 'All tasks',
              onTrailingTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const RemindersScreen()))),
          const SizedBox(height: 12),
          for (final t in demoTasks) ...[
            TaskTile(
              title: t.title,
              subtitle: t.sub,
              done: _done[t.key]!,
              onToggle: () => setState(() => _done[t.key] = !_done[t.key]!),
              trailing: _chip(t, _done[t.key]!),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
          SectionHeader('Your plants', trailing: 'See all 6'),
          const SizedBox(height: 12),
          SizedBox(
            height: 244,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: const [
                _MiniPlantCard(
                  name: 'Snake Plant',
                  room: 'Living Room',
                  badge: 'Water in 2d',
                  water: '35%',
                  sunlight: '80%',
                ),
                SizedBox(width: 12),
                _MiniPlantCard(
                  name: 'Peace Lily',
                  room: 'Home Office',
                  badge: 'Needs water',
                  badgeAccent: true,
                  dark: true,
                  water: '18%',
                  sunlight: '45%',
                ),
                SizedBox(width: 12),
                _MiniPlantCard(name: 'Aloe Vera', room: 'Kitchen Window'),
              ],
            ),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WeatherScreen())),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        color: PP.pale1,
                        borderRadius: BorderRadius.circular(18)),
                    child: const Icon(LucideIcons.sun,
                        size: 24, color: PP.forest),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Addis Ababa · Partly sunny',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: PP.inkA(0.5))),
                        const SizedBox(height: 2),
                        Text('21° — good day to water',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: PP.track(15, -0.015))),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight,
                      size: 18, color: PP.inkA(0.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        const InitialsAvatar('AT'),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good morning',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: PP.inkA(0.5))),
            Text('Abel',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: PP.track(16, -0.02))),
          ],
        ),
        const Spacer(),
        SquircleIconButton(icon: LucideIcons.search, onTap: () {}),
        const SizedBox(width: 9),
        SquircleIconButton(
          icon: LucideIcons.bell,
          badge: true,
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        ),
      ],
    );
  }

  Widget _healthCard() {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Tag('Care streak · 12 days',
                  background: PP.pale1,
                  foreground: PP.forest,
                  icon: LucideIcons.flame,
                  fontSize: 12,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 7)),
              Text('3 of 5 done',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: PP.inkA(0.45))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text.rich(
                TextSpan(
                  text: '92',
                  style: TextStyle(
                      fontSize: 52,
                      height: 0.9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: PP.track(52, -0.05)),
                  children: const [
                    TextSpan(
                        text: '%',
                        style: TextStyle(fontSize: 24, letterSpacing: 0)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text('Garden health\nup 4% this week',
                    style: TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: PP.inkA(0.55))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < healthBarValues.length; i++) ...[
                  if (i != 0) const SizedBox(width: 5),
                  Expanded(
                    child: Container(
                      height: 44 * healthBarValues[i] / 100,
                      decoration: BoxDecoration(
                        color: i >= healthBarValues.length - 3
                            ? PP.forest
                            : (i.isOdd
                                ? const Color(0xFFC6D9AC)
                                : const Color(0xFFD6E3C2)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(CareTask t, bool done) {
    final bg = done ? PP.pale4 : t.chipBg;
    final fg = done ? PP.inkA(0.5) : t.chipFg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        (done ? 'Done' : t.chip).toUpperCase(),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.55,
            color: fg),
      ),
    );
  }
}

class _MiniPlantCard extends StatelessWidget {
  const _MiniPlantCard({
    required this.name,
    required this.room,
    this.badge,
    this.badgeAccent = false,
    this.dark = false,
    this.water,
    this.sunlight,
  });

  final String name;
  final String room;
  final String? badge;
  final bool badgeAccent;
  final bool dark;
  final String? water;
  final String? sunlight;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? PP.bone : PP.ink;
    final subFg = dark ? PP.bone.withValues(alpha: 0.55) : PP.inkA(0.45);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PlantDetailScreen())),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dark ? PP.forest : Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 124,
              child: Stack(
                children: [
                  PlantImage(height: 124, width: double.infinity, dark: dark, iconSize: 66),
                  if (badge != null)
                    Positioned(
                      top: 9,
                      left: 9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: badgeAccent
                              ? PP.lime
                              : Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(badge!,
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: badgeAccent ? PP.ink : PP.ink)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: PP.track(15.5, -0.02),
                          color: fg)),
                  Text(room,
                      style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: subFg)),
                  if (water != null && sunlight != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _stat(water!, 'Water', fg, subFg),
                        Container(
                          width: 1,
                          height: 28,
                          margin: const EdgeInsets.symmetric(horizontal: 14),
                          color: dark
                              ? PP.bone.withValues(alpha: 0.2)
                              : PP.inkA(0.1),
                        ),
                        _stat(sunlight!, 'Sunlight', fg, subFg),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color fg, Color subFg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: fg)),
        Text(label,
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w600, color: subFg)),
      ],
    );
  }
}
