import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../api/plantpal_api.dart';
import '../models/models.dart';
import '../theme/pp_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/pp_common.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersData {
  _RemindersData(this.today, this.upcoming);
  final List<Reminder> today;
  final List<Reminder> upcoming;
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _api = PlantPalApi.instance;
  final _busy = <int>{};

  Future<_RemindersData> _load() async {
    final today = await _api.todayReminders();
    final all = await _api.reminders();
    final todayIds = today.map((r) => r.id).toSet();
    final now = DateTime.now();
    final upcoming = all
        .where((r) =>
            !todayIds.contains(r.id) &&
            !r.isCompleted &&
            (r.scheduledTime == null || r.scheduledTime!.isAfter(now)))
        .toList()
      ..sort((a, b) => (a.scheduledTime ?? now).compareTo(b.scheduledTime ?? now));
    return _RemindersData(today, upcoming);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PP.bone,
      body: SafeArea(
        child: AsyncView<_RemindersData>(
          load: _load,
          builder: (context, data, reload) {
            final left = data.today.where((r) => !r.isCompleted).length;
            return RefreshIndicator(
              color: PP.forest,
              onRefresh: reload,
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
                  _weekStrip(),
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
                      Text(
                          '$left of ${data.today.length} left',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: PP.inkA(0.45))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (data.today.isEmpty)
                    _note('Nothing scheduled for today.')
                  else
                    for (final r in data.today) ...[
                      _tile(r, reload),
                      const SizedBox(height: 10),
                    ],
                  const SizedBox(height: 16),
                  Text('Upcoming',
                      style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          letterSpacing: PP.track(19, -0.025))),
                  const SizedBox(height: 12),
                  if (data.upcoming.isEmpty)
                    _note('No upcoming reminders.')
                  else
                    for (final r in data.upcoming.take(8)) ...[
                      _upcomingRow(r),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _note(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: PP.card.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: PP.inkA(0.55))),
      );

  Widget _weekStrip() {
    final now = DateTime.now();
    const dn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: [
        for (var i = 0; i < 5; i++) ...[
          if (i != 0) const SizedBox(width: 7),
          Expanded(
            child: Builder(builder: (_) {
              final day = now.add(Duration(days: i));
              final selected = i == 0;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? PP.ink : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(dn[day.weekday - 1],
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? PP.bone.withValues(alpha: 0.6)
                                : PP.inkA(0.45))),
                    const SizedBox(height: 2),
                    Text(day.day.toString().padLeft(2, '0'),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: selected ? PP.bone : PP.ink)),
                  ],
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _tile(Reminder r, Future<void> Function() reload) {
    final busy = _busy.contains(r.id);
    return Opacity(
      opacity: busy ? 0.6 : 1,
      child: TaskTile(
        title: r.title,
        subtitle: _subtitle(r),
        done: r.isCompleted,
        onToggle: busy ? null : () => _toggle(r, reload, complete: !r.isCompleted),
        trailing: GestureDetector(
          onTap: busy || r.isCompleted
              ? null
              : () => _toggle(r, reload, snooze: true),
          child: Container(
            width: 32,
            height: 32,
            decoration:
                BoxDecoration(color: PP.inkA(0.06), shape: BoxShape.circle),
            child: Icon(LucideIcons.clock, size: 15, color: PP.inkA(0.55)),
          ),
        ),
      ),
    );
  }

  Widget _upcomingRow(Reminder r) {
    final t = r.scheduledTime;
    final due = t == null
        ? '—'
        : () {
            final diff = t.difference(DateTime.now()).inDays;
            return diff <= 0 ? 'soon' : '${diff}d';
          }();
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
            child: Icon(_iconFor(r.taskType), size: 19, color: PP.forest),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: PP.track(15, -0.01))),
                Text(_subtitle(r),
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

  IconData _iconFor(TaskType t) => switch (t) {
        TaskType.fertilize => LucideIcons.sprout,
        TaskType.mist => LucideIcons.droplets,
        TaskType.rotate => LucideIcons.refreshCw,
        TaskType.repot => LucideIcons.house,
        TaskType.water => LucideIcons.droplet,
      };

  String _subtitle(Reminder r) {
    final loc = r.plantLocation.isEmpty ? '' : '${r.plantLocation} · ';
    final t = r.scheduledTime;
    if (t == null) return '${loc}anytime today';
    const dn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hhmm =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '$loc${dn[t.weekday - 1]} ${t.day} · $hhmm';
  }

  Future<void> _toggle(
    Reminder r,
    Future<void> Function() reload, {
    bool? complete,
    bool snooze = false,
  }) async {
    setState(() => _busy.add(r.id));
    try {
      await _api.updateReminder(r.id,
          isCompleted: complete, snooze: snooze ? true : null);
      if (snooze && mounted) showPPSnack(context, 'Snoozed');
      await reload();
    } on ApiException catch (e) {
      if (mounted) showPPSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(r.id));
    }
  }
}
