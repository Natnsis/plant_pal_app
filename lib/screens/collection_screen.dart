import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/plantpal_api.dart';
import '../models/models.dart';
import '../theme/pp_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/pp_common.dart';
import 'plant_detail_screen.dart';
import 'scan_screen.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final _api = PlantPalApi.instance;
  String _room = 'All';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AsyncView<List<Plant>>(
        load: _api.plants,
        padding: const EdgeInsets.only(top: 120),
        builder: (context, plants, reload) {
          final rooms = <String>{
            'All',
            for (final p in plants)
              if (p.location.isNotEmpty) p.location,
          }.toList();
          final visible = _room == 'All'
              ? plants
              : plants.where((p) => p.location == _room).toList();

          return RefreshIndicator(
            color: PP.forest,
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 120),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                        child: DisplayTitle('Your plant\ncollection')),
                    SquircleIconButton(icon: LucideIcons.search, onTap: () {}),
                  ],
                ),
                const SizedBox(height: 20),
                if (rooms.length > 1)
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: rooms.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: 9),
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 11),
                            decoration: BoxDecoration(
                              color: PP.ink,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Row(
                              children: [
                                Icon(LucideIcons.filter,
                                    size: 14, color: PP.lime),
                                SizedBox(width: 8),
                                Text('Filters',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: PP.bone)),
                              ],
                            ),
                          );
                        }
                        final r = rooms[i - 1];
                        return FilterChipPP(
                          label: r == 'All' ? 'All plants' : r,
                          selected: _room == r,
                          showClose: true,
                          onTap: () => setState(() => _room = r),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 18),
                if (visible.isEmpty)
                  _emptyState(context)
                else
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      for (final p in visible) _PlantGridCard(plant: p),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: PP.pale1,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(LucideIcons.sprout, size: 40, color: PP.forest),
          ),
          const SizedBox(height: 18),
          Text('No plants yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: PP.track(20, -0.03))),
          const SizedBox(height: 8),
          Text(
            "Scan your first plant and we'll build its care plan and reminders.",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: PP.inkA(0.5)),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ScanScreen())),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
              decoration: BoxDecoration(
                color: PP.ink,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Text('Scan a plant',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: PP.bone)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantGridCard extends StatelessWidget {
  const _PlantGridCard({required this.plant});
  final Plant plant;

  @override
  Widget build(BuildContext context) {
    final dark = plant.needsAttention;
    final fg = dark ? PP.bone : PP.ink;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PlantDetailScreen(plantId: plant.id))),
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
                      height: 112,
                      width: double.infinity,
                      dark: dark,
                      iconSize: 58),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: dark ? PP.amberBg : Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        (dark ? 'Watch' : 'Healthy').toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: dark ? PP.amberFg : PP.forest),
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
                  Text(plant.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: PP.track(14.5, -0.02),
                          color: fg)),
                  Text(
                      plant.location.isEmpty
                          ? plant.species.commonName
                          : plant.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: fg.withValues(alpha: 0.55))),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Icon(LucideIcons.heartPulse,
                          size: 12, color: fg.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Text('Health ${plant.healthScore}',
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
