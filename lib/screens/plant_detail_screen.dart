import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../api/journal_store.dart';
import '../api/media_channel.dart';
import '../api/plantpal_api.dart';
import '../models/models.dart';
import '../theme/pp_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/pp_common.dart';
import '../widgets/pp_sheets.dart';
import 'diagnosis_screen.dart';
import 'root_shell.dart';

class PlantDetailScreen extends StatefulWidget {
  const PlantDetailScreen({super.key, required this.plantId});

  final int plantId;

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _Detail {
  _Detail(this.plant, this.carePlan, this.growth, this.activities, this.journal);
  final Plant plant;
  final CarePlan? carePlan;
  final List<GrowthMetric> growth;
  final List<ActivityLog> activities;
  final List<JournalEntry> journal;
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final _api = PlantPalApi.instance;
  final _store = JournalStore.instance;
  static const _tabs = ['Care', 'Growth', 'Journal', 'Info'];
  String _tab = 'Care';
  bool _busy = false;
  bool _diagnosing = false;

  List<LocalNote> _notes = const [];
  final _noteDraft = TextEditingController();
  Future<void> Function()? _reload;

  @override
  void initState() {
    super.initState();
    _refreshNotes();
  }

  @override
  void dispose() {
    _noteDraft.dispose();
    super.dispose();
  }

  Future<void> _refreshNotes() async {
    final notes = await _store.forPlant(widget.plantId);
    if (mounted) setState(() => _notes = notes);
  }

  Future<_Detail> _load() async {
    final plant = await _api.plant(widget.plantId);
    CarePlan? care;
    try {
      care = await _api.carePlan(widget.plantId);
    } catch (_) {}
    List<GrowthMetric> growth = const [];
    try {
      growth = await _api.growth(widget.plantId);
    } catch (_) {}
    List<ActivityLog> acts = const [];
    try {
      acts = await _api.activities(widget.plantId);
    } catch (_) {}
    List<JournalEntry> journal = const [];
    try {
      journal = await _api.journal(plantId: widget.plantId);
    } catch (_) {}
    return _Detail(plant, care, growth, acts, journal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PP.bone,
      body: AsyncView<_Detail>(
        load: _load,
        padding: const EdgeInsets.only(top: 120),
        builder: (context, d, reload) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _hero(context, d.plant, reload),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: _sheet(context, d, reload),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _hero(
      BuildContext context, Plant plant, Future<void> Function() reload) {
    final health = plant.healthScore;
    // `reload` is captured by the menu callbacks below.
    _reload = reload;
    return SizedBox(
      height: 380,
      child: Stack(
        children: [
          Positioned.fill(
            child: PlantImage(
              imageUrl: plant.photoUrl,
              radius: 0,
              iconSize: 250,
              child: plant.photoUrl.startsWith('http')
                  ? null
                  : Icon(LucideIcons.sprout,
                      size: 250, color: PP.forest.withValues(alpha: 0.4)),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33000000), Colors.transparent, Color(0x22000000)],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RoundIconButton(
                    icon: LucideIcons.chevronLeft,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  _PlantMenu(
                    onChangePhoto: () => _changePhoto(plant),
                    onDelete: () => _confirmDelete(plant),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 120,
            right: 24,
            child: _GlassStat(
              icon: LucideIcons.heartPulse,
              label: 'Health\nscore',
              value: '$health',
            ),
          ),
          Positioned(
            top: 184,
            left: 22,
            child: _GlassStat(
              icon: LucideIcons.hand,
              label: 'Care\nlevel',
              value: _difficultyLabel(plant.species.difficulty),
            ),
          ),
          Positioned(
            top: 262,
            right: 46,
            child: _GlassStat(
              icon: LucideIcons.shield,
              label: 'Pet\nsafe',
              value: plant.species.petSafe ? 'Yes' : 'No',
              light: true,
            ),
          ),
        ],
      ),
    );
  }

  String _difficultyLabel(Difficulty d) => switch (d) {
        Difficulty.easy => 'Easy',
        Difficulty.medium => 'Medium',
        Difficulty.hard => 'Hard',
      };

  int get _unsynced => _notes.where((n) => !n.synced).length;

  Widget _sheet(BuildContext context, _Detail d, Future<void> Function() reload) {
    final plant = d.plant;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: PP.bone,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
        boxShadow: [
          BoxShadow(
              color: PP.inkA(0.10),
              blurRadius: 40,
              offset: const Offset(0, -18)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plant.displayName,
                        style: TextStyle(
                            fontSize: 27,
                            height: 1.05,
                            fontWeight: FontWeight.w600,
                            letterSpacing: PP.track(27, -0.035))),
                    const SizedBox(height: 2),
                    Text(
                        [
                          if (plant.location.isNotEmpty) plant.location,
                          if (plant.species.scientificName.isNotEmpty)
                            plant.species.scientificName,
                        ].join(' · '),
                        style: TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            color: PP.inkA(0.5))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Health',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: PP.inkA(0.45))),
                  Text('${plant.healthScore}',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: PP.track(24, -0.03),
                          color: PP.forest)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Tag('${_difficultyLabel(plant.species.difficulty)} care'),
              if (plant.species.petSafe) const Tag('Pet-friendly'),
              if (plant.species.family.isNotEmpty) Tag(plant.species.family),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: PP.pale4,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              children: [
                for (final t in _tabs)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color:
                              _tab == t ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        alignment: Alignment.center,
                        child: Text(t,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _tab == t ? PP.ink : PP.inkA(0.5))),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: _panel(d, reload),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _primaryAction(d, reload)),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _diagnosing ? null : () => _openChat(d.plant),
                child: Container(
                  width: 62,
                  height: 58,
                  decoration: BoxDecoration(
                    color: PP.pale2,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: _diagnosing
                      ? const Padding(
                          padding: EdgeInsets.all(18),
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: PP.forest),
                        )
                      : const Icon(LucideIcons.stethoscope,
                          size: 21, color: PP.forest),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _primaryAction(_Detail d, Future<void> Function() reload) {
    final (label, action) = switch (_tab) {
      'Growth' => ('Log growth', () => _logGrowthSheet(reload)),
      'Journal' => (
          _unsynced > 0 ? 'Sync to cloud ($_unsynced)' : 'Synced with cloud',
          _unsynced > 0 ? () => _syncNotes(reload) : null,
        ),
      'Info' => ('Ask plant doctor', () => _openChat(d.plant)),
      _ => ('Log care', () => _logCareSheet(reload)),
    };
    final disabled = _busy || _diagnosing || action == null;
    return PrimaryButton(
      label: _busy ? 'Working…' : label,
      background: disabled ? PP.inkA(0.4) : PP.ink,
      onPressed: disabled ? null : action,
    );
  }

  // ── actions ───────────────────────────────────────────────────────────────

  Future<void> _logCareSheet(Future<void> Function() reload) async {
    var choice = 'Water';
    final picked = await showPPSheet<String>(
      context,
      title: 'Log care',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What did you do for this plant?',
                style: TextStyle(fontSize: 13, color: PP.inkA(0.6))),
            const SizedBox(height: 12),
            PPChoiceChips(
              options: const ['Water', 'Fertilize', 'Mist', 'Rotate', 'Repot'],
              value: choice,
              onChanged: (v) => setSheet(() => choice = v),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Log it',
              background: PP.forest,
              onPressed: () => Navigator.of(ctx).pop(choice),
            ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    const map = {
      'Water': 'watered',
      'Fertilize': 'fertilized',
      'Mist': 'misted',
      'Rotate': 'rotated',
      'Repot': 'repotted',
    };
    setState(() => _busy = true);
    try {
      await _api.logActivity(widget.plantId,
          activityType: map[picked]!, notes: 'Logged from plant detail');
      if (mounted) showPPSnack(context, '$picked logged');
      await reload();
    } on ApiException catch (e) {
      if (mounted) showPPSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logGrowthSheet(Future<void> Function() reload) async {
    final height = TextEditingController();
    var rate = 'moderate';
    final ok = await showPPSheet<bool>(
      context,
      title: 'Log growth',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PPSheetField(
              controller: height,
              hint: 'Height in cm',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Text('Growth rate',
                style: TextStyle(fontSize: 12.5, color: PP.inkA(0.5))),
            const SizedBox(height: 8),
            PPChoiceChips(
              options: const ['slow', 'moderate', 'fast'],
              value: rate,
              onChanged: (v) => setSheet(() => rate = v),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Save measurement',
              background: PP.forest,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final cm = double.tryParse(height.text.trim());
    if (cm == null || cm <= 0) {
      if (mounted) showPPSnack(context, 'Enter a valid height', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await _api.logGrowth(widget.plantId, heightCm: cm, rate: rate);
      if (mounted) showPPSnack(context, 'Growth logged');
      await reload();
    } on ApiException catch (e) {
      if (mounted) showPPSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addNote(String plantName) async {
    final text = _noteDraft.text.trim();
    if (text.isEmpty) return;
    _noteDraft.clear();
    await _store.add(
        plantId: widget.plantId, plantName: plantName, text: text);
    await _refreshNotes();
  }

  Future<void> _syncNotes(Future<void> Function() reload) async {
    setState(() => _busy = true);
    var failed = 0;
    try {
      for (final n in _notes.where((n) => !n.synced).toList()) {
        try {
          final entry = await _api.createJournalEntry(
            type: 'note',
            plantId: n.plantId,
            note: n.text,
            date: n.createdAt,
          );
          await _store.markSynced(n.id, remoteId: entry.id);
        } on ApiException {
          failed++;
        }
      }
      await _refreshNotes();
      await reload();
      if (mounted) {
        showPPSnack(
          context,
          failed == 0
              ? 'Journal synced to cloud'
              : '$failed note(s) failed to sync',
          error: failed != 0,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Opens the plant doctor as a fast, unlimited text chat seeded with this
  /// plant's context (`POST /diagnosis/chat`). Photo-based disease diagnosis
  /// lives on the Scan tab's "Diagnose" mode.
  Future<void> _openChat(Plant plant) async {
    setState(() => _diagnosing = true);
    try {
      final ctx = [
        plant.displayName,
        if (plant.species.commonName.isNotEmpty &&
            plant.species.commonName != plant.displayName)
          '(${plant.species.commonName})',
        if (plant.location.isNotEmpty) 'in the ${plant.location}',
        'health ${plant.healthScore}/100',
      ].join(' ');
      final session = await _api.startChat(context: ctx);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DiagnosisScreen(
            sessionId: session.id, plantName: plant.displayName),
      ));
    } on ApiException catch (e) {
      if (mounted) showPPSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _diagnosing = false);
    }
  }

  Future<void> _changePhoto(Plant plant) async {
    final source = await showPPSheet<String>(
      context,
      title: 'Change photo',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sourceRow(ctx, LucideIcons.camera, 'Take a photo', 'camera'),
          const SizedBox(height: 8),
          _sourceRow(ctx, LucideIcons.image, 'Choose from gallery', 'gallery'),
        ],
      ),
    );
    if (source == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final bytes = source == 'camera'
          ? await MediaChannel.capture()
          : await MediaChannel.pickFromGallery();
      if (bytes == null) return; // cancelled
      await _api.updatePlantPhoto(plant.id, bytes);
      if (mounted) showPPSnack(context, 'Photo updated');
      await _reload?.call();
    } on MediaException catch (e) {
      if (mounted) showPPSnack(context, e.message, error: true);
    } on ApiException catch (e) {
      if (mounted) showPPSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _sourceRow(
      BuildContext ctx, IconData icon, String label, String value) {
    return GestureDetector(
      onTap: () => Navigator.of(ctx).pop(value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: PP.forest),
            const SizedBox(width: 14),
            Text(label,
                style: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Plant plant) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PP.bone,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Row(
          children: [
            const Text('🥀', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Let ${plant.displayName} go?',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        content: Text(
          "This removes ${plant.displayName} from your garden for good — its "
          "care plan, reminders, growth history and logged care all go with "
          "it. There's no undo.",
          style: TextStyle(fontSize: 13.5, height: 1.5, color: PP.inkA(0.65)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Keep it',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: PP.forest)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: PP.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _api.deletePlant(plant.id);
      if (!mounted) return;
      showPPSnack(context, '${plant.displayName} removed from your garden');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootShell(initialIndex: 1)),
        (r) => false,
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showPPSnack(context, e.message, error: true);
      }
    }
  }

  // ── panels ────────────────────────────────────────────────────────────────

  Widget _panel(_Detail d, Future<void> Function() reload) {
    switch (_tab) {
      case 'Growth':
        return _growthPanel(d);
      case 'Journal':
        return _journalPanel(d);
      case 'Info':
        return _infoPanel(d);
      default:
        return _carePanel(d);
    }
  }

  Widget _carePanel(_Detail d) {
    final c = d.carePlan;
    if (c == null) {
      return _softPanel(
          'No care plan yet. Scan-confirmed plants get one automatically.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _grid([
          _Cell(
              'Watering',
              c.wateringFrequencyDays > 0
                  ? 'Every ${c.wateringFrequencyDays}d'
                  : (c.wateringMethod.isEmpty ? '—' : c.wateringMethod),
              c.wateringAmount.isEmpty ? null : c.wateringAmount),
          _Cell('Light',
              c.lightRequirement.isEmpty ? '—' : c.lightRequirement),
          _Cell(
              'Temperature',
              (c.tempMinC == 0 && c.tempMaxC == 0)
                  ? '—'
                  : '${c.tempMinC}–${c.tempMaxC} °C'),
          _Cell('Humidity',
              c.humidityRequirement.isEmpty ? '—' : c.humidityRequirement),
        ]),
        if (c.wateringTips.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PP.pale1,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.droplet, size: 15, color: PP.forest),
                    const SizedBox(width: 8),
                    Text('WATERING TIP',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: PP.forest)),
                  ],
                ),
                const SizedBox(height: 7),
                Text(c.wateringTips,
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: PP.forest)),
              ],
            ),
          ),
        ],
        if (d.activities.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Recent care',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: PP.inkA(0.5))),
          const SizedBox(height: 8),
          for (final a in d.activities.take(3)) ...[
            _JournalRow(
              _titleCase(a.type),
              [
                if (a.loggedDate != null) _shortDate(a.loggedDate!),
                if (a.notes.isNotEmpty) a.notes,
              ].join(' · '),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }

  Widget _growthPanel(_Detail d) {
    final latest = d.growth.isEmpty ? null : d.growth.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _grid([
          _Cell('Height',
              latest == null ? '—' : '${latest.heightCm.toStringAsFixed(0)} cm'),
          _Cell('Readings', '${d.growth.length}'),
          _Cell('Rate',
              latest?.rate.isNotEmpty == true ? _titleCase(latest!.rate) : 'Steady'),
          _Cell(
              'Last logged',
              latest?.recordedDate == null
                  ? '—'
                  : _shortDate(latest!.recordedDate!)),
        ]),
        if (d.growth.length > 1) ...[
          const SizedBox(height: 10),
          for (final g in d.growth.take(4)) ...[
            _JournalRow(
              '${g.heightCm.toStringAsFixed(0)} cm',
              [
                if (g.recordedDate != null) _shortDate(g.recordedDate!),
                if (g.rate.isNotEmpty) _titleCase(g.rate),
              ].join(' · '),
            ),
            const SizedBox(height: 8),
          ],
        ] else if (d.growth.isEmpty)
          _softPanel('No measurements yet. Tap "Log growth" to add one.'),
      ],
    );
  }

  Widget _journalPanel(_Detail d) {
    // Remote entries not already represented by a synced local note.
    final localRemoteIds =
        _notes.where((n) => n.remoteId != null).map((n) => n.remoteId).toSet();
    final remoteOnly = d.journal
        .where((e) => e.type == 'note' && !localRemoteIds.contains(e.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteDraft,
                  minLines: 1,
                  maxLines: 3,
                  onSubmitted: (_) => _addNote(d.plant.displayName),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: InputBorder.none,
                    hintText: 'Write a note about this plant…',
                    hintStyle: TextStyle(
                        color: PP.inkA(0.4), fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _addNote(d.plant.displayName),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                      color: PP.ink, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.plus, size: 18, color: PP.lime),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _notes.isEmpty && remoteOnly.isEmpty
              ? 'Notes are kept on this device until you sync them.'
              : '$_unsynced not synced · ${_notes.length - _unsynced + remoteOnly.length} in cloud',
          style: TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w500, color: PP.inkA(0.45)),
        ),
        const SizedBox(height: 10),
        if (_notes.isEmpty && remoteOnly.isEmpty)
          _softPanel('No journal notes yet.')
        else ...[
          for (final n in _notes) ...[
            _NoteCard(
              text: n.text,
              meta:
                  '${_shortDate(n.createdAt)} · ${n.synced ? 'synced' : 'on device'}',
              synced: n.synced,
              onDelete: () async {
                await _store.delete(n.id);
                await _refreshNotes();
              },
            ),
            const SizedBox(height: 8),
          ],
          for (final e in remoteOnly) ...[
            _NoteCard(
              text: e.note,
              meta: '${e.date == null ? '' : '${_shortDate(e.date!)} · '}synced',
              synced: true,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }

  Widget _infoPanel(_Detail d) {
    final s = d.plant.species;
    final c = d.carePlan;
    final rows = <(String, String)>[
      if (s.commonName.isNotEmpty) ('Common name', s.commonName),
      if (s.scientificName.isNotEmpty) ('Scientific name', s.scientificName),
      if (s.family.isNotEmpty) ('Family', s.family),
      if (s.origin.isNotEmpty) ('Origin', s.origin),
      ('Care level', _difficultyLabel(s.difficulty)),
      ('Pet-safe', s.petSafe ? 'Yes' : 'No'),
      if (c != null && c.soilType.isNotEmpty) ('Soil', c.soilType),
      if (c != null && c.fertilizerType.isNotEmpty)
        ('Fertilizer', c.fertilizerType),
      if (c != null && c.lightRequirement.isNotEmpty)
        ('Light', c.lightRequirement),
      if (c != null && c.humidityRequirement.isNotEmpty)
        ('Humidity', c.humidityRequirement),
      if (c != null && !(c.tempMinC == 0 && c.tempMaxC == 0))
        ('Temperature', '${c.tempMinC}–${c.tempMaxC} °C'),
      if (c != null && c.pruningFrequency.isNotEmpty)
        ('Pruning', c.pruningFrequency),
      if (c != null && c.repottingFrequency.isNotEmpty)
        ('Repotting', c.repottingFrequency),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : Border(bottom: BorderSide(color: PP.inkA(0.07))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(rows[i].$1,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: PP.inkA(0.45))),
                  ),
                  Expanded(
                    child: Text(rows[i].$2,
                        style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _grid(List<Widget> cells) => GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        // Roomy enough for a label + value + a wrapped sub-line without the
        // 1px overflow the tighter ratio produced.
        childAspectRatio: 1.55,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: cells,
      );

  Widget _softPanel(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: PP.inkA(0.55))),
      );

  static String _titleCase(String s) => s.isEmpty
      ? s
      : s
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');

  static String _shortDate(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[d.month - 1]} ${d.day}';
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.text,
    required this.meta,
    required this.synced,
    this.onDelete,
  });

  final String text;
  final String meta;
  final bool synced;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: synced ? null : Border.all(color: PP.lime, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text,
              style: const TextStyle(
                  fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(synced ? LucideIcons.cloud : LucideIcons.smartphone,
                  size: 12, color: PP.inkA(0.4)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(meta,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: PP.inkA(0.4))),
              ),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(LucideIcons.trash2,
                      size: 14, color: PP.inkA(0.35)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.label, this.value, [this.sub]);
  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: PP.inkA(0.45))),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: PP.track(18, -0.02))),
          if (sub != null) ...[
            const SizedBox(height: 1),
            Text(sub!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: PP.inkA(0.45))),
          ],
        ],
      ),
    );
  }
}

class _JournalRow extends StatelessWidget {
  const _JournalRow(this.title, this.date);
  final String title;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                const BoxDecoration(color: PP.forest, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                if (date.isNotEmpty)
                  Text(date,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: PP.inkA(0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassStat extends StatelessWidget {
  const _GlassStat({
    required this.icon,
    required this.label,
    required this.value,
    this.light = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final fg = light ? PP.ink : PP.bone;
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: light
            ? PP.bone.withValues(alpha: 0.72)
            : PP.forest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: light ? PP.lime.withValues(alpha: 0.9) : PP.lime,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(color: PP.lime.withValues(alpha: 0.28), blurRadius: 24),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11.5,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: fg)),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}

/// The hero-overlay "⋮" menu: change photo or delete the plant.
class _PlantMenu extends StatelessWidget {
  const _PlantMenu({required this.onChangePhoto, required this.onDelete});

  final VoidCallback onChangePhoto;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: PP.bone,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      position: PopupMenuPosition.under,
      onSelected: (v) {
        if (v == 'photo') onChangePhoto();
        if (v == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'photo',
          child: Row(
            children: [
              Icon(LucideIcons.camera, size: 18, color: PP.forest),
              SizedBox(width: 12),
              Text('Change photo',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(LucideIcons.trash2, size: 18, color: PP.danger),
              SizedBox(width: 12),
              Text('Delete plant',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: PP.danger)),
            ],
          ),
        ),
      ],
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: PP.card.withValues(alpha: 0.85),
          shape: BoxShape.circle,
        ),
        child: const Icon(LucideIcons.moreVertical, size: 19, color: PP.ink),
      ),
    );
  }
}
