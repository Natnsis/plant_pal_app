import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/demo.dart';
import '../theme/pp_theme.dart';
import '../widgets/pp_common.dart';
import 'plant_detail_screen.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  String _room = 'All';

  @override
  Widget build(BuildContext context) {
    final plants = demoPlants
        .where((p) => _room == 'All' || p.room == _room)
        .toList(growable: false);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 120),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: DisplayTitle('Curated plants\nfor your space'),
              ),
              SquircleIconButton(icon: LucideIcons.search, onTap: () {}),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: PP.ink,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.filter, size: 14, color: PP.lime),
                      SizedBox(width: 8),
                      Text('Filters',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: PP.bone)),
                    ],
                  ),
                ),
                for (final r in demoRooms) ...[
                  const SizedBox(width: 9),
                  FilterChipPP(
                    label: r == 'All' ? 'All plants' : r,
                    selected: _room == r,
                    showClose: true,
                    onTap: () => setState(() => _room = r),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          _plantOfMonth(),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [for (final p in plants) _PlantGridCard(plant: p)],
          ),
        ],
      ),
    );
  }

  Widget _plantOfMonth() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              color: PP.forest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: PP.bone.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.sprout, size: 15, color: PP.lime),
                        SizedBox(width: 9),
                        Text('Plant of the month',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: PP.bone)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _circleBtn(LucideIcons.heart,
                          bg: PP.bone.withValues(alpha: 0.16), fg: PP.bone),
                      const SizedBox(width: 8),
                      _circleBtn(LucideIcons.arrowUpRight,
                          bg: PP.bone, fg: PP.ink),
                    ],
                  ),
                ],
              ),
            ),
            PlantImage(
                height: 190,
                width: double.infinity,
                radius: 0,
                iconSize: 112),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Monstera\nDeliciosa',
                            style: TextStyle(
                                fontSize: 21,
                                height: 1.1,
                                fontWeight: FontWeight.w600,
                                letterSpacing: PP.track(21, -0.03))),
                        const SizedBox(height: 4),
                        Text('Low-maintenance · Air purifier',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: PP.inkA(0.5))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const PlantDetailScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 13),
                      decoration: BoxDecoration(
                        color: PP.ink,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Open',
                              style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: PP.bone)),
                          SizedBox(width: 7),
                          Icon(LucideIcons.arrowRight,
                              size: 14, color: PP.lime),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, {required Color bg, required Color fg}) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, size: 17, color: fg),
    );
  }
}

class _PlantGridCard extends StatelessWidget {
  const _PlantGridCard({required this.plant});
  final Plant plant;

  @override
  Widget build(BuildContext context) {
    final dark = plant.dark;
    final fg = dark ? PP.bone : PP.ink;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PlantDetailScreen())),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: dark ? PP.forest : Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 112,
              child: Stack(
                children: [
                  PlantImage(
                      height: 112, width: double.infinity, dark: dark, iconSize: 58),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: plant.status.badgeBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        plant.status.label.toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: plant.status.badgeFg),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 11),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plant.name,
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: PP.track(14.5, -0.02),
                          color: fg)),
                  Text(plant.room,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: fg.withValues(alpha: 0.55))),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Icon(LucideIcons.droplet,
                          size: 12, color: fg.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Text(plant.water,
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: fg.withValues(alpha: 0.6))),
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
}
