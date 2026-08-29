import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../api/plantpal_api.dart';
import '../models/models.dart';
import '../state/auth_scope.dart';
import '../theme/pp_theme.dart';
import '../widgets/async_view.dart';
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

class _HomeData {
  _HomeData(this.plants, this.reminders, this.forecast, this.unread);
  final List<Plant> plants;
  final List<Reminder> reminders;
  final Forecast? forecast;
  final int unread;
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = PlantPalApi.instance;
  final _busyReminders = <int>{};

  Future<_HomeData> _load() async {
    final plants = await _api.plants();
    final reminders = await _api.todayReminders();
    Forecast? forecast;
    try {
      forecast = await _api.weather();
    } catch (_) {
      forecast = null; // upstream weather provider is flaky
    }
    var unread = 0;
    try {
      unread = await _api.unreadCount();
    } catch (_) {}
    return _HomeData(plants, reminders, forecast, unread);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;
    return SafeArea(
      bottom: false,
      child: AsyncView<_HomeData>(
        load: _load,
        padding: const EdgeInsets.only(top: 120),
        builder: (context, data, reload) {
          final pending =
              data.reminders.where((r) => !r.isCompleted).length;
          final avgHealth = data.plants.isEmpty
              ? 0
              : (data.plants.map((p) => p.healthScore).reduce((a, b) => a + b) /
                      data.plants.length)
                  .round();
          return RefreshIndicator(
            color: PP.forest,
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 120),
              children: [
                _header(context, user, data.unread),
                const SizedBox(height: 22),
                Text(
                  pending == 0
                      ? 'You’re all caught\nup today.'
                      : '$pending ${pending == 1 ? 'plant needs' : 'plants need'}\nyou today.',
                  style: TextStyle(
                      fontSize: 33,
                      height: 1.04,
                      fontWeight: FontWeight.w700,
                      letterSpacing: PP.track(33)),
                ),
                const SizedBox(height: 18),
                _healthCard(user, avgHealth, data.reminders.length - pending,
                    data.reminders.length),
                const SizedBox(height: 26),
                SectionHeader('Today’s care',
                    trailing: 'All tasks',
                    onTrailingTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RemindersScreen()))),
                const SizedBox(height: 12),
                if (data.reminders.isEmpty)
                  _softNote('No care tasks scheduled for today.')
                else
                  for (final r in data.reminders) ...[
                    _reminderTile(r, reload),
                    const SizedBox(height: 10),
                  ],
                const SizedBox(height: 16),
                SectionHeader('Your plants',
                    trailing: data.plants.isEmpty
                        ? null
                        : 'See all ${data.plants.length}'),
                const SizedBox(height: 12),
                if (data.plants.isEmpty)
                  _softNote('Scan your first plant to start your collection.')
                else
                  SizedBox(
                    height: 210,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: data.plants.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _MiniPlantCard(plant: data.plants[i]),
                    ),
                  ),
                const SizedBox(height: 22),
                _weatherCard(context, data.forecast),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _softNote(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: PP.card.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: PP.inkA(0.55))),
      );

  Widget _header(BuildContext context, UserProfile? user, int unread) {
    final name = (user?.fullName ?? 'there').split(' ').first;
    return Row(
      children: [
        InitialsAvatar(user?.initials ?? '🌱'),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good ${_partOfDay()}',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: PP.inkA(0.5))),
            Text(name,
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
          badge: unread > 0,
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        ),
      ],
    );
  }

  String _partOfDay() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  Widget _healthCard(UserProfile? user, int avgHealth, int done, int total) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Tag('Care streak · ${user?.careStreakDays ?? 0} days',
                  background: PP.pale1,
                  foreground: PP.forest,
                  icon: LucideIcons.flame,
                  fontSize: 12,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 7)),
              Text('$done of $total done',
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
                  text: '$avgHealth',
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
                child: Text('Garden health\nacross your plants',
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
                for (var i = 0; i < 14; i++) ...[
                  if (i != 0) const SizedBox(width: 5),
                  Expanded(
                    child: Container(
                      height: 44 * (0.35 + 0.6 * ((i + 3) % 7) / 7),
                      decoration: BoxDecoration(
                        color: i >= 11
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

  Widget _reminderTile(Reminder r, Future<void> Function() reload) {
    final busy = _busyReminders.contains(r.id);
    return Opacity(
      opacity: busy ? 0.6 : 1,
      child: TaskTile(
        title: r.title,
        subtitle: _reminderSubtitle(r),
        done: r.isCompleted,
        onToggle: busy ? null : () => _toggle(r, reload),
        trailing: _statusChip(r),
      ),
    );
  }

  String _reminderSubtitle(Reminder r) {
    final loc = r.plantLocation.isEmpty ? '' : '${r.plantLocation} · ';
    final t = r.scheduledTime;
    final time = t == null
        ? 'today'
        : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '$loc$time';
  }

  Widget _statusChip(Reminder r) {
    final (label, bg, fg) = r.isCompleted
        ? ('Done', PP.pale4, PP.inkA(0.5))
        : (r.scheduledTime != null &&
                r.scheduledTime!.isBefore(DateTime.now()))
            ? ('Due', PP.lime, PP.ink)
            : ('Today', PP.pale2, PP.forest);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.55,
              color: fg)),
    );
  }

  Future<void> _toggle(Reminder r, Future<void> Function() reload) async {
    setState(() => _busyReminders.add(r.id));
    try {
      await _api.updateReminder(r.id, isCompleted: !r.isCompleted);
      await reload();
    } on ApiException catch (e) {
      if (mounted) showPPSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busyReminders.remove(r.id));
    }
  }

  Widget _weatherCard(BuildContext context, Forecast? f) {
    final line = f == null
        ? 'Weather is unavailable right now'
        : '${f.current.temp}° — humidity ${f.current.humidity}%';
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const WeatherScreen())),
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
                  color: PP.pale1, borderRadius: BorderRadius.circular(18)),
              child: const Icon(LucideIcons.sun, size: 24, color: PP.forest),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Addis Ababa',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: PP.inkA(0.5))),
                  const SizedBox(height: 2),
                  Text(line,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: PP.track(15, -0.015))),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: PP.inkA(0.4)),
          ],
        ),
      ),
    );
  }
}

class _MiniPlantCard extends StatelessWidget {
  const _MiniPlantCard({required this.plant});
  final Plant plant;

  @override
  Widget build(BuildContext context) {
    final dark = plant.needsAttention;
    final fg = dark ? PP.bone : PP.ink;
    final subFg = dark ? PP.bone.withValues(alpha: 0.55) : PP.inkA(0.45);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PlantDetailScreen(plantId: plant.id))),
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
              height: 118,
              child: Stack(
                children: [
                  PlantImage(
                      height: 118,
                      width: double.infinity,
                      dark: dark,
                      iconSize: 60),
                  Positioned(
                    top: 9,
                    left: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: dark
                            ? PP.lime
                            : Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        dark ? 'Needs care' : 'Healthy',
                        style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: PP.ink),
                      ),
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
                  Text(plant.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: PP.track(15.5, -0.02),
                          color: fg)),
                  Text(
                      plant.location.isEmpty
                          ? plant.species.scientificName
                          : plant.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: subFg)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _stat('${plant.healthScore}', 'Health', fg, subFg),
                      Container(
                        width: 1,
                        height: 28,
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        color: dark
                            ? PP.bone.withValues(alpha: 0.2)
                            : PP.inkA(0.1),
                      ),
                      _stat(
                          plant.species.petSafe ? 'Yes' : 'No',
                          'Pet-safe',
                          fg,
                          subFg),
                    ],
                  ),
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
