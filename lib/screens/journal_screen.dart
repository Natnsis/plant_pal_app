import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/plantpal_api.dart';
import '../models/models.dart';
import '../theme/pp_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/pp_common.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _api = PlantPalApi.instance;
  String _filter = 'All entries';
  static const _filters = ['All entries', 'Watering', 'Photos', 'Milestones'];

  bool _match(JournalEntry e) => switch (_filter) {
        'Watering' => e.type == 'water',
        'Photos' => e.hasPhoto || e.imageUrl.isNotEmpty,
        'Milestones' => e.isMilestone,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AsyncView<List<JournalEntry>>(
        load: () => _api.journal(),
        padding: const EdgeInsets.only(top: 120),
        emptyWhen: (list) => list.isEmpty,
        emptyLabel: 'No journal entries yet',
        emptyIcon: LucideIcons.bookOpen,
        builder: (context, all, reload) {
          final entries = all.where(_match).toList();
          JournalEntry? milestone;
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
                const DisplayTitle('Growth diary'),
                const SizedBox(height: 8),
                Text('${all.length} entries',
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
                          color: _filter == _filters[i]
                              ? PP.ink
                              : Colors.white,
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
                if (milestone != null) ...[
                  const SizedBox(height: 18),
                  _milestoneCard(milestone),
                ],
                const SizedBox(height: 14),
                if (entries.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 22),
                    decoration: BoxDecoration(
                      color: PP.card.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text('No entries in this filter.',
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: PP.inkA(0.55))),
                  )
                else
                  for (final e in entries) ...[
                    _EntryCard(entry: e),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _milestoneCard(JournalEntry e) {
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
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: PP.bone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(LucideIcons.sprout,
                size: 56, color: PP.mint.withValues(alpha: 0.5)),
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
  const _EntryCard({required this.entry});
  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final (tagBg, tagFg) = switch (entry.type) {
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
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: entry.hasPhoto ? PP.plantImage : null,
              color: entry.hasPhoto ? null : PP.pale1,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              entry.hasPhoto ? LucideIcons.image : _iconFor(entry.type),
              size: entry.hasPhoto ? 26 : 22,
              color: PP.forest.withValues(alpha: entry.hasPhoto ? 0.5 : 1),
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
                      child: Text(entry.type.toUpperCase(),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.55,
                              color: tagFg)),
                    ),
                    const SizedBox(width: 8),
                    Text(_JournalScreenState._date(entry.date),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: PP.inkA(0.45))),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                    entry.plantName.isEmpty
                        ? 'Journal entry'
                        : entry.plantName,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: PP.track(14.5, -0.01))),
                if (entry.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(entry.note,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: PP.inkA(0.5))),
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
