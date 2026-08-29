import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/demo.dart';
import '../theme/pp_theme.dart';
import '../widgets/pp_common.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late final Map<String, bool> _done = {
    for (final t in demoTasks) t.key: t.initiallyDone,
  };

  static const _days = [
    ('Fri', '29'),
    ('Sat', '30'),
    ('Sun', '31'),
    ('Mon', '01'),
    ('Tue', '02'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PP.bone,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: DisplayTitle('Care\nschedule')),
                SquircleIconButton(
                  icon: LucideIcons.plus,
                  background: PP.ink,
                  foreground: PP.bone,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                for (var i = 0; i < _days.length; i++) ...[
                  if (i != 0) const SizedBox(width: 7),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: i == 0 ? PP.ink : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(_days[i].$1,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: i == 0
                                      ? PP.bone.withValues(alpha: 0.6)
                                      : PP.inkA(0.45))),
                          const SizedBox(height: 2),
                          Text(_days[i].$2,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: i == 0 ? PP.bone : PP.ink)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 26),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Today',
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        letterSpacing: PP.track(19, -0.025))),
                Text('2 of 3 left',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: PP.inkA(0.45))),
              ],
            ),
            const SizedBox(height: 12),
            for (final t in demoTasks) ...[
              TaskTile(
                title: t.title,
                subtitle: t.sub,
                done: _done[t.key]!,
                onToggle: () => setState(() => _done[t.key] = !_done[t.key]!),
                trailing: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: PP.inkA(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.clock,
                      size: 15, color: PP.inkA(0.55)),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 16),
            Text('This week',
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    letterSpacing: PP.track(19, -0.025))),
            const SizedBox(height: 12),
            _weekRow(LucideIcons.droplet, 'Water Snake Plant',
                'Sun 31 · 08:00', '2d'),
            const SizedBox(height: 10),
            _weekRow(LucideIcons.house, 'Repot Aloe Vera', 'Tue 02 · 18:00', '4d'),
          ],
        ),
      ),
    );
  }

  Widget _weekRow(IconData icon, String title, String sub, String due) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: PP.pale1, borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, size: 19, color: PP.forest),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: PP.track(15, -0.01))),
                Text(sub,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: PP.inkA(0.5))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: PP.field,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(due.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.55,
                    color: PP.inkA(0.5))),
          ),
        ],
      ),
    );
  }
}
