import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// =============================================================================
// SCREEN 32: PROFILE
// =============================================================================

IconData _weatherIcon(String code) {
  if (code.contains('rain') || code.contains('drizzle')) return LucideIcons.cloudRain;
  if (code.contains('cloud')) return LucideIcons.cloud;
  if (code.contains('thunder')) return LucideIcons.cloudLightning;
  if (code.contains('snow')) return LucideIcons.snowflake;
  if (code.contains('fog') || code.contains('mist')) return LucideIcons.cloudFog;
  return LucideIcons.sun;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  PlantUser? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await AuthService.getMe();
      if (!mounted) return;
      setState(() { _user = PlantUser.fromJson(data); _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load profile'; _isLoading = false; });
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    TokenStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (r) => false);
  }

  void _showEditSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        user: _user!,
        onSaved: (updated) => setState(() => _user = updated),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageBase,
      body: SafeArea(
        child: _isLoading ? _buildSkeleton() : _error != null ? _buildError() : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final user = _user!;
    final initials = user.fullName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(children: [
        // Top bar
        Row(children: [
          const Expanded(child: Text('Profile',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.cream))),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
            child: Container(width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(LucideIcons.settings, color: AppColors.cream, size: 20)),
          ),
        ]),

        const SizedBox(height: 24),

        // Profile card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8))]),
          child: Column(children: [
            // Avatar
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.sageBase.withValues(alpha: 0.4), shape: BoxShape.circle),
              child: Center(child: Text(initials,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.accentDark))),
            ),
            const SizedBox(height: 14),
            Text(user.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(user.email, style: TextStyle(fontSize: 14, color: AppColors.textPrimary.withValues(alpha: 0.5))),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showEditSheet,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(LucideIcons.pencil, size: 14, color: AppColors.accentGreen),
                const SizedBox(width: 4),
                Text('Edit Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.accentGreen)),
              ]),
            ),
          ]),
        ),

        const SizedBox(height: 20),

        // Stats row
        Row(children: [
          _StatCard(value: '${user.careStreakDays}', label: 'Day Streak', iconData: LucideIcons.flame, color: const Color(0xFFFF8F00)),
          const SizedBox(width: 10),
          _StatCard(value: '${user.totalTaskDone}', label: 'Tasks Done', iconData: LucideIcons.checkCircle, color: AppColors.accentGreen),
          const SizedBox(width: 10),
          _StatCard(value: '${user.totalJournalInjuries}', label: 'Journal', iconData: LucideIcons.bookOpen, color: const Color(0xFF42A5F5)),
        ]),

        const SizedBox(height: 24),

        // Settings list
        Container(
          decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            _SettingsRow(
              icon: LucideIcons.bell, title: 'Notification Settings',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
            ),
            _SettingsRow(
              icon: LucideIcons.leaf, title: 'My Plants',
              onTap: () => Navigator.of(context).pushNamed('/my-plants'),
            ),
            _SettingsRow(
              icon: LucideIcons.info, title: 'About PlantPal',
              onTap: () => _showAboutSheet(),
            ),
          ]),
        ),

        const SizedBox(height: 24),

        // Log out
        SizedBox(
          width: double.infinity, height: 52,
          child: OutlinedButton(
            onPressed: () => _showLogoutDialog(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
              side: const BorderSide(color: Color(0xFFE53935)),
              shape: const StadiumBorder(),
            ),
            child: const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out of PlantPal?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _logout(); },
            child: const Text('Log Out', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showAboutSheet() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(28)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.textPrimary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999))),
          const SizedBox(height: 20),
          const Icon(LucideIcons.leaf, size: 48, color: AppColors.accentGreen),
          const SizedBox(height: 12),
          const Text('PlantPal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Version 1.0.0', style: TextStyle(fontSize: 13, color: AppColors.textPrimary.withValues(alpha: 0.4))),
          const SizedBox(height: 16),
          Text('Your AI-powered plant care companion.\nIdentify, diagnose, and care for your plants.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary.withValues(alpha: 0.6), height: 1.5)),
          // TODO: fill with real about/legal copy
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(children: [
        Container(width: 120, height: 28, decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8))),
        const SizedBox(height: 24),
        Container(width: double.infinity, height: 200, decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(28))),
        const SizedBox(height: 20),
        Row(children: List.generate(3, (_) => Expanded(
          child: Container(height: 80, margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16))),
        ))),
      ]),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_error!, style: const TextStyle(color: AppColors.cream)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _loadProfile, style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel, shape: const StadiumBorder()),
          child: const Text('Retry')),
    ]));
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, required this.iconData, required this.color});
  final String value;
  final String label;
  final IconData iconData;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Icon(iconData, size: 20, color: color),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.textPrimary.withValues(alpha: 0.5))),
        ]),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(children: [
          Icon(icon, size: 20, color: AppColors.textPrimary.withValues(alpha: 0.6)),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary))),
          Icon(LucideIcons.chevronRight, size: 20, color: AppColors.textPrimary.withValues(alpha: 0.3)),
        ]),
      ),
    );
  }
}

// =============================================================================
// Edit Profile Sheet
// =============================================================================

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user, required this.onSaved});
  final PlantUser user;
  final ValueChanged<PlantUser> onSaved;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  bool _isSaving = false;
  String? _error;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.fullName);
    _emailCtrl = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); super.dispose(); }

  Future<void> _onSave() async {
    setState(() { _isSaving = true; _error = null; _emailError = null; });
    try {
      final body = await AuthService.updateMe(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );
      if (!mounted) return;
      widget.onSaved(PlantUser.fromJson(body));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        setState(() { _emailError = 'This email is already in use'; _isSaving = false; });
      } else {
        setState(() { _error = e.message; _isSaving = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _error = "Couldn't reach PlantPal"; _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.textPrimary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)))),
          const SizedBox(height: 16),
          const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          if (_error != null) ...[
            Container(width: double.infinity, padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 13))),
            const SizedBox(height: 16),
          ],
          const Text('Full Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextField(controller: _nameCtrl, enabled: !_isSaving,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDec()),
          const SizedBox(height: 16),
          const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextField(controller: _emailCtrl, enabled: !_isSaving, keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDec(error: _emailError)),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _onSave,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel, shape: const StadiumBorder()),
              child: _isSaving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  InputDecoration _inputDec({String? error}) {
    return InputDecoration(
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.08))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.08))),
      errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: Color(0xFFD32F2F))),
      errorText: error,
    );
  }
}

// =============================================================================
// SCREEN 33: NOTIFICATION SETTINGS
// =============================================================================

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _dailySummary = true;
  bool _soundAlerts = true;
  bool _vibration = true;
  String _preferredTime = '08:00';
  int _snoozeDuration = 15;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await AuthService.getNotificationSettings();
      if (!mounted) return;
      setState(() {
        _notificationsEnabled = data['notification_enabled'] ?? true;
        _dailySummary = data['daily_summary_enabled'] ?? true;
        _soundAlerts = data['sound_alert_enabled'] ?? true;
        _vibration = data['vibration_enabled'] ?? true;
        _preferredTime = data['preferred_notification_time']?.toString() ?? '08:00';
        _snoozeDuration = data['default_snooze_duration_minute'] ?? 15;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load settings'; _isLoading = false; });
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      await AuthService.updateNotificationSettings({key: value});
    } catch (_) {
      // Revert on failure
      _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't update that setting")));
      }
    }
  }

  void _showTimePicker() async {
    final parts = _preferredTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() => _preferredTime = timeStr);
      _updateSetting('preferred_notification_time', timeStr);
    }
  }

  void _showSnoozePicker() {
    final options = [5, 10, 15, 30, 60];
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(28)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Snooze Duration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          ...options.map((min) => ListTile(
            title: Text('$min min', style: const TextStyle(color: AppColors.textPrimary)),
            trailing: _snoozeDuration == min ? const Icon(Icons.check, color: AppColors.accentGreen) : null,
            onTap: () {
              setState(() => _snoozeDuration = min);
              _updateSetting('default_snooze_duration_minute', min);
              Navigator.pop(context);
            },
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageBase,
      body: SafeArea(
        child: Column(children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.25), shape: BoxShape.circle),
                    child: const Icon(LucideIcons.chevronLeft, color: AppColors.cream, size: 22)),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Notification Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.cream))),
            ]),
          ),

          const SizedBox(height: 16),

          Expanded(child: _isLoading ? _buildSkeleton() : _error != null ? _buildError() : _buildContent()),
        ]),
      ),
    );
  }

  Widget _buildContent() {
    final dimmed = !_notificationsEnabled;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Section: General
        _SectionHeader('General'),
        _ToggleRow(
          title: 'Enable Notifications',
          value: _notificationsEnabled,
          onChanged: (v) { setState(() => _notificationsEnabled = v); _updateSetting('notification_enabled', v); },
        ),
        Opacity(
          opacity: dimmed ? 0.4 : 1.0,
          child: IgnorePointer(
            ignoring: dimmed,
            child: _ToggleRow(
              title: 'Daily Summary',
              subtitle: 'Get a daily digest of your plants\' needs',
              value: _dailySummary,
              onChanged: (v) { setState(() => _dailySummary = v); _updateSetting('daily_summary_enabled', v); },
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Section: Alerts
        _SectionHeader('Alerts'),
        Opacity(
          opacity: dimmed ? 0.4 : 1.0,
          child: IgnorePointer(
            ignoring: dimmed,
            child: Column(children: [
              _ToggleRow(
                title: 'Sound',
                value: _soundAlerts,
                onChanged: (v) { setState(() => _soundAlerts = v); _updateSetting('sound_alert_enabled', v); },
              ),
              _ToggleRow(
                title: 'Vibration',
                value: _vibration,
                onChanged: (v) { setState(() => _vibration = v); _updateSetting('vibration_enabled', v); },
              ),
            ]),
          ),
        ),

        const SizedBox(height: 12),

        // Section: Timing
        _SectionHeader('Timing'),
        Opacity(
          opacity: dimmed ? 0.4 : 1.0,
          child: IgnorePointer(
            ignoring: dimmed,
            child: Column(children: [
              _PickerRow(
                title: 'Preferred Time',
                value: _preferredTime,
                onTap: _showTimePicker,
              ),
              _PickerRow(
                title: 'Default Snooze Duration',
                value: '$_snoozeDuration min',
                onTap: _showSnoozePicker,
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 6,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 56,
        decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_error!, style: const TextStyle(color: AppColors.cream)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _loadSettings, style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel, shape: const StadiumBorder()),
          child: const Text('Retry')),
    ]));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
        child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.cream.withValues(alpha: 0.6))));
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.title, this.subtitle, required this.value, required this.onChanged});
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: TextStyle(fontSize: 12, color: AppColors.textPrimary.withValues(alpha: 0.5))),
            ],
          ],
        )),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.accentDark,
          inactiveTrackColor: AppColors.textPrimary.withValues(alpha: 0.15),
        ),
      ]),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.title, required this.value, required this.onTap});
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary.withValues(alpha: 0.5))),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textPrimary.withValues(alpha: 0.3)),
        ]),
      ),
    );
  }
}

// =============================================================================
// SCREEN 34: WEATHER DETAIL
// =============================================================================

class WeatherDetailScreen extends StatefulWidget {
  const WeatherDetailScreen({super.key});

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  WeatherForecast? _forecast;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // TODO: wire device geolocation once available, currently relies on API's Addis Ababa default
      final data = await AuthService.getWeather();
      if (!mounted) return;
      if (data == null) {
        setState(() { _error = 'Weather data is temporarily unavailable'; _isLoading = false; });
      } else {
        setState(() { _forecast = WeatherForecast.fromJson(data); _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load weather'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageBase,
      body: SafeArea(
        child: Column(children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.25), shape: BoxShape.circle),
                    child: const Icon(LucideIcons.chevronLeft, color: AppColors.cream, size: 22)),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Weather',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.cream))),
            ]),
          ),

          const SizedBox(height: 16),

          Expanded(child: _isLoading ? _buildSkeleton() : _error != null ? _buildError() : _buildContent()),
        ]),
      ),
    );
  }

  Widget _buildContent() {
    final forecast = _forecast!;
    final current = forecast.current;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Hero card
        if (current != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8))]),
            child: Column(children: [
              Icon(_weatherIcon(current.icon), size: 56, color: AppColors.accentGreen),
              const SizedBox(height: 8),
              Text('${current.temp.round()}°', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(LucideIcons.droplets, size: 16, color: AppColors.textPrimary.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Text('${current.humidity.round()}% humidity',
                    style: TextStyle(fontSize: 14, color: AppColors.textPrimary.withValues(alpha: 0.5))),
              ]),
              const SizedBox(height: 12),
              // Contextual tip
              if (current.humidity < 30)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(12)),
                  child: Text('Low humidity — your plants may need more frequent misting',
                      style: TextStyle(fontSize: 12, color: const Color(0xFFE65100).withValues(alpha: 0.8))),
                ),
            ]),
          ),

        const SizedBox(height: 24),

        // Hourly strip
        if (forecast.hourly.isNotEmpty) ...[
          Text('Hourly Forecast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.cream)),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: forecast.hourly.length,
              separatorBuilder: (_, idx) => const SizedBox(width: 8),
              itemBuilder: (_, idx) {
                final h = forecast.hourly[idx];
                return Container(
                  width: 64,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(h.hour, style: TextStyle(fontSize: 11, color: AppColors.cream.withValues(alpha: 0.6))),
                    const SizedBox(height: 4),
                    Icon(_weatherIcon(current?.icon ?? 'sun'), size: 16, color: AppColors.cream),
                    const SizedBox(height: 4),
                    Text('${h.temp.round()}°', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.cream)),
                  ]),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Daily forecast
        if (forecast.daily.isNotEmpty) ...[
          Text('7-Day Forecast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.cream)),
          const SizedBox(height: 12),
          ...forecast.daily.map((d) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Expanded(child: Text(d.date, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
              Icon(_weatherIcon(d.icon), size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 12),
              Text('${d.high.round()}° / ${d.low.round()}°',
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary.withValues(alpha: 0.6))),
            ]),
          )),
        ],

        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        Container(width: double.infinity, height: 180, decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(28))),
        const SizedBox(height: 24),
        ...List.generate(5, (_) => Container(
          margin: const EdgeInsets.only(bottom: 8), height: 48,
          decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
        )),
      ]),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('🌤️', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 16),
      Text(_error!, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.cream)),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: _loadWeather,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel, shape: const StadiumBorder()),
          child: const Text('Retry')),
    ]));
  }
}
