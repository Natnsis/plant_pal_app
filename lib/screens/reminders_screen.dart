import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../api/plantpal_api.dart';
import '../models/models.dart';
import '../theme/pp_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/pp_common.dart';
import '../widgets/pp_sheets.dart';
import 'plant_detail_screen.dart';

/// The care schedule: a scrollable strip of days, each showing whether that
/// day's plant care is done / missed / still due, and full-detail cards for
/// the selected day. Completing or skipping a task rolls the next occurrence
/// forward automatically (the backend reschedules from the care plan), so the
/// schedule keeps living instead of emptying out after the first week.
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _api = PlantPalApi.instance;
  final _busy = <int>{};

  static const _stripBack = 4; // days shown before today
  static const _stripFwd = 27; // days shown after today

  late DateTime _selected = _today();
  int _reloadKey = 0;

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Returns (today's due list — authoritative, matches Home, TZ-safe on the
  /// server — , the wider range for the strip + other days).
  Future<(List<Reminder>, List<Reminder>)> _load() async {
    final today = await _api.todayReminders();
    List<Reminder> all = const [];
    try {
      all = await _api.reminders(
        status: 'all',
        from: _today().subtract(const Duration(days: _stripBack + 1)),
        to: _today().add(const Duration(days: _stripFwd + 1)),
      );
    } catch (_) {}
    return (today, all);
  }

  Map<String, List<Reminder>> _byDay(List<Reminder> all) {
    final map = <String, List<Reminder>>{};
    for (final r in all) {
      (map[_key(r.day)] ??= []).add(r);
    }
    for (final list in map.values) {
      list.sort((a, b) =>
          (a.scheduledTime ?? a.day).compareTo(b.scheduledTime ?? b.day));
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PP.bone,
      body: SafeArea(
        child: AsyncView<(List<Reminder>, List<Reminder>)>(
          key: ValueKey(_reloadKey),
          load: _load,
          builder: (context, data, reload) {
            final (todayList, all) = data;
            final byDay = _byDay(all);
            final isTodaySel = _selected == _today();

            // Today's view = the authoritative /reminders/today list, merged
            // with anything already done/skipped today from the range list
            // (deduped by id). Other days bucket straight from the range.
            List<Reminder> dayItems;
            if (isTodaySel) {
              final ids = todayList.map((r) => r.id).toSet();
              final extras = (byDay[_key(_today())] ?? const <Reminder>[])
                  .where((r) => !ids.contains(r.id));
              dayItems = [...todayList, ...extras]..sort((a, b) =>
                  (a.scheduledTime ?? a.day).compareTo(b.scheduledTime ?? b.day));
            } else {
              dayItems = byDay[_key(_selected)] ?? const <Reminder>[];
            }
            final done = dayItems
                .where((r) => r.status == ReminderStatus.done)
                .length;
            return RefreshIndicator(
              color: PP.forest,
              onRefresh: reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 40),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(child: DisplayTitle('Care\nschedule')),
                        SquircleIconButton(
                          icon: LucideIcons.plus,
                          background: PP.ink,
                          foreground: PP.bone,
                          onTap: () => _addReminder(reload),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _strip(byDay, todayList),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_dayHeading(_selected),
                            style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                                letterSpacing: PP.track(19, -0.025))),
                        if (dayItems.isNotEmpty)
                          Text('$done of ${dayItems.length} done',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: PP.inkA(0.45))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (dayItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: _note(_selected.isBefore(_today())
                          ? 'Nothing was scheduled this day.'
                          : 'No care scheduled — enjoy the day off.'),
                    )
                  else
                    for (final r in dayItems) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: _ReminderCard(
                          reminder: r,
                          busy: _busy.contains(r.id),
                          onComplete: () => _act(r, reload, complete: true),
                          onSkip: () => _act(r, reload, skip: true),
                          onOpen: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => PlantDetailScreen(
                                      plantId: r.plantId))),
                        ),
                      ),
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

  Widget _strip(Map<String, List<Reminder>> byDay, List<Reminder> todayList) {
    final start = _today().subtract(const Duration(days: _stripBack));
    const count = _stripBack + 1 + _stripFwd;
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final day = start.add(Duration(days: i));
          final isToday = day == _today();
          final items = isToday
              ? todayList
              : (byDay[_key(day)] ?? const <Reminder>[]);
          final selected = day == _selected;
          return GestureDetector(
            onTap: () => setState(() => _selected = day),
            child: Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? PP.ink
                    : isToday
                        ? PP.pale2
                        : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(_weekday(day),
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? PP.bone.withValues(alpha: 0.6)
                              : PP.inkA(0.45))),
                  const SizedBox(height: 2),
                  Text(day.day.toString().padLeft(2, '0'),
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: selected ? PP.bone : PP.ink)),
                  const SizedBox(height: 6),
                  _dayDot(items, selected),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dayDot(List<Reminder> items, bool selected) {
    if (items.isEmpty) {
      return Container(
        width: 12,
        height: 3,
        decoration: BoxDecoration(
          color: (selected ? PP.bone : PP.ink).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    final anyMissed = items.any((r) => r.status == ReminderStatus.missed);
    final anyPending = items.any((r) =>
        r.status == ReminderStatus.dueToday ||
        r.status == ReminderStatus.upcoming);
    final allDone = items.every((r) =>
        r.status == ReminderStatus.done || r.status == ReminderStatus.skipped);
    final color = anyMissed
        ? PP.danger
        : allDone
            ? PP.forest
            : anyPending
                ? PP.lime
                : PP.forest;
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Future<void> _act(
    Reminder r,
    Future<void> Function() reload, {
    bool complete = false,
    bool skip = false,
  }) async {
    setState(() => _busy.add(r.id));
    try {
      await _api.updateReminder(r.id,
          isCompleted: complete ? true : null, skip: skip ? true : null);
      if (mounted) {
        showPPSnack(context, skip ? 'Skipped — next one scheduled' : 'Done!');
      }
      setState(() => _reloadKey++);
      await reload();
    } on ApiException catch (e) {
      if (mounted) showPPSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(r.id));
    }
  }

  static String _weekday(DateTime d) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];

  String _dayHeading(DateTime d) {
    final t = _today();
    if (d == t) return 'Today';
    if (d == t.add(const Duration(days: 1))) return 'Tomorrow';
    if (d == t.subtract(const Duration(days: 1))) return 'Yesterday';
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${_weekday(d)} ${d.day} ${m[d.month - 1]}';
  }

  Future<void> _addReminder(Future<void> Function() reload) async {
    List<Plant> plants;
    try {
      plants = await _api.plants();
    } on ApiException catch (e) {
      if (mounted) showPPSnack(context, e.message, error: true);
      return;
    }
    if (!mounted) return;
    if (plants.isEmpty) {
      showPPSnack(context, 'Add a plant first, then schedule its care.');
      return;
    }

    Plant plant = plants.first;
    var task = 'Water';
    var inDays = 3;
    final ok = await showPPSheet<bool>(
      context,
      title: 'Add a reminder',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plant',
                style: TextStyle(fontSize: 12.5, color: PP.inkA(0.5))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in plants)
                  GestureDetector(
                    onTap: () => setSheet(() => plant = p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: plant.id == p.id ? PP.ink : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(p.displayName,
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: plant.id == p.id
                                  ? PP.bone
                                  : PP.inkA(0.6))),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Task', style: TextStyle(fontSize: 12.5, color: PP.inkA(0.5))),
            const SizedBox(height: 8),
            PPChoiceChips(
              options: const ['Water', 'Fertilize', 'Mist', 'Rotate', 'Repot'],
              value: task,
              onChanged: (v) => setSheet(() => task = v),
            ),
            const SizedBox(height: 14),
            Text('When', style: TextStyle(fontSize: 12.5, color: PP.inkA(0.5))),
            const SizedBox(height: 8),
            PPChoiceChips(
              options: const [
                'Tomorrow',
                'In 3 days',
                'In a week',
                'In 2 weeks'
              ],
              value: switch (inDays) {
                1 => 'Tomorrow',
                7 => 'In a week',
                14 => 'In 2 weeks',
                _ => 'In 3 days',
              },
              onChanged: (v) => setSheet(() => inDays = switch (v) {
                    'Tomorrow' => 1,
                    'In a week' => 7,
                    'In 2 weeks' => 14,
                    _ => 3,
                  }),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Schedule',
              background: PP.forest,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;

    const map = {
      'Water': 'water',
      'Fertilize': 'fertilize',
      'Mist': 'mist',
      'Rotate': 'rotate',
      'Repot': 'repot',
    };
    final now = DateTime.now();
    final when =
        DateTime(now.year, now.month, now.day, 9).add(Duration(days: inDays));
    try {
      await _api.createReminder(plant.id,
          taskType: map[task]!, scheduledTime: when);
      if (mounted) showPPSnack(context, 'Reminder scheduled');
      setState(() => _reloadKey++);
      await reload();
    } on ApiException catch (e) {
      if (mounted) showPPSnack(context, e.message, error: true);
    }
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.busy,
    required this.onComplete,
    required this.onSkip,
    required this.onOpen,
  });

  final Reminder reminder;
  final bool busy;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final VoidCallback onOpen;

  IconData get _icon => switch (reminder.taskType) {
        TaskType.fertilize => LucideIcons.sprout,
        TaskType.mist => LucideIcons.droplets,
        TaskType.rotate => LucideIcons.refreshCw,
        TaskType.repot => LucideIcons.house,
        TaskType.water => LucideIcons.droplet,
      };

  @override
  Widget build(BuildContext context) {
    final s = reminder.status;
    final (badge, badgeBg, badgeFg) = switch (s) {
      ReminderStatus.done => ('DONE', PP.pale2, PP.forest),
      ReminderStatus.skipped => ('SKIPPED', PP.pale4, PP.inkA(0.5)),
      ReminderStatus.missed => ('MISSED', PP.amberBg, PP.amberFg),
      ReminderStatus.dueToday => ('DUE', PP.lime, PP.ink),
      ReminderStatus.upcoming => ('SCHEDULED', PP.field, PP.inkA(0.5)),
    };
    final actionable =
        s == ReminderStatus.dueToday || s == ReminderStatus.missed;

    final t = reminder.scheduledTime;
    final timeStr = t == null
        ? ''
        : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final sub = [
      if (reminder.plantLocation.isNotEmpty) reminder.plantLocation,
      if (timeStr.isNotEmpty) timeStr,
    ].join(' · ');

    return Opacity(
      opacity: busy ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: s == ReminderStatus.missed
              ? Border.all(color: PP.amberBg, width: 1.4)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: PP.pale1,
                      borderRadius: BorderRadius.circular(15)),
                  child: Icon(_icon, size: 19, color: PP.forest),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: GestureDetector(
                    onTap: onOpen,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reminder.title,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: PP.track(15, -0.01))),
                        if (sub.isNotEmpty)
                          Text(sub,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: PP.inkA(0.5))),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(badge,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: badgeFg)),
                ),
              ],
            ),
            if (s == ReminderStatus.done && reminder.completedAt != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.check_rounded, size: 15, color: PP.forest),
                  const SizedBox(width: 6),
                  Text(
                      'Done ${_rel(reminder.completedAt!)}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: PP.inkA(0.5))),
                ],
              ),
            ],
            if (s == ReminderStatus.missed) ...[
              const SizedBox(height: 8),
              Text('Overdue — still needs doing.',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: PP.amberFg)),
            ],
            if (actionable) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _btn('Mark done', PP.forest, PP.bone,
                        busy ? null : onComplete),
                  ),
                  const SizedBox(width: 10),
                  _btn('Skip', PP.field, PP.inkA(0.6),
                      busy ? null : onSkip, wide: false),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _btn(String label, Color bg, Color fg, VoidCallback? onTap,
      {bool wide = true}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: wide ? 0 : 20, vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
      ),
    );
  }

  static String _rel(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}
