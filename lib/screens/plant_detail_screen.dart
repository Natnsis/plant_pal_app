import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../api/plantpal_api.dart';
import '../models/models.dart';
import '../theme/pp_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/pp_common.dart';
import 'diagnosis_screen.dart';

class PlantDetailScreen extends StatefulWidget {
  const PlantDetailScreen({super.key, required this.plantId});

  final int plantId;

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _Detail {
  _Detail(this.plant, this.carePlan, this.growth, this.activities);
  final Plant plant;
  final CarePlan? carePlan;
  final List<GrowthMetric> growth;
  final List<ActivityLog> activities;
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final _api = PlantPalApi.instance;
  static const _tabs = ['Care', 'Growth', 'Journal', 'Info'];
  String _tab = 'Care';
  bool _loggingWater = false;

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
    return _Detail(plant, care, growth, acts);
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
                _hero(context, d.plant),
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

  Widget _hero(BuildContext context, Plant plant) {
    final health = plant.healthScore;
    return SizedBox(
      height: 380,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE7ECDB), Color(0xFFD3E0BD)],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Icon(LucideIcons.sprout,
                  size: 250, color: PP.forest.withValues(alpha: 0.4)),
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
                  const RoundIconButton(icon: LucideIcons.moreVertical),
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
            child: _panel(d),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: _loggingWater ? 'Logging…' : 'Log watering',
                  background: _loggingWater ? PP.inkA(0.4) : PP.ink,
                  onPressed: _loggingWater ? null : () => _logWater(reload),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const DiagnosisScreen())),
                child: Container(
                  width: 62,
                  height: 58,
                  decoration: BoxDecoration(
                    color: PP.pale2,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(LucideIcons.stethoscope,
                      size: 21, color: PP.forest),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _logWater(Future<void> Function() reload) async {
    setState(() => _loggingWater = true);
    try {
      await _api.logActivity(widget.plantId,
          activityType: 'watered', notes: 'Logged from plant detail');
      if (mounted) showPPSnack(context, 'Watering logged');
      await reload();
    } on ApiException catch (e) {
      if (mounted) showPPSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loggingWater = false);
    }
  }

  Widget _panel(_Detail d) {
    switch (_tab) {
      case 'Growth':
        final latest = d.growth.isEmpty ? null : d.growth.last;
        return _grid([
          _Cell('Height',
              latest == null ? '—' : '${latest.heightCm.toStringAsFixed(0)} cm'),
          _Cell('Readings', '${d.growth.length}'),
          _Cell('Rate', latest?.rate.isNotEmpty == true ? latest!.rate : 'Steady'),
          _Cell(
              'Last logged',
              latest?.recordedDate == null
                  ? '—'
                  : _shortDate(latest!.recordedDate!)),
        ]);
      case 'Journal':
        if (d.activities.isEmpty) {
          return _softPanel('No activity logged yet.');
        }
        return Column(
          children: [
            for (final a in d.activities.take(4)) ...[
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
        );
      case 'Info':
        return _grid([
          _Cell('Species',
              d.plant.species.scientificName.isEmpty
                  ? d.plant.species.commonName
                  : d.plant.species.scientificName),
          _Cell('Difficulty', _difficultyLabel(d.plant.species.difficulty)),
          _Cell('Family',
              d.plant.species.family.isEmpty ? '—' : d.plant.species.family),
          _Cell('Toxicity', d.plant.species.petSafe ? 'Pet-safe' : 'Toxic'),
        ]);
      default:
        final c = d.carePlan;
        if (c == null) return _softPanel('No care plan generated yet.');
        return _grid([
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
        ]);
    }
  }

  Widget _grid(List<Widget> cells) => GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.85,
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
                      maxLines: 1,
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
