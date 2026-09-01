import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../api/media_channel.dart';
import '../api/notif_channel.dart';
import '../api/plantpal_api.dart';
import '../models/models.dart';
import '../state/auth_scope.dart';
import '../theme/pp_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/pp_common.dart';
import '../widgets/pp_sheets.dart';
import 'community_screen.dart';
import 'help_screen.dart';
import 'privacy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  final _api = PlantPalApi.instance;
  NotificationSettings? _settings;
  final _savingKeys = <String>{};
  int _settingsKey = 0;
  NotifPermission _perm = NotifPermission.granted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPerm();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadPerm();
  }

  Future<void> _loadPerm() async {
    final p = await NotifChannel.status();
    if (mounted) setState(() => _perm = p);
  }

  bool get _osNotifsOn => _perm == NotifPermission.granted;

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
          setState(() {
            _settings = null;
            _settingsKey++;
          });
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
              key: ValueKey(_settingsKey),
              load: () async {
                _settings ??= await _api.notificationSettings();
                return _settings!;
              },
              // Always render from _settings so optimistic toggle updates in
              // _save show immediately (the AsyncView's own value is only the
              // first load).
              builder: (context, s, reload) => _settingsCard(_settings ?? s),
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
                  _moreRow(LucideIcons.circleHelp, 'Help & plant guides',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const HelpScreen()))),
                  _moreRow(LucideIcons.shield, 'Privacy & data',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const PrivacyScreen()))),
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
    return Column(
      children: [
        if (!_osNotifsOn) _permBanner(),
        Container(
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
                    // Sound / vibration / daily-summary only do anything if
                    // the OS lets us post notifications at all.
                    opacity: (_savingKeys.contains(r.$1) ||
                            (!_osNotifsOn && r.$1 != 'push'))
                        ? 0.4
                        : 1,
                    child: PPToggle(
                      value: r.$4,
                      onChanged: _savingKeys.contains(r.$1)
                          ? null
                          : (!_osNotifsOn && r.$1 != 'push')
                              ? (_) => _openNotifSettings()
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
                Opacity(
                  opacity: _savingKeys.contains('preferred') ||
                          (!_osNotifsOn)
                      ? 0.4
                      : 1,
                  child: GestureDetector(
                    onTap: _savingKeys.contains('preferred')
                        ? null
                        : () => _pickPreferredTime(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: PP.field,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(s.preferredTimeLabel,
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 6),
                          Icon(LucideIcons.clock,
                              size: 14, color: PP.inkA(0.5)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ],
    );
  }

  Widget _permBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PP.amberBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.bellOff, size: 20, color: PP.amberFg),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _perm == NotifPermission.denied
                  ? 'Notifications are turned off for PlantPal in your phone settings.'
                  : 'Allow notifications so reminders reach your phone.',
              style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: PP.amberFg),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _openNotifSettings,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: PP.amberFg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                  _perm == NotifPermission.deniedCanRetry ? 'Allow' : 'Settings',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PP.amberBg)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openNotifSettings() async {
    if (_perm == NotifPermission.deniedCanRetry) {
      final r = await NotifChannel.requestPermission();
      if (mounted) setState(() => _perm = r);
      if (r == NotifPermission.granted) return;
    }
    await NotifChannel.openSettings();
  }

  Future<void> _pickPreferredTime(NotificationSettings s) async {
    final current = s.preferredTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: current != null
          ? TimeOfDay(hour: current.hour, minute: current.minute)
          : const TimeOfDay(hour: 8, minute: 0),
      helpText: 'When should daily reminders arrive?',
    );
    if (picked == null) return;
    // Model only reads hour/minute off this; the date part is arbitrary.
    final asDate = DateTime(2000, 1, 1, picked.hour, picked.minute);
    await _save('preferred', s.copyWith(preferredTime: asDate));
  }

  Future<void> _save(String key, NotificationSettings next) async {
    // Turning push notifications on triggers the real OS permission prompt
    // (Android 13+, via the native bridge). If the user declines it we still
    // save the preference — the in-app inbox banner keeps working — but real
    // phone notifications won't fire until they allow it in Settings.
    if (key == 'push' && next.notificationEnabled) {
      final result = await NotifChannel.requestPermission();
      if (result != NotifPermission.granted && mounted) {
        showPPSnack(
          context,
          'Saved. Turn on notifications for PlantPal in your phone settings to '
          'get reminders on your lock screen.',
        );
      }
    }

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

  Future<void> _editProfile(UserProfile user) async {
    final name = TextEditingController(text: user.fullName);
    final action = await showPPSheet<String>(
      context,
      title: 'Edit profile',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Name', style: TextStyle(fontSize: 12.5, color: PP.inkA(0.5))),
          const SizedBox(height: 6),
          PPSheetField(controller: name, hint: 'Your name'),
          const SizedBox(height: 16),
          Text('Profile photo',
              style: TextStyle(fontSize: 12.5, color: PP.inkA(0.5))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _pickBtn(ctx, LucideIcons.camera, 'Camera', 'camera'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _pickBtn(ctx, LucideIcons.image, 'Gallery', 'gallery'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Save name',
            background: PP.forest,
            onPressed: () => Navigator.of(ctx).pop('name'),
          ),
        ],
      ),
    );
    if (action == null || !mounted) return;

    if (action == 'name') {
      try {
        await AuthScope.of(context).updateProfile(
          fullName: name.text.trim().isEmpty ? null : name.text.trim(),
        );
        if (mounted) showPPSnack(context, 'Profile updated');
      } on ApiException catch (e) {
        if (mounted) showPPSnack(context, e.message, error: true);
      }
      return;
    }

    // camera / gallery -> upload avatar
    try {
      final bytes = action == 'camera'
          ? await MediaChannel.capture()
          : await MediaChannel.pickFromGallery();
      if (bytes == null || !mounted) return;
      final updated = await _api.uploadAvatar(bytes);
      if (!mounted) return;
      AuthScope.of(context).setUser(updated);
      showPPSnack(context, 'Photo updated');
    } on MediaException catch (e) {
      if (mounted) showPPSnack(context, e.message, error: true);
    } on ApiException catch (e) {
      if (mounted) showPPSnack(context, e.message, error: true);
    }
  }

  Widget _pickBtn(
      BuildContext ctx, IconData icon, String label, String value) {
    return GestureDetector(
      onTap: () => Navigator.of(ctx).pop(value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: PP.forest),
            const SizedBox(height: 5),
            Text(label,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ),
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
                  imageUrl: user?.imageUrl,
                  placeholderAsset: kProfilePlaceholderAsset,
                  size: 62,
                  radius: 22,
                  fontSize: 20),
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
              GestureDetector(
                onTap: user == null ? null : () => _editProfile(user),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: PP.bone.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child:
                      const Icon(LucideIcons.pencil, size: 17, color: PP.bone),
                ),
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
