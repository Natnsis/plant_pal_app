import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/pp_theme.dart';
import '../widgets/pp_common.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 150),
            children: [
              const DisplayTitle('Growth diary'),
              const SizedBox(height: 8),
              Text('48 entries · 6 plants',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: PP.inkA(0.5))),
              const SizedBox(height: 18),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  children: const [
                    _JChip('All entries', selected: true),
                    SizedBox(width: 9),
                    _JChip('Watering'),
                    SizedBox(width: 9),
                    _JChip('Photos'),
                    SizedBox(width: 9),
                    _JChip('Milestones'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _milestoneCard(),
              const SizedBox(height: 14),
              _EntryCard(
                tag: 'Watered',
                tagBg: PP.pale2,
                tagFg: PP.forest,
                date: 'Aug 26',
                title: 'Peace Lily · 250 ml',
                body: 'Soil was bone dry, leaves perked up by evening.',
                icon: LucideIcons.sprout,
                iconBgGradient: true,
              ),
              const SizedBox(height: 12),
              _EntryCard(
                tag: 'Note',
                tagBg: PP.amberBg,
                tagFg: PP.amberFg,
                date: 'Aug 24',
                title: 'Golden Pothos · leaf spots',
                body: 'Opened a diagnosis session — watching for spread.',
                icon: LucideIcons.droplet,
              ),
            ],
          ),
          Positioned(
            right: 22,
            bottom: 104,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: PP.ink,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: PP.inkA(0.28),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plus, size: 17, color: PP.lime),
                    SizedBox(width: 9),
                    Text('New entry',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: PP.bone)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _milestoneCard() {
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
              Text('Aug 21',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: PP.bone.withValues(alpha: 0.6))),
            ],
          ),
          const SizedBox(height: 8),
          Text('Fiddle Leaf Fig passed 110 cm',
              style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  letterSpacing: PP.track(21, -0.03),
                  color: PP.bone)),
          const SizedBox(height: 14),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: PP.bone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(LucideIcons.sprout,
                size: 56, color: PP.mint.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 12),
          Text(
            'Third new leaf this season. Rotating the pot weekly is clearly working.',
            style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: PP.bone.withValues(alpha: 0.78)),
          ),
        ],
      ),
    );
  }
}

class _JChip extends StatelessWidget {
  const _JChip(this.label, {this.selected = false});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: selected ? PP.ink : Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? PP.bone : PP.inkA(0.6))),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.tag,
    required this.tagBg,
    required this.tagFg,
    required this.date,
    required this.title,
    required this.body,
    required this.icon,
    this.iconBgGradient = false,
  });

  final String tag;
  final Color tagBg;
  final Color tagFg;
  final String date;
  final String title;
  final String body;
  final IconData icon;
  final bool iconBgGradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: iconBgGradient ? PP.plantImage : null,
              color: iconBgGradient ? null : PP.pale1,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon,
                size: iconBgGradient ? 30 : 24,
                color: PP.forest.withValues(alpha: iconBgGradient ? 0.45 : 1)),
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
                      child: Text(tag.toUpperCase(),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.55,
                              color: tagFg)),
                    ),
                    const SizedBox(width: 8),
                    Text(date,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: PP.inkA(0.45))),
                  ],
                ),
                const SizedBox(height: 7),
                Text(title,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: PP.track(14.5, -0.01))),
                const SizedBox(height: 2),
                Text(body,
                    style: TextStyle(
                        fontSize: 13,
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
