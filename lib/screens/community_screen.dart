import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/demo.dart';
import '../theme/pp_theme.dart';
import '../widgets/pp_common.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final Set<String> _liked = {};
  static const _filters = ['All', 'Tips', 'Showcase', 'Q&A', 'Local'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PP.bone,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
          children: [
            Row(
              children: [
                const Expanded(child: DisplayTitle('Community')),
                SquircleIconButton(
                  icon: LucideIcons.plus,
                  background: PP.ink,
                  foreground: PP.bone,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                children: [
                  for (var i = 0; i < _filters.length; i++) ...[
                    if (i != 0) const SizedBox(width: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(
                        color: i == 0 ? PP.ink : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(_filters[i],
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: i == 0 ? PP.bone : PP.inkA(0.6))),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            for (final p in demoPosts) ...[
              _post(p),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _post(CommunityPost p) {
    final liked = _liked.contains(p.id);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(p.initials, size: 38, radius: 14, fontSize: 13),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.author,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: PP.track(14, -0.01))),
                    Text(p.meta,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: PP.inkA(0.45))),
                  ],
                ),
              ),
              Tag(p.category,
                  background: PP.pale2,
                  foreground: PP.forest,
                  uppercase: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6)),
            ],
          ),
          const SizedBox(height: 13),
          Text(p.text,
              style: const TextStyle(
                  fontSize: 14, height: 1.55, fontWeight: FontWeight.w500)),
          const SizedBox(height: 13),
          PlantImage(height: 150, width: double.infinity, radius: 24, iconSize: 56),
          const SizedBox(height: 13),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  liked ? _liked.remove(p.id) : _liked.add(p.id);
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: liked ? PP.pale2 : PP.field,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: liked ? PP.forest : PP.inkA(0.6),
                      ),
                      const SizedBox(width: 8),
                      Text('${p.likes + (liked ? 1 : 0)}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: liked ? PP.forest : PP.inkA(0.6))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: PP.field,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.messageCircle,
                        size: 16, color: PP.inkA(0.6)),
                    const SizedBox(width: 8),
                    Text('${p.comments}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: PP.inkA(0.6))),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                    color: PP.field, shape: BoxShape.circle),
                child: Icon(LucideIcons.share,
                    size: 16, color: PP.inkA(0.55)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
