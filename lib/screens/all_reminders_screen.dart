import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// =============================================================================
// ReminderActions — shared action logic (reuse from Home + Plant Detail)
// =============================================================================

class ReminderActions {
  static Future<void> complete(Reminder reminder, {VoidCallback? onDone, VoidCallback? onRevert}) async {
    try {
      await AuthService.updateReminder(reminder.id, {'is_completed': true});
      onDone?.call();
    } catch (_) {
      onRevert?.call();
    }
  }

  static Future<void> snooze(Reminder reminder, {ValueChanged<Reminder>? onDone, VoidCallback? onRevert}) async {
    try {
      final body = await AuthService.updateReminder(reminder.id, {'snooze': true});
      onDone?.call(Reminder.fromJson(body));
    } catch (_) {
      onRevert?.call();
    }
  }

  static Future<void> delete(Reminder reminder, {VoidCallback? onDone, VoidCallback? onRevert}) async {
    try {
      await AuthService.deleteReminder(reminder.id);
      onDone?.call();
    } catch (_) {
      onRevert?.call();
    }
  }
}

// =============================================================================
// SCREEN 24: ALL REMINDERS
// =============================================================================

class AllRemindersScreen extends StatefulWidget {
  const AllRemindersScreen({super.key});

  @override
  State<AllRemindersScreen> createState() => _AllRemindersScreenState();
}

class _AllRemindersScreenState extends State<AllRemindersScreen> {
  List<Reminder> _reminders = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'pending'; // pending | completed | all
  int? _plantFilter;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await AuthService.getAllReminders(
        status: _statusFilter,
        plantId: _plantFilter,
      );
      if (!mounted) return;
      setState(() {
        _reminders = data.map((j) => Reminder.fromJson(j)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load reminders'; _isLoading = false; });
    }
  }

  void _setStatusFilter(String status) {
    setState(() => _statusFilter = status);
    _loadReminders();
  }

  void _setPlantFilter(int? plantId) {
    setState(() => _plantFilter = plantId);
    _loadReminders();
  }

  // Distinct plants from loaded reminders for the chip row
  List<MapEntry<int, String>> get _plantChips {
    final map = <int, String>{};
    for (final r in _reminders) {
      if (r.plant != null) map[r.plantId] = r.plant!.nickname;
    }
    return map.entries.toList();
  }

  // Group reminders by time bucket
  Map<String, List<Reminder>> get _grouped {
    final groups = <String, List<Reminder>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    for (final r in _reminders) {
      String group;
      if (_statusFilter == 'completed') {
        group = 'Completed';
      } else {
        final scheduled = _parseDateTime(r.scheduledTime);
        if (scheduled == null) {
          group = 'Later';
        } else if (scheduled.isBefore(today)) {
          group = 'Overdue';
        } else if (scheduled.isBefore(tomorrow)) {
          group = 'Today';
        } else if (scheduled.isBefore(weekEnd)) {
          group = 'This Week';
        } else {
          group = 'Later';
        }
      }
      groups.putIfAbsent(group, () => []).add(r);
    }

    // Sort groups in logical order
    final order = ['Overdue', 'Today', 'This Week', 'Later', 'Completed'];
    final sorted = <String, List<Reminder>>{};
    for (final g in order) {
      if (groups.containsKey(g)) sorted[g] = groups[g]!;
    }
    return sorted;
  }

  DateTime? _parseDateTime(String s) {
    return DateTime.tryParse(s);
  }

  bool _isOverdue(Reminder r) {
    if (r.isCompleted) return false;
    final dt = _parseDateTime(r.scheduledTime);
    return dt != null && dt.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageBase,
      body: SafeArea(
        child: Column(children: [
          _buildTopBar(),
          _buildSegmentedControl(),
          _buildPlantChips(),
          const SizedBox(height: 8),
          Expanded(child: _buildContent()),
        ]),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.25), shape: BoxShape.circle),
              child: const Icon(LucideIcons.chevronLeft, color: AppColors.cream, size: 22)),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Text('Reminders',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.cream))),
        GestureDetector(
          onTap: _showAddReminderSheet,
          child: Container(width: 40, height: 40,
              decoration: const BoxDecoration(color: AppColors.cream, shape: BoxShape.circle),
              child: const Icon(LucideIcons.plus, color: AppColors.accentDark, size: 22)),
        ),
      ]),
    );
  }

  Widget _buildSegmentedControl() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
        child: Row(children: [
          _SegmentButton(label: 'Pending', isActive: _statusFilter == 'pending', onTap: () => _setStatusFilter('pending')),
          _SegmentButton(label: 'Completed', isActive: _statusFilter == 'completed', onTap: () => _setStatusFilter('completed')),
          _SegmentButton(label: 'All', isActive: _statusFilter == 'all', onTap: () => _setStatusFilter('all')),
        ]),
      ),
    );
  }

  Widget _buildPlantChips() {
    final chips = _plantChips;
    if (chips.isEmpty && !_isLoading) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(children: [
        _FilterChip(
          label: 'All Plants',
          isActive: _plantFilter == null,
          onTap: () => _setPlantFilter(null),
        ),
        const SizedBox(width: 8),
        ...chips.map((e) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _FilterChip(
            label: e.value,
            isActive: _plantFilter == e.key,
            onTap: () => _setPlantFilter(e.key),
          ),
        )),
      ]),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return _buildSkeleton();
    if (_error != null) return _buildError();
    if (_reminders.isEmpty) return _buildEmpty();

    final grouped = _grouped;
    return RefreshIndicator(
      onRefresh: _loadReminders,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        children: grouped.entries.expand((entry) {
          return [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(entry.key,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: entry.key == 'Overdue' ? const Color(0xFFE53935) : AppColors.cream.withValues(alpha: 0.6))),
            ),
            ...entry.value.map((r) => _ReminderCard(
              reminder: r,
              isOverdue: _isOverdue(r),
              isCompletedView: _statusFilter == 'completed',
              onComplete: () => _completeReminder(r),
              onSnooze: () => _snoozeReminder(r),
              onDelete: () => _deleteReminder(r),
              onTap: () => Navigator.of(context).pushNamed('/plant/${r.plantId}'),
            )),
          ];
        }).toList(),
      ),
    );
  }

  Future<void> _completeReminder(Reminder r) async {
    setState(() => _reminders.removeWhere((x) => x.id == r.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Task completed'), duration: const Duration(seconds: 2)),
    );
    try {
      await ReminderActions.complete(r);
      // Refresh to get accurate completed_at from server
      _loadReminders();
    } catch (_) {
      if (mounted) {
        setState(() => _reminders.add(r));
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't complete that task — try again")));
      }
    }
  }

  Future<void> _snoozeReminder(Reminder r) async {
    try {
      await ReminderActions.snooze(r, onDone: (updated) {
        setState(() {
          final idx = _reminders.indexWhere((x) => x.id == r.id);
          if (idx != -1) _reminders[idx] = updated;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Snoozed'), duration: Duration(seconds: 2)));
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't snooze that task — try again")));
      }
    }
  }

  void _deleteReminder(Reminder r) {
    // Optimistic removal with Undo snackbar
    setState(() => _reminders.removeWhere((x) => x.id == r.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Task deleted'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.accentGreen,
          onPressed: () {
            // Re-add the reminder locally (no un-delete endpoint exists)
            setState(() => _reminders.add(r));
            // TODO: re-POST via /plants/{plant_id}/reminders with same task_type/scheduled_time
          },
        ),
      ),
    );

    // Fire delete immediately
    ReminderActions.delete(r).catchError((_) {
      if (mounted) {
        setState(() => _reminders.add(r));
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't delete that task")));
      }
    });
  }

  void _showAddReminderSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _AddReminderSheet(),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 5,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.15), shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 100, height: 14, decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 6),
            Container(width: 160, height: 12, decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4))),
          ])),
        ]),
      ),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_error!, style: const TextStyle(color: AppColors.cream)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _loadReminders, style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel, shape: const StadiumBorder()),
          child: const Text('Retry')),
    ]));
  }

  Widget _buildEmpty() {
    final msg = switch (_statusFilter) {
      'pending' => 'All caught up! 🌿',
      'completed' => 'No completed tasks yet',
      _ => 'No reminders',
    };
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(LucideIcons.leaf, size: 48, color: AppColors.accentGreen),
      const SizedBox(height: 12),
      Text(msg, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.cream)),
    ]));
  }
}

// =============================================================================
// Reminder Card
// =============================================================================

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.isOverdue,
    required this.isCompletedView,
    required this.onComplete,
    required this.onSnooze,
    required this.onDelete,
    required this.onTap,
  });

  final Reminder reminder;
  final bool isOverdue;
  final bool isCompletedView;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDone = reminder.isCompleted;

    return Dismissible(
      key: ValueKey(reminder.id),
      direction: isDone ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(16)),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isDone ? 0.6 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              // Task type icon badge
              _TaskTypeBadge(type: reminder.taskType),
              const SizedBox(width: 12),
              // Info
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(reminder.taskLabel.split(' ').last,
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        )),
                    if (isOverdue) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFE53935).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
                        child: const Text('Overdue', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFE53935))),
                      ),
                    ],
                    if (reminder.snoozeCount > 0) ...[
                      const SizedBox(width: 6),
                      Text('💤${reminder.snoozeCount}', style: TextStyle(fontSize: 11, color: AppColors.textPrimary.withValues(alpha: 0.4))),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text(
                    reminder.plant?.nickname ?? 'Plant',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary.withValues(alpha: 0.5),
                        decoration: isDone ? TextDecoration.lineThrough : null),
                  ),
                  const SizedBox(height: 2),
                  Text(reminder.scheduledTime,
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary.withValues(alpha: 0.35))),
                ],
              )),
              // Actions
              if (isDone)
                Container(
                  width: 28, height: 28,
                  decoration: const BoxDecoration(color: AppColors.accentGreen, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.check, color: Colors.white, size: 16),
                )
              else ...[
                GestureDetector(
                  onTap: onComplete,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accentGreen, width: 2)),
                    child: const Icon(LucideIcons.check, size: 16, color: AppColors.accentGreen),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onSnooze,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.2), width: 1.5)),
                    child: Icon(LucideIcons.clock, size: 14, color: AppColors.textPrimary.withValues(alpha: 0.4)),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Task type badge
// =============================================================================

IconData _reminderTypeIcon(String type) {
  switch (type) {
    case 'water': return LucideIcons.droplets;
    case 'fertilize': return LucideIcons.sprout;
    case 'mist': return LucideIcons.cloudRain;
    case 'rotate': return LucideIcons.refreshCw;
    case 'repot': return LucideIcons.flower2;
    default: return LucideIcons.bell;
  }
}

class _TaskTypeBadge extends StatelessWidget {
  const _TaskTypeBadge({required this.type});
  final String type;

  Color get _bgColor {
    switch (type) {
      case 'water': return const Color(0xFFE3F2FD);
      case 'fertilize': return const Color(0xFFE8F5E9);
      case 'mist': return const Color(0xFFE0F2F1);
      case 'rotate': return const Color(0xFFFFF8E1);
      case 'repot': return const Color(0xFFEFEBE9);
      default: return AppColors.sageBase.withValues(alpha: 0.15);
    }
  }

  Color get _iconColor {
    switch (type) {
      case 'water': return const Color(0xFF1976D2);
      case 'fertilize': return const Color(0xFF388E3C);
      case 'mist': return const Color(0xFF00796B);
      case 'rotate': return const Color(0xFFF9A825);
      case 'repot': return const Color(0xFF6D4C41);
      default: return AppColors.accentGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: _bgColor, shape: BoxShape.circle),
      child: Center(child: Icon(
        _reminderTypeIcon(type),
        size: 18, color: _iconColor,
      )),
    );
  }
}

// =============================================================================
// Segment / filter widgets
// =============================================================================

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accentDark : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(child: Text(label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                  color: isActive ? AppColors.cream : AppColors.cream.withValues(alpha: 0.6)))),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentDark : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: isActive ? null : Border.all(color: AppColors.cream.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
            color: isActive ? AppColors.cream : AppColors.cream.withValues(alpha: 0.7))),
      ),
    );
  }
}

// =============================================================================
// Add Reminder Bottom Sheet
// =============================================================================

class _AddReminderSheet extends StatefulWidget {
  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  List<PlantSummary> _plants = [];
  PlantSummary? _selectedPlant;
  String _taskType = 'water';
  final _timeCtrl = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  static const _types = ['water', 'fertilize', 'mist', 'rotate', 'repot'];

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  @override
  void dispose() { _timeCtrl.dispose(); super.dispose(); }

  Future<void> _loadPlants() async {
    try {
      final data = await AuthService.getPlants();
      if (mounted) {
        setState(() => _plants = data.map((j) => PlantSummary.fromJson(j)).toList());
      }
    } catch (_) {}
  }

  Future<void> _onSubmit() async {
    if (_selectedPlant == null || _timeCtrl.text.isEmpty) return;
    setState(() { _isSubmitting = true; _error = null; });
    try {
      await AuthService.createPlantReminder(
        _selectedPlant!.id,
        taskType: _taskType,
        scheduledTime: _timeCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder added')));
      // Refresh the list
      // The parent screen will need to be refreshed — for now, pop and let on resume refresh
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isSubmitting = false; });
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
          // Handle bar
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.textPrimary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)))),
          const SizedBox(height: 16),
          const Text('Add Reminder', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 20),

          if (_error != null) ...[
            Container(width: double.infinity, padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 13))),
            const SizedBox(height: 16),
          ],

          // Plant picker
          _Label('Plant'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.08))),
            child: DropdownButton<PlantSummary>(
              value: _selectedPlant,
              hint: Text('Select a plant', style: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.3))),
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: _plants.map((p) => DropdownMenuItem(value: p, child: Text(p.nickname))).toList(),
              onChanged: (v) => setState(() => _selectedPlant = v),
            ),
          ),

          const SizedBox(height: 14),

          // Task type
          _Label('Task Type'),
          Wrap(spacing: 8, runSpacing: 8, children: _types.map((t) =>
            GestureDetector(onTap: () => setState(() => _taskType = t),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _taskType == t ? AppColors.accentDark : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: _taskType == t ? null : Border.all(color: AppColors.textPrimary.withValues(alpha: 0.1)),
                ),
                child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                    color: _taskType == t ? AppColors.cream : AppColors.textPrimary)),
              ))).toList()),

          const SizedBox(height: 14),

          // Scheduled time
          _Label('Scheduled Time'),
          TextField(
            controller: _timeCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. 2024-01-15 09:00',
              hintStyle: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.3)),
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting || _selectedPlant == null || _timeCtrl.text.isEmpty ? null : _onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel,
                disabledBackgroundColor: AppColors.buttonBg.withValues(alpha: 0.4),
                shape: const StadiumBorder(),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Add Reminder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)));
  }
}
