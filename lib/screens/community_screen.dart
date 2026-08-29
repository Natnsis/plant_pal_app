import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../api/plantpal_api.dart';
import '../models/models.dart';
import '../theme/pp_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/pp_common.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _api = PlantPalApi.instance;
  final _busy = <int>{};
  String _category = 'All';
  static const _categories = ['All', 'Tips', 'Showcase', 'Q&A', 'Local'];

  // Loaded list, mutated in place for optimistic like toggles.
  List<CommunityPost>? _posts;

  Future<List<CommunityPost>> _load() async {
    final posts = await _api.communityPosts(category: _category);
    _posts = posts;
    return posts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PP.bone,
      body: SafeArea(
        child: AsyncView<List<CommunityPost>>(
          key: ValueKey(_category),
          load: _load,
          emptyWhen: (l) => l.isEmpty,
          emptyLabel: 'No posts here yet',
          emptyIcon: LucideIcons.users,
          builder: (context, posts, reload) {
            final list = _posts ?? posts;
            return RefreshIndicator(
              color: PP.forest,
              onRefresh: reload,
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
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 9),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => setState(() {
                          _category = _categories[i];
                          _posts = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                          decoration: BoxDecoration(
                            color: _category == _categories[i]
                                ? PP.ink
                                : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(_categories[i],
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _category == _categories[i]
                                      ? PP.bone
                                      : PP.inkA(0.6))),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final p in list) ...[
                    _post(p),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _post(CommunityPost p) {
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
              InitialsAvatar(
                  p.authorInitials.isEmpty ? '··' : p.authorInitials,
                  size: 38,
                  radius: 14,
                  fontSize: 13),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.authorName,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: PP.track(14, -0.01))),
                    Text(_relTime(p.time),
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
          PlantImage(
              height: 150, width: double.infinity, radius: 24, iconSize: 56),
          const SizedBox(height: 13),
          Row(
            children: [
              GestureDetector(
                onTap: _busy.contains(p.id) ? null : () => _toggleLike(p),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: p.likedByMe ? PP.pale2 : PP.field,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        p.likedByMe
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 16,
                        color: p.likedByMe ? PP.forest : PP.inkA(0.6),
                      ),
                      const SizedBox(width: 8),
                      Text('${p.likes}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  p.likedByMe ? PP.forest : PP.inkA(0.6))),
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
                decoration:
                    const BoxDecoration(color: PP.field, shape: BoxShape.circle),
                child: Icon(LucideIcons.share, size: 16, color: PP.inkA(0.55)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(CommunityPost p) async {
    final wasLiked = p.likedByMe;
    setState(() {
      _busy.add(p.id);
      p.likedByMe = !wasLiked;
      p.likes += wasLiked ? -1 : 1;
    });
    try {
      final updated =
          wasLiked ? await _api.unlikePost(p.id) : await _api.likePost(p.id);
      setState(() {
        p.likedByMe = updated.likedByMe;
        p.likes = updated.likes;
      });
    } on ApiException catch (e) {
      setState(() {
        p.likedByMe = wasLiked;
        p.likes += wasLiked ? 1 : -1;
      });
      if (mounted) showPPSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(p.id));
    }
  }

  static String _relTime(String iso) {
    final t = DateTime.tryParse(iso);
    if (t == null) return iso;
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    return '${(d.inDays / 7).floor()}w';
  }
}
