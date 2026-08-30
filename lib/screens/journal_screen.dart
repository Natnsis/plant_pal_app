import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../api/journal_store.dart';
import '../api/plantpal_api.dart';
import '../models/models.dart';
import '../theme/pp_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/pp_common.dart';
import '../widgets/pp_sheets.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

/// One row in the merged diary — either a cloud [JournalEntry] or a
/// device-only [LocalNote].
class _Item {
  _Item.remote(JournalEntry e)
      : type = e.type,
        note = e.note,
        imageUrl = e.imageUrl,
        hasPhoto = e.hasPhoto || e.imageUrl.isNotEmpty,
        date = e.date,
        plantName = e.plantName,
        synced = true,
        isMilestone = e.isMilestone,
        localId = null,
        cloudId = e.id;

  _Item.local(LocalNote n)
      : type = 'note',
        note = n.text,
        imageUrl = '',
        hasPhoto = false,
        date = n.createdAt,
        plantName = n.plantName,
        synced = n.synced,
        isMilestone = false,
        localId = n.id,
        cloudId = n.remoteId;

  final String type;
  final String note;
  final String imageUrl;
  final bool hasPhoto;
  final DateTime? date;
  final String plantName;
  final bool synced;
  final bool isMilestone;

  /// Non-null for a device-stored note.
  final String? localId;

  /// Non-null when this note also exists in the cloud (a synced local note,
  /// or a remote-only entry).
  final int? cloudId;

  bool get deletable => type == 'note';
}

class _JournalData {
  _JournalData(this.remote, this.local, this.plants);
  final List<JournalEntry> remote;
  final List<LocalNote> local;
  final List<Plant> plants;
}

class _JournalScreenState extends State<JournalScreen> {
  final _api = PlantPalApi.instance;
  final _store = JournalStore.instance;
  String _filter = 'All entries';
  bool _syncing = false;
  int _reloadKey = 0;
  static const _filters = ['All entries', 'Notes', 'Watering', 'Milestones'];

  Future<_JournalData> _load() async {
    List<JournalEntry> remote = const [];
    try {
      remote = await _api.journal();
    } catch (_) {}
    final local = await _store.all();
    List<Plant> plants = const [];
    try {
      plants = await _api.plants();
    } catch (_) {}
    return _JournalData(remote, local, plants);
  }

  bool _match(_Item e) => switch (_filter) {
        'Notes' => e.type == 'note',
        'Watering' => e.type == 'water',
        'Milestones' => e.isMilestone,
        _ => true,
      };

  List<_Item> _merge(_JournalData d) {
    final syncedRemoteIds = d.local
        .where((n) => n.remoteId != null)
        .map((n) => n.remoteId)
        .toSet();
    final items = <_Item>[
      for (final n in d.local) _Item.local(n),
      for (final e in d.remote)
        if (!syncedRemoteIds.contains(e.id)) _Item.remote(e),
    ]..sort((a, b) =>
        (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AsyncView<_JournalData>(
        key: ValueKey(_reloadKey),
        load: _load,
        padding: const EdgeInsets.only(top: 120),
        builder: (context, d, reload) {
          final all = _merge(d);
          final entries = all.where(_match).toList();
          final unsynced = d.local.where((n) => !n.synced).length;
          _Item? milestone;
          for (final e in all) {
            if (e.isMilestone) {
              milestone = e;
              break;
            }
          }
          return RefreshIndicator(
            color: PP.forest,
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 150),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: DisplayTitle('Growth diary')),
                    SquircleIconButton(
                      icon: LucideIcons.plus,
                      background: PP.ink,
                      foreground: PP.bone,
                      onTap: () => _addNote(d.plants, reload),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${all.length} ${all.length == 1 ? 'entry' : 'entries'}',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: PP.inkA(0.5))),
                const SizedBox(height: 18),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: _filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 9),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => setState(() => _filter = _filters[i]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 11),
                        decoration: BoxDecoration(
                          color:
                              _filter == _filters[i] ? PP.ink : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Text(_filters[i],
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _filter == _filters[i]
                                    ? PP.bone
                                    : PP.inkA(0.6))),
                      ),
                    ),
                  ),
                ),
                if (unsynced > 0) ...[
                  const SizedBox(height: 14),
                  _syncBanner(unsynced, reload),
                ],
                if (milestone != null) ...[
                  const SizedBox(height: 18),
                  _milestoneCard(milestone),
                ],
                const SizedBox(height: 14),
                if (all.isEmpty)
                  _empty()
                else if (entries.isEmpty)
                  _note('No entries in this filter.')
                else
                  for (final e in entries) ...[
                    _EntryCard(
                      item: e,
                      onDelete:
                          e.deletable ? () => _deleteNote(e, reload) : null,
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _note(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
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

  Widget _empty() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: PP.pale1,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(LucideIcons.bookOpen,
                  size: 32, color: PP.forest),
            ),
            const SizedBox(height: 16),
            Text('Your diary is empty',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: PP.track(18, -0.03))),
            const SizedBox(height: 6),
            Text(
              'Tap + to jot a note about a plant. Notes stay on this device '
              'until you sync them.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: PP.inkA(0.5)),
            ),
          ],
        ),
      );

  Widget _syncBanner(int count, Future<void> Function() reload) {
    return GestureDetector(
      onTap: _syncing ? null : () => _syncAll(reload),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: PP.forest,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Icon(_syncing ? LucideIcons.loader : LucideIcons.cloudUpload,
                size: 18, color: PP.lime),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                  _syncing
                      ? 'Syncing…'
                      : '$count note${count == 1 ? '' : 's'} kept on this device',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: PP.bone)),
            ),
            if (!_syncing)
              const Text('Sync to cloud',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: PP.lime)),
          ],
        ),
      ),
    );
  }

  Future<void> _addNote(
      List<Plant> plants, Future<void> Function() reload) async {
    final text = TextEditingController();
    Plant? plant = plants.isNotEmpty ? plants.first : null;
    final saved = await showPPSheet<bool>(
      context,
      title: 'New journal note',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plants.isNotEmpty) ...[
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
                          color: plant?.id == p.id ? PP.ink : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(p.displayName,
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: plant?.id == p.id
                                    ? PP.bone
                                    : PP.inkA(0.6))),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            PPSheetField(
              controller: text,
              hint: 'What did you notice?',
              minLines: 3,
              maxLines: 6,
              autofocus: true,
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Save note',
              background: PP.forest,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ),
    );
    if (saved != true || text.text.trim().isEmpty) return;
    await _store.add(
      plantId: plant?.id ?? 0,
      plantName: plant?.displayName ?? 'General',
      text: text.text.trim(),
    );
    if (mounted) {
      setState(() => _reloadKey++);
      await reload();
    }
  }

  Future<void> _syncAll(Future<void> Function() reload) async {
    setState(() => _syncing = true);
    var failed = 0;
    try {
      final notes = await _store.all();
      for (final n in notes.where((n) => !n.synced)) {
        try {
          final entry = await _api.createJournalEntry(
            type: 'note',
            plantId: n.plantId == 0 ? null : n.plantId,
            note: n.text,
            date: n.createdAt,
          );
          await _store.markSynced(n.id, remoteId: entry.id);
        } on ApiException {
          failed++;
        }
      }
      if (mounted) {
        setState(() => _reloadKey++);
        await reload();
      }
      if (mounted) {
        showPPSnack(
          context,
          failed == 0 ? 'Journal synced' : '$failed note(s) failed to sync',
          error: failed != 0,
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _deleteNote(_Item e, Future<void> Function() reload) async {
    final hasCloud = e.cloudId != null;
    final hasDevice = e.localId != null;

    final choice = await showPPSheet<String>(
      context,
      title: 'Delete note',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasDevice && hasCloud)
            _deleteRow(ctx, 'Remove from this device only', 'device'),
          if (hasDevice && hasCloud) const SizedBox(height: 8),
          if (hasCloud)
            _deleteRow(
                ctx,
                hasDevice
                    ? 'Delete everywhere (device + cloud)'
                    : 'Delete from cloud',
                'both'),
          if (hasCloud && hasDevice && !hasCloud) const SizedBox(height: 8),
          if (hasDevice && !hasCloud)
            _deleteRow(ctx, 'Delete this note', 'device'),
        ],
      ),
    );
    if (choice == null || !mounted) return;

    try {
      if ((choice == 'both') && e.cloudId != null) {
        await _api.deleteJournalEntry(e.cloudId!);
      }
      if ((choice == 'device' || choice == 'both') && e.localId != null) {
        await _store.delete(e.localId!);
      }
      if (mounted) {
        setState(() => _reloadKey++);
        await reload();
      }
    } on ApiException catch (err) {
      if (mounted) showPPSnack(context, err.message, error: true);
    }
  }

  Widget _deleteRow(BuildContext ctx, String label, String value) {
    return GestureDetector(
      onTap: () => Navigator.of(ctx).pop(value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.trash2, size: 17, color: PP.danger),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _milestoneCard(_Item e) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PP.forest,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MILESTONE',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: PP.bone.withValues(alpha: 0.6))),
              Text(_date(e.date),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: PP.bone.withValues(alpha: 0.6))),
            ],
          ),
          const SizedBox(height: 8),
          Text(e.note.isEmpty ? '${e.plantName} milestone' : e.note,
              style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  letterSpacing: PP.track(21, -0.03),
                  color: PP.bone)),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: e.imageUrl.isNotEmpty
                ? PlantImage(imageUrl: e.imageUrl, radius: 22)
                : Container(
                    decoration: BoxDecoration(
                      color: PP.bone.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(LucideIcons.sprout,
                        size: 56, color: PP.mint.withValues(alpha: 0.5)),
                  ),
          ),
        ],
      ),
    );
  }

  static String _date(DateTime? d) {
    if (d == null) return '';
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[d.month - 1]} ${d.day}';
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.item, this.onDelete});
  final _Item item;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final (tagBg, tagFg) = switch (item.type) {
      'water' => (PP.pale2, PP.forest),
      'fertilize' => (PP.pale2, PP.forest),
      'note' => (PP.amberBg, PP.amberFg),
      'growth' => (PP.forest, PP.bone),
      _ => (PP.pale1, PP.forest),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: item.synced ? null : Border.all(color: PP.lime, width: 1.3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: item.imageUrl.isNotEmpty
                ? PlantImage(imageUrl: item.imageUrl, radius: 20)
                : Container(
                    decoration: BoxDecoration(
                      color: PP.pale1,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(_iconFor(item.type),
                        size: 22, color: PP.forest),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: tagBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(item.type.toUpperCase(),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.55,
                              color: tagFg)),
                    ),
                    const SizedBox(width: 8),
                    Text(_JournalScreenState._date(item.date),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: PP.inkA(0.45))),
                    const Spacer(),
                    Icon(
                        item.synced
                            ? LucideIcons.cloud
                            : LucideIcons.smartphone,
                        size: 12,
                        color: PP.inkA(0.35)),
                    if (onDelete != null) ...[
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: onDelete,
                        behavior: HitTestBehavior.opaque,
                        child: Icon(LucideIcons.trash2,
                            size: 14, color: PP.inkA(0.4)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 7),
                Text(item.plantName.isEmpty ? 'Journal entry' : item.plantName,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: PP.track(14.5, -0.01))),
                if (item.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.note,
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: PP.inkA(0.55))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) => switch (type) {
        'water' => LucideIcons.droplet,
        'fertilize' => LucideIcons.sprout,
        'prune' => LucideIcons.scissors,
        'repot' => LucideIcons.house,
        'growth' => LucideIcons.trendingUp,
        _ => LucideIcons.pencil,
      };
}
