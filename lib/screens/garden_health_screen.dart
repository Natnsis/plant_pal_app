import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/plantpal_api.dart';
import '../models/models.dart';
import '../theme/pp_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/pp_common.dart';
import 'plant_detail_screen.dart';

/// The screen behind the Home "Garden health" card: every plant ranked by
/// its health score, so the number on the card is actually explorable.
class GardenHealthScreen extends StatelessWidget {
  const GardenHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = PlantPalApi.instance;
    return Scaffold(
      backgroundColor: PP.bone,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
              child: Row(
                children: [
                  SquircleIconButton(
                    icon: LucideIcons.chevronLeft,
                    background: PP.card.withValues(alpha: 0.8),
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text('Garden health',
                          style: TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),
            Expanded(
              child: AsyncView<List<Plant>>(
                load: api.plants,
                emptyWhen: (l) => l.isEmpty,
                emptyLabel: 'No plants to report on yet',
                emptyIcon: LucideIcons.sprout,
                builder: (context, plants, reload) {
                  final sorted = [...plants]
                    ..sort((a, b) => a.healthScore.compareTo(b.healthScore));
                  final avg = plants.isEmpty
                      ? 0
                      : (plants
                                  .map((p) => p.healthScore)
                                  .reduce((a, b) => a + b) /
                              plants.length)
                          .round();
                  final needAttention =
                      plants.where((p) => p.needsAttention).length;
                  return RefreshIndicator(
                    color: PP.forest,
                    onRefresh: reload,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(22, 6, 22, 30),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: PP.forest,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text.rich(TextSpan(
                                text: '$avg',
                                style: TextStyle(
                                    fontSize: 46,
                                    height: 0.9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: PP.track(46, -0.05),
                                    color: PP.bone),
                                children: const [
                                  TextSpan(
                                      text: '%',
                                      style: TextStyle(fontSize: 20)),
                                ],
                              )),
                              const SizedBox(width: 14),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                    'Average across ${plants.length} '
                                    '${plants.length == 1 ? 'plant' : 'plants'}'
                                    '${needAttention > 0 ? '\n$needAttention need attention' : ''}',
                                    style: TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            PP.bone.withValues(alpha: 0.75))),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        for (final p in sorted) ...[
                          _HealthRow(plant: p),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({required this.plant});
  final Plant plant;

  @override
  Widget build(BuildContext context) {
    final score = plant.healthScore.clamp(0, 100);
    final color = score >= 75
        ? PP.forest
        : score >= 50
            ? const Color(0xFF9AA84B)
            : PP.danger;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PlantDetailScreen(plantId: plant.id))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            PlantImage(
                imageUrl: plant.photoUrl, width: 46, height: 46, radius: 15),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plant.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      minHeight: 6,
                      backgroundColor: PP.inkA(0.08),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('$score',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      ),
    );
  }
}
