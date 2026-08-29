import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// =============================================================================
// LikeAction — shared like/unlike logic with debounce
// =============================================================================

class LikeAction {
  static Future<void> toggle(CommunityPost post, {
    required ValueChanged<CommunityPost> onDone,
    required VoidCallback onRevert,
    required VoidCallback onNotFound,
  }) async {
    try {
      final body = post.likedByMe
          ? await AuthService.unlikePost(post.id)
          : await AuthService.likePost(post.id);
      onDone(CommunityPost.fromJson(body));
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        onNotFound();
      } else {
        onRevert();
      }
    } catch (_) {
      onRevert();
    }
  }
}

// =============================================================================
// SCREEN 29: COMMUNITY FEED
// =============================================================================

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final ScrollController _scrollCtrl = ScrollController();

  List<CommunityPost> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  String _category = 'all';
  int _offset = 0;
  static const _limit = 20;

  static const _categories = ['all', 'tips', 'showcase', 'qa', 'local'];
  static const _categoryLabels = {'all': 'All', 'tips': 'Tips 💡', 'showcase': 'Showcase 🌟', 'qa': 'Q&A ❓', 'local': 'Local 📍'};

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() { _scrollCtrl.dispose(); super.dispose(); }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 && !_isLoadingMore && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadPosts() async {
    setState(() { _isLoading = true; _error = null; _offset = 0; _hasMore = true; });
    try {
      final data = await AuthService.getCommunityPosts(category: _category, offset: 0, limit: _limit);
      if (!mounted) return;
      setState(() {
        _posts = data.map((j) => CommunityPost.fromJson(j)).toList();
        _isLoading = false;
        _hasMore = data.length >= _limit;
      });
    } catch (e) {
      if (mounted) setState(() { _error = "Couldn't load the community feed"; _isLoading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      _offset += _limit;
      final data = await AuthService.getCommunityPosts(category: _category, offset: _offset, limit: _limit);
      if (!mounted) return;
      setState(() {
        _posts.addAll(data.map((j) => CommunityPost.fromJson(j)));
        _hasMore = data.length >= _limit;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _setCategory(String cat) {
    if (_category == cat) return;
    setState(() => _category = cat);
    _loadPosts();
  }

  Future<void> _toggleLike(CommunityPost post) async {
    // Optimistic update
    final idx = _posts.indexWhere((p) => p.id == post.id);
    if (idx == -1) return;

    final updated = CommunityPost(
      id: post.id, authorName: post.authorName, authorInitials: post.authorInitials,
      category: post.category, text: post.text, emoji: post.emoji, time: post.time,
      likes: post.likedByMe ? post.likes - 1 : post.likes + 1,
      comments: post.comments, likedByMe: !post.likedByMe,
    );
    setState(() => _posts[idx] = updated);

    await LikeAction.toggle(post,
      onDone: (serverPost) { if (mounted) setState(() => _posts[idx] = serverPost); },
      onRevert: () { if (mounted) setState(() => _posts[idx] = post); },
      onNotFound: () { if (mounted) setState(() => _posts.removeAt(idx)); },
    );
  }

  void _showNewPostSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _NewPostSheet(onPosted: (post) {
        setState(() => _posts.insert(0, post));
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageBase,
      body: SafeArea(
        child: Column(children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(children: [
              const Expanded(child: Text('Community',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.cream))),
              GestureDetector(
                onTap: _showNewPostSheet,
                child: Container(width: 40, height: 40,
                    decoration: const BoxDecoration(color: AppColors.cream, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.plus, color: AppColors.accentDark, size: 22)),
              ),
            ]),
          ),

          // Category tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: _categories.map((c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CategoryPill(
                label: _categoryLabels[c] ?? c,
                isActive: _category == c,
                onTap: () => _setCategory(c),
              ),
            )).toList()),
          ),

          const SizedBox(height: 12),

          // Feed
          Expanded(child: _buildContent()),
        ]),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return _buildSkeleton();
    if (_error != null) return _buildError();
    if (_posts.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _posts.length + (_isLoadingMore ? 1 : 0) + (_hasMore ? 0 : 1),
        itemBuilder: (_, i) {
          if (i == _posts.length && _isLoadingMore) {
            return const Padding(padding: EdgeInsets.all(16),
                child: Center(child: SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cream))));
          }
          if (i >= _posts.length) {
            return Padding(padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text("You're all caught up 🌿",
                    style: TextStyle(fontSize: 13, color: AppColors.cream.withValues(alpha: 0.5)))));
          }
          return _PostCard(
            post: _posts[i],
            onLike: () => _toggleLike(_posts[i]),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 4,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.15), shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Container(width: 100, height: 14, decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4))),
          ]),
          const SizedBox(height: 12),
          Container(width: double.infinity, height: 14, decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 6),
          Container(width: 200, height: 14, decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 12),
          Row(children: [
            Container(width: 20, height: 20, decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.1), shape: BoxShape.circle)),
            const SizedBox(width: 40),
            Container(width: 20, height: 20, decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.1), shape: BoxShape.circle)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_error!, style: const TextStyle(color: AppColors.cream)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _loadPosts, style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel, shape: const StadiumBorder()),
          child: const Text('Retry')),
    ]));
  }

  Widget _buildEmpty() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('💬', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('No posts yet in ${_categoryLabels[_category] ?? _category}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.cream)),
        const SizedBox(height: 8),
        Text('Be the first to share something!',
            style: TextStyle(fontSize: 14, color: AppColors.cream.withValues(alpha: 0.6))),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _showNewPostSheet,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel, shape: const StadiumBorder()),
            child: const Text('New Post')),
      ]),
    ));
  }
}

// =============================================================================
// Post Card
// =============================================================================

class _PostCard extends StatefulWidget {
  const _PostCard({required this.post, required this.onLike});
  final CommunityPost post;
  final VoidCallback onLike;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimCtrl;
  bool _expanded = false;
  bool _isLikeDebounced = false;

  @override
  void initState() {
    super.initState();
    _likeAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200), lowerBound: 0.8, upperBound: 1.2);
  }

  @override
  void dispose() { _likeAnimCtrl.dispose(); super.dispose(); }

  void _onLikeTap() {
    if (_isLikeDebounced) return;
    _isLikeDebounced = true;
    Future.delayed(const Duration(milliseconds: 400), () => _isLikeDebounced = false);
    _likeAnimCtrl.forward(from: 0.8).then((_) => _likeAnimCtrl.reverse());
    widget.onLike();
  }

  Color get _categoryColor {
    switch (widget.post.category) {
      case 'tips': return const Color(0xFF4CAF64);
      case 'showcase': return const Color(0xFFFFA726);
      case 'qa': return const Color(0xFF42A5F5);
      case 'local': return const Color(0xFFAB47BC);
      default: return AppColors.textPrimary.withValues(alpha: 0.3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final needsTruncation = post.text.length > 200;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Author row
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.sageBase.withValues(alpha: 0.3), shape: BoxShape.circle),
            child: Center(child: Text(post.authorInitials,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentDark))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.authorName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text(post.time, style: TextStyle(fontSize: 11, color: AppColors.textPrimary.withValues(alpha: 0.4))),
            ],
          )),
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _categoryColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
            child: Text(post.category.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _categoryColor)),
          ),
        ]),

        // Emoji + text
        if (post.emoji != null && post.emoji!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(post.emoji!, style: const TextStyle(fontSize: 32)),
        ],
        const SizedBox(height: 8),
        Text(
          post.text,
          maxLines: _expanded ? null : 5,
          overflow: _expanded ? null : TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
        ),
        if (needsTruncation && !_expanded)
          GestureDetector(
            onTap: () => setState(() => _expanded = true),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Read more', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _categoryColor)),
            ),
          ),

        const SizedBox(height: 12),

        // Action row
        Row(children: [
          // Like
          GestureDetector(
            onTap: _onLikeTap,
            child: ScaleTransition(
              scale: _likeAnimCtrl,
              child: Row(children: [
                Icon(
                  post.likedByMe ? LucideIcons.heart : LucideIcons.heart,
                  size: 20,
                  color: post.likedByMe ? const Color(0xFFE91E63) : AppColors.textPrimary.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 4),
                Text('${post.likes}', style: TextStyle(fontSize: 13, color: AppColors.textPrimary.withValues(alpha: 0.5))),
              ]),
            ),
          ),
          const SizedBox(width: 20),
          // Comments — ⚠️ display only, not interactive (no comments endpoint)
          Row(children: [
            Icon(LucideIcons.messageCircle, size: 18, color: AppColors.textPrimary.withValues(alpha: 0.3)),
            const SizedBox(width: 4),
            Text('${post.comments}', style: TextStyle(fontSize: 13, color: AppColors.textPrimary.withValues(alpha: 0.3))),
          ]),
        ]),
      ]),
    );
  }
}

// =============================================================================
// Category pill
// =============================================================================

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentDark : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: isActive ? null : Border.all(color: AppColors.cream.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
            color: isActive ? AppColors.cream : AppColors.cream.withValues(alpha: 0.7))),
      ),
    );
  }
}

// =============================================================================
// SCREEN 30: NEW COMMUNITY POST
// =============================================================================

class _NewPostSheet extends StatefulWidget {
  const _NewPostSheet({required this.onPosted});
  final ValueChanged<CommunityPost> onPosted;

  @override
  State<_NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends State<_NewPostSheet> {
  String _category = 'tips';
  String? _emoji;
  final _textCtrl = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  static const _categories = ['tips', 'showcase', 'qa', 'local'];
  static const _categoryEmoji = {'tips': '💡', 'showcase': '🌟', 'qa': '❓', 'local': '📍'};
  static const _presetEmojis = ['🌱', '🌿', '🪴', '🌸', '🍃', '💧'];

  static const _placeholders = {
    'tips': 'Share a care tip...',
    'showcase': 'Tell us about your plant...',
    'qa': 'What do you want to ask?',
    'local': "What's happening near you?",
  };

  @override
  void dispose() { _textCtrl.dispose(); super.dispose(); }

  Future<void> _onPost() async {
    if (_textCtrl.text.trim().length < 3) return;
    setState(() { _isSubmitting = true; _error = null; });
    try {
      final body = await AuthService.createCommunityPost(
        category: _category,
        text: _textCtrl.text.trim(),
        emoji: _emoji,
      );
      if (!mounted) return;
      widget.onPosted(CommunityPost.fromJson(body));
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Posted!')));
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _isSubmitting = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Something went wrong. Please try again.'; _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.textPrimary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)))),
          const SizedBox(height: 16),
          Row(children: [
            const Expanded(child: Text('New Post', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(LucideIcons.x, size: 22),
            ),
          ]),

          const SizedBox(height: 20),

          if (_error != null) ...[
            Container(width: double.infinity, padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 13))),
            const SizedBox(height: 16),
          ],

          // Category
          _Label('Category'),
          Wrap(spacing: 8, runSpacing: 8, children: _categories.map((c) =>
            GestureDetector(onTap: () => setState(() => _category = c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _category == c ? AppColors.accentDark : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: _category == c ? null : Border.all(color: AppColors.textPrimary.withValues(alpha: 0.1)),
                ),
                child: Text('${_categoryEmoji[c]} $c', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                    color: _category == c ? AppColors.cream : AppColors.textPrimary)),
              ))).toList()),

          const SizedBox(height: 16),

          // Emoji
          _Label('Emoji (optional)'),
          Wrap(spacing: 8, children: _presetEmojis.map((e) =>
            GestureDetector(onTap: () => setState(() => _emoji = _emoji == e ? null : e),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _emoji == e ? AppColors.accentGreen.withValues(alpha: 0.15) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _emoji == e ? AppColors.accentGreen : AppColors.textPrimary.withValues(alpha: 0.1)),
                ),
                child: Center(child: Text(e, style: const TextStyle(fontSize: 20))),
              ))).toList()),

          const SizedBox(height: 16),

          // Text
          _Label('Text'),
          TextField(
            controller: _textCtrl,
            maxLines: 5,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: _placeholders[_category] ?? 'What\'s on your mind?',
              hintStyle: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.3)),
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 20),

          // Preview
          if (_textCtrl.text.trim().isNotEmpty) ...[
            Text('Preview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary.withValues(alpha: 0.4))),
            const SizedBox(height: 8),
            _PostCard(
              post: CommunityPost(
                id: 0, authorName: 'You', authorInitials: 'Y', category: _category,
                text: _textCtrl.text, emoji: _emoji, time: 'Just now',
                likes: 0, comments: 0, likedByMe: false,
              ),
              onLike: () {},
            ),
            const SizedBox(height: 12),
          ],

          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting || _textCtrl.text.trim().length < 3 ? null : _onPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel,
                disabledBackgroundColor: AppColors.buttonBg.withValues(alpha: 0.4),
                shape: const StadiumBorder(),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Post', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)));
  }
}
