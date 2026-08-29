import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../api/plantpal_api.dart';
import '../models/models.dart';
import '../state/auth_scope.dart';
import '../theme/pp_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/pp_common.dart';
import 'community_screen.dart';
import 'states_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = PlantPalApi.instance;
  NotificationSettings? _settings;
  final _savingKeys = <String>{};

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.user;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: PP.forest,
        onRefresh: () async {
          await auth.refreshUser();
          setState(() => _settings = null);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
          children: [
            _profileCard(user),
            const SizedBox(height: 26),
            Text('Notifications',
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    letterSpacing: PP.track(19, -0.025))),
            const SizedBox(height: 12),
            AsyncView<NotificationSettings>(
              key: ValueKey(_settings == null),
              load: () async {
                _settings ??= await _api.notificationSettings();
                return _settings!;
              },
              builder: (context, s, reload) => _settingsCard(s),
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
                  _moreRow(LucideIcons.users, 'Community',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const CommunityScreen()))),
                  _moreRow(LucideIcons.layers, 'Component states',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const StatesScreen()))),
                  _moreRow(LucideIcons.circleHelp, 'Help & plant guides'),
                  _moreRow(LucideIcons.shield, 'Privacy & data'),
                  _moreRow(LucideIcons.logOut, 'Log out',
                      danger: true,
                      border: false,
                      onTap: () => AuthScope.of(context).logout()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsCard(NotificationSettings s) {
    final rows = <(String, String, String, bool, NotificationSettings Function(bool))>[
      (
        'push',
        'Push notifications',
        'Watering, feeding, diagnosis',
        s.notificationEnabled,
        (v) => s.copyWith(notificationEnabled: v),
      ),
      (
        'summary',
        'Daily summary',
        'One digest each morning',
        s.dailySummaryEnabled,
        (v) => s.copyWith(dailySummaryEnabled: v),
      ),
      (
        'sound',
        'Sound alerts',
        'Chime with each reminder',
        s.soundAlertEnabled,
        (v) => s.copyWith(soundAlertEnabled: v),
      ),
      (
        'vibrate',
        'Vibration',
        'Haptic nudge',
        s.vibrationEnabled,
        (v) => s.copyWith(vibrationEnabled: v),
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          for (final r in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: PP.inkA(0.07))),
              ),
              child: Row(
                children: [
                  Expanded(child: _settingLabel(r.$2, r.$3)),
                  Opacity(
                    opacity: _savingKeys.contains(r.$1) ? 0.5 : 1,
                    child: PPToggle(
                      value: r.$4,
                      onChanged: _savingKeys.contains(r.$1)
                          ? null
                          : (v) => _save(r.$1, r.$5(v)),
                    ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: PP.field,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(s.preferredTimeLabel,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(String key, NotificationSettings next) async {
    setState(() {
      _savingKeys.add(key);
      _settings = next; // optimistic
    });
    try {
      final saved = await _api.updateNotificationSettings(next);
      setState(() => _settings = saved);
    } on ApiException catch (e) {
      if (mounted) showPPSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _savingKeys.remove(key));
    }
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

  Widget _profileCard(UserProfile? user) {
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
              InitialsAvatar(user?.initials ?? '🌱',
                  size: 62, radius: 22, fontSize: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? 'PlantPal user',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: PP.track(20, -0.025),
                            color: PP.bone)),
                    const SizedBox(height: 2),
                    Text(user?.email ?? '',
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
            children: [
              Expanded(
                  child: _PStat('${user?.careStreakDays ?? 0}', 'Day streak')),
              const SizedBox(width: 10),
              Expanded(child: _PStat('${user?.tasksDone ?? 0}', 'Tasks done')),
              const SizedBox(width: 10),
              Expanded(
                  child: _PStat('${user?.journalEntries ?? 0}', 'Journal')),
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
