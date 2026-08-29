import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/pp_theme.dart';
import '../widgets/pp_common.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
                    child: Text('Notifications',
                        style: TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w600)),
                  ),
                ),
                Text('Read all',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: PP.forest)),
              ],
            ),
            const SizedBox(height: 18),
            _NotifTile(
              icon: LucideIcons.droplet,
              iconBg: PP.pale1,
              iconFg: PP.forest,
              title: 'Peace Lily needs water',
              subtitle: 'Scheduled for 08:00 · Home Office',
              time: '2m',
              unread: true,
              actions: const [('Mark done', true), ('Snooze 1h', false)],
            ),
            const SizedBox(height: 10),
            _NotifTile(
              icon: LucideIcons.sprout,
              iconBg: PP.pale1,
              iconFg: PP.forest,
              title: 'Diagnosis result ready',
              subtitle: 'Golden Pothos · leaf-tip scorch, moderate',
              time: '1h',
              unread: true,
            ),
            const SizedBox(height: 10),
            _NotifTile(
              icon: LucideIcons.trendingUp,
              iconBg: PP.amberBg,
              iconFg: PP.amberFg,
              title: '12-day care streak',
              subtitle: 'Your longest yet — keep it going.',
              time: 'Yesterday',
              muted: true,
            ),
            const SizedBox(height: 10),
            _NotifTile(
              icon: LucideIcons.info,
              iconBg: const Color(0xFFE1E7D5),
              iconFg: PP.inkA(0.6),
              title: 'Care tip: rotate your pots',
              subtitle: 'A quarter turn weekly keeps growth even.',
              time: '2d',
              muted: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.time,
    this.unread = false,
    this.muted = false,
    this.actions = const [],
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final String time;
  final bool unread;
  final bool muted;
  final List<(String, bool)> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: muted ? PP.card.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: unread
            ? const Border(left: BorderSide(color: PP.lime, width: 4))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, size: 19, color: iconFg),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: PP.track(14.5, -0.01))),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: PP.inkA(0.5))),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      for (final a in actions) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 8),
                          decoration: BoxDecoration(
                            color: a.$2 ? PP.ink : PP.field,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(a.$1,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: a.$2 ? PP.bone : PP.inkA(0.6))),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(time,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: PP.inkA(0.4))),
        ],
      ),
    );
  }
}
