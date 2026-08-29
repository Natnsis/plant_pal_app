import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/pp_theme.dart';
import '../widgets/pp_common.dart';
import 'community_screen.dart';
import 'states_screen.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Map<String, bool> _notif = {
    'push': true,
    'summary': true,
    'sound': false,
    'vibrate': true,
  };

  static const _settings = [
    ('push', 'Push notifications', 'Watering, feeding, diagnosis'),
    ('summary', 'Daily summary', 'One digest each morning'),
    ('sound', 'Sound alerts', 'Chime with each reminder'),
    ('vibrate', 'Vibration', 'Haptic nudge'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
        children: [
          _profileCard(),
          const SizedBox(height: 26),
          Text('Notifications',
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  letterSpacing: PP.track(19, -0.025))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: [
                for (final s in _settings)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: PP.inkA(0.07)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _settingLabel(s.$2, s.$3)),
                        PPToggle(
                          value: _notif[s.$1]!,
                          onChanged: (v) => setState(() => _notif[s.$1] = v),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    children: [
                      Expanded(
                        child: _settingLabel(
                            'Preferred time', 'When daily reminders arrive'),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: PP.field,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text('08:00',
                            style: TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text('More',
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  letterSpacing: PP.track(19, -0.025))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: [
                _moreRow(LucideIcons.users, 'Community', border: true,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const CommunityScreen()))),
                _moreRow(LucideIcons.layers, 'Component states', border: true,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const StatesScreen()))),
                _moreRow(LucideIcons.circleHelp, 'Help & plant guides',
                    border: true),
                _moreRow(LucideIcons.shield, 'Privacy & data', border: true),
                _moreRow(LucideIcons.logOut, 'Log out',
                    danger: true,
                    border: false,
                    onTap: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                        (_) => false)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingLabel(String label, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                letterSpacing: PP.track(14.5, -0.01))),
        const SizedBox(height: 1),
        Text(sub,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: PP.inkA(0.45))),
      ],
    );
  }

  Widget _profileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PP.forest,
        borderRadius: BorderRadius.circular(36),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const InitialsAvatar('AT', size: 62, radius: 22, fontSize: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Abel Tesfaye',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: PP.track(20, -0.025),
                            color: PP.bone)),
                    const SizedBox(height: 2),
                    Text('abel@pitrontech.et',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: PP.bone.withValues(alpha: 0.65))),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: PP.bone.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(LucideIcons.pencil, size: 17, color: PP.bone),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: _PStat('12', 'Day streak')),
              SizedBox(width: 10),
              Expanded(child: _PStat('148', 'Tasks done')),
              SizedBox(width: 10),
              Expanded(child: _PStat('48', 'Journal')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _moreRow(IconData icon, String label,
      {bool border = true, bool danger = false, VoidCallback? onTap}) {
    final color = danger ? PP.danger : PP.forest;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: border
              ? Border(bottom: BorderSide(color: PP.inkA(0.07)))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: danger ? PP.danger : PP.ink)),
            ),
            if (!danger)
              Icon(LucideIcons.chevronRight, size: 17, color: PP.inkA(0.35)),
          ],
        ),
      ),
    );
  }
}

class _PStat extends StatelessWidget {
  const _PStat(this.value, this.label);
  final String value;
  final String label;

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
          Text(value,
              style: const TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w700, color: PP.bone)),
          const SizedBox(height: 1),
          Text(label,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: PP.bone.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}
