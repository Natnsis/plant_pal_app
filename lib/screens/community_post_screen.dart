import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../api/plantpal_api.dart';
import '../models/models.dart';
import '../theme/pp_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/pp_common.dart';

/// A single community post with its comment thread. Reached by tapping a post
/// in the feed, or via a `plantpal://post/<id>` deep link (pass [postId] and
/// it loads the post itself). Likes and comments here update the same backend
/// rows the feed reads, so the feed reflects them on return.
class CommunityPostScreen extends StatefulWidget {
  const CommunityPostScreen({super.key, this.post, this.postId})
      : assert(post != null || postId != null,
            'CommunityPostScreen needs a post or a postId');

  final CommunityPost? post;
  final int? postId;

  @override
  State<CommunityPostScreen> createState() => _CommunityPostScreenState();
}

class _CommunityPostScreenState extends State<CommunityPostScreen> {
  final _api = PlantPalApi.instance;
  final _draft = TextEditingController();
  CommunityPost? _post;
  bool _likeBusy = false;
  bool _sending = false;
  int _reloadKey = 0;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    if (_post == null) _loadPost();
  }

  Future<void> _loadPost() async {
    try {
      final p = await _api.communityPost(widget.postId!);
      if (mounted) setState(() => _post = p);
    } on ApiException catch (e) {
      if (mounted) {
        showPPSnack(context, e.message, error: true);
        Navigator.of(context).maybePop();
      }
    }
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final post = _post;
    if (_likeBusy || post == null) return;
    final wasLiked = post.likedByMe;
    setState(() {
      _likeBusy = true;
      post.likedByMe = !wasLiked;
      post.likes += wasLiked ? -1 : 1;
    });
    try {
      final updated =
          wasLiked ? await _api.unlikePost(post.id) : await _api.likePost(post.id);
      setState(() {
        post.likedByMe = updated.likedByMe;
        post.likes = updated.likes;
      });
    } on ApiException catch (e) {
      setState(() {
        post.likedByMe = wasLiked;
        post.likes += wasLiked ? 1 : -1;
      });
      if (mounted) showPPSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _likeBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_post == null) {
      return const Scaffold(
        backgroundColor: PP.bone,
        body: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
                strokeWidth: 2.4, color: PP.forest),
          ),
        ),
      );
    }
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
                      child: Text('Post',
                          style: TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),
            Expanded(
              child: AsyncView<List<CommunityComment>>(
                key: ValueKey(_reloadKey),
                load: () => _api.postComments(_post!.id),
                builder: (context, comments, reload) => RefreshIndicator(
                  color: PP.forest,
                  onRefresh: reload,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
                    children: [
                      _postCard(),
                      const SizedBox(height: 18),
                      Text('${comments.length} '
                          '${comments.length == 1 ? 'comment' : 'comments'}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: PP.inkA(0.5))),
                      const SizedBox(height: 12),
                      if (comments.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 22),
                          decoration: BoxDecoration(
                            color: PP.card.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text('No comments yet — start the conversation.',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: PP.inkA(0.55))),
                        )
                      else
                        for (final c in comments) ...[
                          _commentRow(c),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ),
                ),
              ),
            ),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _postCard() {
    final p = _post!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(
                  p.authorInitials.isEmpty ? '··' : p.authorInitials,
                  size: 40,
                  radius: 15,
                  fontSize: 13),
              const SizedBox(width: 11),
              Expanded(
                child: Text(p.authorName,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600)),
              ),
              Tag(p.category,
                  background: PP.pale2,
                  foreground: PP.forest,
                  uppercase: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6)),
            ],
          ),
          const SizedBox(height: 14),
          Text(p.text,
              style: const TextStyle(
                  fontSize: 14.5, height: 1.6, fontWeight: FontWeight.w500)),
          if (p.imageUrl.isNotEmpty) ...[
            const SizedBox(height: 14),
            PlantImage(
                imageUrl: p.imageUrl,
                height: 190,
                width: double.infinity,
                radius: 22),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              GestureDetector(
                onTap: _likeBusy ? null : _toggleLike,
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
                          color: p.likedByMe ? PP.forest : PP.inkA(0.6)),
                      const SizedBox(width: 8),
                      Text('${p.likes}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: p.likedByMe ? PP.forest : PP.inkA(0.6))),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _commentRow(CommunityComment c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InitialsAvatar(
              c.authorInitials.isEmpty ? '··' : c.authorInitials,
              size: 34,
              radius: 12,
              fontSize: 12),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.authorName,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(c.text,
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _composer() {
    // Scaffold(resizeToAvoidBottomInset: true) already lifts this above the
    // keyboard — don't add viewInsets again or it double-pads and overflows.
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 100),
                child: TextField(
                  controller: _draft,
                  minLines: 1,
                  maxLines: 4,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: InputBorder.none,
                    hintText: 'Add a comment…',
                    hintStyle: TextStyle(
                        color: PP.inkA(0.4), fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : () => _sendComment(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: _sending ? PP.inkA(0.35) : PP.ink,
                    shape: BoxShape.circle),
                child: const Icon(LucideIcons.arrowUp, size: 18, color: PP.lime),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendComment() async {
    final text = _draft.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _api.createComment(_post!.id, text);
      _draft.clear();
      if (mounted) {
        setState(() {
          _post!.comments++;
          _reloadKey++; // rebuilds AsyncView -> reloads thread
        });
        showPPSnack(context, 'Comment added');
      }
    } on ApiException catch (e) {
      if (mounted) showPPSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
