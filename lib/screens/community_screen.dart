import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../api/plantpal_api.dart';
import '../models/models.dart';
import '../theme/pp_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/pp_common.dart';
import '../widgets/pp_sheets.dart';
import 'community_post_screen.dart';

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
  List<Plant> _myPlants = const [];

  @override
  void initState() {
    super.initState();
    _loadMyPlants();
  }

  Future<void> _loadMyPlants() async {
    try {
      final p = await _api.plants();
      if (mounted) setState(() => _myPlants = p);
    } catch (_) {}
  }

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
                        onTap: () => _compose(reload),
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
                  if (list.isEmpty)
                    _emptyState()
                  else
                    for (final p in list) ...[
                      _post(p, reload),
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

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
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
            child: const Icon(LucideIcons.users, size: 34, color: PP.forest),
          ),
          const SizedBox(height: 16),
          Text(
              _category == 'All'
                  ? 'No posts yet'
                  : 'Nothing in $_category yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: PP.track(18, -0.03))),
          const SizedBox(height: 6),
          Text(
            'Be the first — share a tip, a win, or a question with the community.',
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
  }

  Future<void> _compose(Future<void> Function() reload) async {
    final text = TextEditingController();
    var cat = _category == 'All' ? 'Tips' : _category;
    Plant? attached;
    final withPhoto = _myPlants.where((p) => p.photoUrl.isNotEmpty).toList();

    final posted = await showPPSheet<bool>(
      context,
      title: 'New post',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PPChoiceChips(
              options: const ['Tips', 'Showcase', 'Q&A', 'Local'],
              value: cat,
              onChanged: (v) => setSheet(() => cat = v),
            ),
            const SizedBox(height: 12),
            PPSheetField(
              controller: text,
              hint: 'Share something with the community…',
              minLines: 3,
              maxLines: 6,
              autofocus: true,
            ),
            if (withPhoto.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Attach a plant photo (optional)',
                  style: TextStyle(fontSize: 12.5, color: PP.inkA(0.5))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in withPhoto)
                    GestureDetector(
                      onTap: () => setSheet(() =>
                          attached = attached?.id == p.id ? null : p),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: attached?.id == p.id
                                ? PP.forest
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            PlantImage(
                                imageUrl: p.photoUrl,
                                width: 54,
                                height: 54,
                                radius: 13),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 56,
                              child: Text(p.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Post',
              background: PP.forest,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ),
    );
    if (posted != true || text.text.trim().isEmpty) return;
    try {
      await _api.createCommunityPost(
        category: cat,
        text: text.text.trim(),
        imageUrl: attached?.photoUrl ?? '',
      );
      setState(() => _posts = null);
      await reload();
      if (mounted) showPPSnack(context, 'Posted to the community');
    } on ApiException catch (e) {
      if (mounted) showPPSnack(context, e.message, error: true);
    }
  }

  Future<void> _shareLink(CommunityPost p) async {
    // A custom scheme so opening it launches the app straight to this post
    // (see main.dart / MainActivity.kt deep-link handling).
    final url = 'plantpal://post/${p.id}';
    await showPPSheet<void>(
      context,
      title: 'Share this post',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(url,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: PP.inkA(0.7))),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Copy link',
            background: PP.forest,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (mounted) showPPSnack(context, 'Link copied');
            },
          ),
        ],
      ),
    );
  }

  Widget _post(CommunityPost p, Future<void> Function() reload) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CommunityPostScreen(post: p)));
        if (mounted) {
          setState(() => _posts = null);
          reload();
        }
      },
      child: Container(
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
          if (p.imageUrl.isNotEmpty) ...[
            const SizedBox(height: 13),
            PlantImage(
                imageUrl: p.imageUrl,
                height: 170,
                width: double.infinity,
                radius: 24),
          ],
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
              GestureDetector(
                onTap: () => _shareLink(p),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                      color: PP.field, shape: BoxShape.circle),
                  child: Icon(LucideIcons.share,
                      size: 16, color: PP.inkA(0.55)),
                ),
              ),
            ],
          ),
        ],
      ),
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
