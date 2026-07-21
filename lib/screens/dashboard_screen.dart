import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../data/api_client.dart';
import '../data/comment_store.dart';
import '../data/feed_store.dart';
import '../data/repository.dart';
import '../data/saved_store.dart';
import '../data/story_store.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/pexels_image.dart';
import 'comments_sheet.dart';
import 'full_screen_reel.dart';
import 'share_sheet.dart';
import 'story_compose_screen.dart';
import 'story_viewer_screen.dart';

/// Dashboard — an Instagram-style Samaj feed: stories, reels, and posts.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: 'Samaj Feed',
      currentRoute: '/dashboard',
      padding: EdgeInsets.zero,
      child: _Feed(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feed content
// ─────────────────────────────────────────────────────────────────────────────

class _Feed extends StatefulWidget {
  const _Feed();

  @override
  State<_Feed> createState() => _FeedState();
}

class _FeedState extends State<_Feed> {
  List<_Post> _backendPosts = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  /// Pulls the real feed from the backend. On failure/empty we fall back to the
  /// embedded demo posts so the screen is never blank (the app's usual pattern).
  Future<void> _loadFeed() async {
    try {
      final data = await Repository.instance.feed(limit: 20);
      final raw = (data['posts'] as List?) ?? const [];
      final posts = raw
          .whereType<Map>()
          .map((m) => _Post.fromBackend(Map<String, dynamic>.from(m)))
          .toList();
      if (!mounted) return;
      setState(() {
        _backendPosts = posts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false); // leave feed empty on error, no fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FeedStore.instance,
      builder: (context, _) {
        // Locally-uploaded posts (this session) sit on top of the real backend
        // feed. No demo/seed content — an empty backend shows an empty feed.
        final userPosts =
            FeedStore.instance.posts.map(_Post.fromUser).toList();
        // A post uploaded this session also comes back in the backend feed on
        // the next refresh — keep the local card (it renders from the local
        // file, so no re-download) and drop the duplicate.
        final uploaded = FeedStore.instance.remoteIds;
        final all = <_Post>[
          ...userPosts,
          ..._backendPosts.where((p) => !uploaded.contains(p.id)),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            // Stories rail (Instagram-style) pinned to the top of the feed.
            const _StoriesShelf(),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.forest700, strokeWidth: 2)),
              )
            else if (all.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                child: Column(
                  children: [
                    const Icon(Icons.photo_library_outlined,
                        size: 44, color: AppColors.hint),
                    const SizedBox(height: 12),
                    Text('No posts yet',
                        style: display(16, color: AppColors.forest900)),
                    const SizedBox(height: 4),
                    Text('Be the first to share something with the Samaj.',
                        textAlign: TextAlign.center,
                        style: body(13, color: AppColors.textMuted)),
                  ],
                ),
              ),
            // Interleave posts with a reels shelf after the second post.
            for (var i = 0; i < all.length; i++) ...[
              _PostCard(post: all[i]),
              if (i == 1) const _ReelsShelf(),
            ],
            const SizedBox(height: 24),
            Center(
              child: Text('You\'re all caught up ✦',
                  style: body(12, color: AppColors.hint)),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stories
// ─────────────────────────────────────────────────────────────────────────────

/// Horizontal "Family Updates" stories rail, backed by `/api/stories`. Loads on
/// mount and rebuilds as you post, view, or delete.
class _StoriesShelf extends StatefulWidget {
  const _StoriesShelf();

  @override
  State<_StoriesShelf> createState() => _StoriesShelfState();
}

class _StoriesShelfState extends State<_StoriesShelf> {
  @override
  void initState() {
    super.initState();
    // Load after first frame so it doesn't block the initial feed paint.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StoryStore.instance.refresh();
    });
  }

  static const _videoExts = {
    'mp4', 'mov', 'mkv', 'webm', '3gp', 'avi', 'm4v', 'flv', 'wmv',
  };

  /// Pick an image/video, then open the "Share Story" composer to post it.
  Future<void> _pickAndPostStory() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    String? picked;
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.media);
      picked = result?.files.single.path;
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not pick media: $e')));
      return;
    }
    if (picked == null) return; // cancelled
    final path = picked;
    final isVideo = _videoExts.contains(path.split('.').last.toLowerCase());
    navigator.push(MaterialPageRoute(
      builder: (_) => StoryComposeScreen(filePath: path, isVideo: isVideo),
    ));
  }

  void _openMyStories() {
    final mine = StoryStore.instance.mine;
    if (mine.isEmpty) {
      _pickAndPostStory();
      return;
    }
    final slides = [
      for (final s in mine)
        StorySlide(
          author: 'Your Story',
          createdAt: s.createdAt,
          mediaUrl: s.mediaUrl,
          isVideo: s.isVideo,
          caption: s.caption,
          isMine: true,
          storyId: s.id,
          viewCount: s.viewCount,
          onDeleted: () => StoryStore.instance.refresh(),
        ),
    ];
    _openViewer(slides);
  }

  void _openTray(StoryTray tray) {
    final slides = [
      for (final s in tray.stories)
        StorySlide(
          author: tray.author.userName,
          createdAt: s.createdAt,
          mediaUrl: s.mediaUrl,
          isVideo: s.isVideo,
          caption: s.caption,
          storyId: s.id,
          onShown: () => StoryStore.instance.markViewed(s.id),
        ),
    ];
    _openViewer(slides);
  }

  void _openViewer(List<StorySlide> slides) {
    if (slides.isEmpty) return;
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => StoryViewerScreen(slides: slides),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StoryStore.instance,
      builder: (context, _) {
        final trays = StoryStore.instance.otherTrays;
        return Container(
          color: AppColors.cream,
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Text('FAMILY UPDATES',
                    style: body(12,
                        weight: FontWeight.w700,
                        color: AppColors.gold700,
                        letterSpacing: 1.4)),
              ),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: trays.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return _YourStory(
                        hasStory: StoryStore.instance.hasActiveStory,
                        onTap: _openMyStories,
                        onAdd: _pickAndPostStory,
                      );
                    }
                    final tray = trays[i - 1];
                    return _TrayCircle(
                      tray: tray,
                      viewed: StoryStore.instance.trayViewed(tray),
                      onTap: () => _openTray(tray),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The leading "Your Story" tile. With no active story it's a dashed ring +
/// button; once you've posted, it becomes your avatar in a ring with a small
/// + badge to add another.
class _YourStory extends StatelessWidget {
  const _YourStory({
    required this.hasStory,
    required this.onTap,
    required this.onAdd,
  });
  final bool hasStory;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    if (!hasStory) {
      return _StoryTile(
        label: 'Your Story',
        onTap: onTap,
        avatar: CustomPaint(
          painter: const _DashedCirclePainter(color: AppColors.forest600),
          child: const SizedBox(
            width: 64,
            height: 64,
            child: Icon(Icons.add_rounded, color: AppColors.forest700, size: 28),
          ),
        ),
      );
    }
    final name = context.watch<AuthService>().user?.name ?? 'You';
    return _StoryTile(
      label: 'Your Story',
      onTap: onTap,
      avatar: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _ring(child: PexelsImage(url: '', name: name, size: 56)),
            // Add-another badge
            Positioned(
              right: -2,
              bottom: -2,
              child: GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.forest700,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cream, width: 2),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One author's story tray: a ring (gold→forest when unseen, grey once viewed)
/// around their initials avatar.
class _TrayCircle extends StatelessWidget {
  const _TrayCircle({
    required this.tray,
    required this.viewed,
    required this.onTap,
  });
  final StoryTray tray;
  final bool viewed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = tray.author.userName;
    return _StoryTile(
      label: name,
      onTap: onTap,
      avatar: _ring(
        viewed: viewed,
        child: PexelsImage(url: '', name: name, size: 56),
      ),
    );
  }
}

/// A story avatar ring: gradient (unseen) or grey (viewed), with a cream gap.
Widget _ring({required Widget child, bool viewed = false}) {
  return Container(
    width: 64,
    height: 64,
    padding: const EdgeInsets.all(2.5),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: viewed
          ? null
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.gold500, AppColors.forest600],
            ),
      color: viewed ? AppColors.border : null,
    ),
    child: Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cream,
      ),
      child: ClipOval(child: child),
    ),
  );
}

/// Shared layout for a story item: avatar above a single-line label.
class _StoryTile extends StatelessWidget {
  const _StoryTile(
      {required this.label, required this.avatar, required this.onTap});
  final String label;
  final Widget avatar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 66,
        child: Column(
          children: [
            avatar,
            const SizedBox(height: 6),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: body(11, color: AppColors.label)),
          ],
        ),
      ),
    );
  }
}

/// Paints a dashed circle outline (for the "add your story" tile).
class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final radius = size.width / 2 - paint.strokeWidth;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    const dashes = 26;
    final step = 2 * math.pi / dashes;
    final sweep = step * 0.62; // gap between dashes
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * step, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Reels
// ─────────────────────────────────────────────────────────────────────────────

class _Reel {
  const _Reel(this.title, this.emoji, this.views, this.gradient);
  final String title;
  final String emoji;
  final String views;
  final List<Color> gradient;
}

const _reels = <_Reel>[
  _Reel('Samaj Utsava 2025', '🪔', '12.4K', [Color(0xFF92400E), Color(0xFFD97706)]),
  _Reel('Chickpete Goldsmiths', '💛', '8.1K', [AppColors.gold700, AppColors.gold500]),
  _Reel('Kumta Temple Yatra', '🛕', '5.9K', [AppColors.forest800, AppColors.forest600]),
  _Reel('Bhajan Sandhya', '🎶', '3.2K', [Color(0xFF3B4C8A), Color(0xFF1B4332)]),
];

class _ReelsShelf extends StatelessWidget {
  const _ReelsShelf();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cream,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.movie_creation_outlined,
                    size: 18, color: AppColors.forest800),
                const SizedBox(width: 8),
                Text('Reels', style: display(16, color: AppColors.forest900)),
                const Spacer(),
                Text('See all',
                    style: body(12,
                        weight: FontWeight.w600, color: AppColors.forest700)),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _reels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _ReelCard(reel: _reels[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelCard extends StatelessWidget {
  const _ReelCard({required this.reel});
  final _Reel reel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSnack(context, 'Playing "${reel.title}"'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 140,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: reel.gradient,
                  ),
                ),
              ),
              Center(
                  child:
                      Text(reel.emoji, style: const TextStyle(fontSize: 52))),
              // Play glyph
              Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 26),
                ),
              ),
              // Gradient scrim + caption
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reel.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: body(12,
                              weight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.play_arrow_rounded,
                              size: 13, color: Colors.white70),
                          const SizedBox(width: 2),
                          Text('${reel.views} plays',
                              style: body(10, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Posts
// ─────────────────────────────────────────────────────────────────────────────

class _Post {
  const _Post({
    required this.id,
    required this.author,
    required this.subtitle,
    required this.emoji,
    required this.gradient,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.time,
    this.mediaPath,
    this.mediaUrl,
    this.isReel = false,
    this.pending,
  });

  final String id;
  final String author;
  final String subtitle;
  final String emoji;
  final List<Color> gradient;
  final String caption;
  final int likes;
  final int comments;
  final String time;
  final String? mediaPath; // local upload file; null → use mediaUrl / placeholder
  final String? mediaUrl; // remote (Cloudinary) media from the backend feed
  final bool isReel; // true → the media is a video

  /// Set while this card is a local upload that hasn't landed on the server
  /// yet (or failed) — drives the "Uploading… / Retry" overlay.
  final UserPost? pending;

  /// Builds a feed card from a user-created upload. The id is the server's
  /// once the upload lands, so likes and comments hit the real post.
  factory _Post.fromUser(UserPost p) => _Post(
        id: p.feedId,
        pending: (p.uploading || p.failed) ? p : null,
        author: p.author,
        subtitle: p.subtitle,
        emoji: p.isReel ? '🎬' : '🖼️',
        gradient: const [AppColors.forest800, AppColors.forest600],
        caption: p.caption,
        likes: 0,
        comments: 0,
        time: 'Just now',
        mediaPath: p.mediaPath,
        isReel: p.isReel,
      );

  /// Builds a feed card from a backend `/feed` post (Cloudinary-hosted media).
  factory _Post.fromBackend(Map<String, dynamic> m) {
    final urls = m['mediaUrls'];
    final mediaUrl = (urls is List && urls.isNotEmpty) ? urls.first.toString() : null;
    final isVideo = (m['postType'] ?? '').toString() == 'video';
    final userField = m['userId'];
    final author = (m['userName'] ??
            (userField is Map ? userField['userName'] : null) ??
            'Samaj Member')
        .toString();
    return _Post(
      id: (m['_id'] ?? '').toString(),
      author: author,
      subtitle: 'Samaj Member',
      emoji: isVideo ? '🎬' : '🖼️',
      gradient: const [AppColors.forest800, AppColors.forest600],
      caption: (m['caption'] ?? '').toString(),
      likes: (m['likeCount'] as num?)?.toInt() ?? 0,
      comments: (m['commentCount'] as num?)?.toInt() ?? 0,
      time: _timeAgo(m['createdAt']?.toString()),
      mediaUrl: mediaUrl,
      isReel: isVideo,
    );
  }

  /// The bookmarkable form of this post/reel for the app-wide [SavedStore].
  SavedItem toSavedItem() => SavedItem(
        id: id,
        author: author,
        caption: caption,
        mediaPath: mediaPath,
        mediaUrl: mediaUrl,
        isReel: isReel,
        emoji: emoji,
        gradient: gradient,
      );
}

/// "3h", "2d", "Just now" — a compact relative time from an ISO-8601 string.
String _timeAgo(String? iso) {
  if (iso == null || iso.isEmpty) return 'Recently';
  final t = DateTime.tryParse(iso);
  if (t == null) return 'Recently';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${(d.inDays / 7).floor()}w ago';
}

class _PostCard extends StatefulWidget {
  const _PostCard({required this.post});
  final _Post post;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _liked = false;
  bool _burst = false;
  Timer? _burstTimer;
  int? _serverLikeCount; // set once the API confirms a like/unlike

  @override
  void dispose() {
    _burstTimer?.cancel();
    super.dispose();
  }

  int get _likeCount => _serverLikeCount ?? (widget.post.likes + (_liked ? 1 : 0));

  /// POST /api/posts/:postId/likes — the endpoint toggles, so one call covers
  /// both like and unlike. The heart flips immediately and reverts if the
  /// request fails.
  Future<void> _toggleLike() async {
    final wasLiked = _liked;
    setState(() => _liked = !wasLiked);
    if (!isBackendPostId(widget.post.id)) return; // local/demo post

    try {
      final res = await Repository.instance.likePost(widget.post.id);
      if (!mounted) return;
      setState(() {
        _liked = res['liked'] == true;
        _serverLikeCount = (res['likeCount'] as num?)?.toInt();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _liked = wasLiked);
      _showSnack(context, e is ApiException ? e.message : 'Could not update like');
    }
  }

  void _doubleTapLike() {
    _burstTimer?.cancel();
    setState(() => _burst = true);
    _burstTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _burst = false);
    });
    // Double-tap always means "like", never unlike.
    if (!_liked) _toggleLike();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    return Container(
      color: AppColors.cream,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.gold500, AppColors.forest600],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: AppColors.cream),
                    child: _Avatar(name: p.author, size: 36),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: body(13,
                              weight: FontWeight.w700,
                              color: AppColors.forest900)),
                      Text(p.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: body(11, color: AppColors.hint)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded,
                      color: AppColors.label),
                  onPressed: () => _showSnack(context, 'Post options'),
                ),
              ],
            ),
          ),
          // Media. Reels handle their own tap (→ full screen), so we don't
          // attach double-tap-to-like on them to avoid a gesture conflict.
          GestureDetector(
            onDoubleTap: p.isReel ? null : _doubleTapLike,
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (p.mediaUrl != null && p.isReel)
                    _VideoTile(
                        url: p.mediaUrl!,
                        author: p.author,
                        caption: p.caption,
                        saved: p.toSavedItem())
                  else if (p.mediaUrl != null)
                    Image.network(p.mediaUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) =>
                            progress == null
                                ? child
                                : const ColoredBox(
                                    color: AppColors.forest900,
                                    child: Center(
                                        child: CircularProgressIndicator(
                                            color: Colors.white54,
                                            strokeWidth: 2))),
                        errorBuilder: (_, __, ___) => const ColoredBox(
                            color: AppColors.forest900,
                            child: Icon(Icons.broken_image_outlined,
                                color: Colors.white54, size: 48)))
                  else if (p.mediaPath != null && p.isReel)
                    _VideoTile(
                        path: p.mediaPath!,
                        author: p.author,
                        caption: p.caption,
                        saved: p.toSavedItem())
                  else if (p.mediaPath != null)
                    Image.file(File(p.mediaPath!), fit: BoxFit.cover)
                  else ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: p.gradient,
                        ),
                      ),
                    ),
                    Center(
                        child: Text(p.emoji,
                            style: const TextStyle(fontSize: 96))),
                  ],
                  // Reel badge (top-right)
                  if (p.isReel)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 2),
                            Text('Reel',
                                style: body(10,
                                    weight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  // Double-tap heart burst
                  Center(
                    child: AnimatedScale(
                      scale: _burst ? 1 : 0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      child: AnimatedOpacity(
                        opacity: _burst ? 1 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(Icons.favorite,
                            size: 110,
                            color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ),
                  ),
                  // Upload state — only while POST /api/posts is in flight or
                  // after it failed.
                  if (p.pending != null) _UploadOverlay(post: p.pending!),
                ],
              ),
            ),
          ),
          // Action row
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
            child: Row(
              children: [
                _ActionIcon(
                  icon: _liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _liked ? const Color(0xFFE0245E) : AppColors.label,
                  onTap: _toggleLike,
                ),
                _ActionIcon(
                  icon: Icons.mode_comment_outlined,
                  onTap: () => showCommentsSheet(context, postId: p.id),
                ),
                _ActionIcon(
                  icon: Icons.send_outlined,
                  onTap: () => showShareSheet(
                    context,
                    author: p.author,
                    caption: p.caption,
                    isReel: p.isReel,
                  ),
                ),
                const Spacer(),
                ListenableBuilder(
                  listenable: SavedStore.instance,
                  builder: (context, _) {
                    final saved = SavedStore.instance.isSaved(p.id);
                    return _ActionIcon(
                      icon: saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: saved ? AppColors.gold700 : AppColors.label,
                      onTap: () {
                        final nowSaved =
                            SavedStore.instance.toggle(p.toSavedItem());
                        _showSnack(
                            context,
                            nowSaved
                                ? 'Saved to your profile'
                                : 'Removed from saved');
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          // Likes
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 0),
            child: Text('$_likeCount likes',
                style: body(13,
                    weight: FontWeight.w700, color: AppColors.forest900)),
          ),
          // Caption
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: '${p.author}  ',
                    style: body(13,
                        weight: FontWeight.w700, color: AppColors.ink)),
                TextSpan(
                    text: p.caption,
                    style: body(13, color: AppColors.label, height: 1.35)),
              ]),
            ),
          ),
          // Comments + time
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListenableBuilder(
                  listenable: CommentStore.instance,
                  builder: (context, _) {
                    // Falls back to the feed's commentCount until this post's
                    // comments have actually been fetched.
                    final count = CommentStore.instance
                        .countFor(p.id, fallback: p.comments);
                    return GestureDetector(
                      onTap: () => showCommentsSheet(context, postId: p.id),
                      child: Text(
                        count == 0
                            ? 'Add a comment…'
                            : 'View all $count comment${count == 1 ? '' : 's'}',
                        style: body(12, color: AppColors.hint),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(p.time.toUpperCase(),
                    style: body(10,
                        color: AppColors.hint, letterSpacing: 0.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Autoplaying, looping, muted video for a reel post (tap to mute/unmute).
class _VideoTile extends StatefulWidget {
  const _VideoTile(
      {this.path, this.url, this.author = '', this.caption = '', this.saved})
      : assert(path != null || url != null, 'need a local path or a remote url');
  final String? path; // local file
  final String? url; // remote (Cloudinary) video
  final String author;
  final String caption;
  final SavedItem? saved;

  @override
  State<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<_VideoTile> {
  VideoPlayerController? _controller;
  bool _muted = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    final c = widget.url != null
        ? VideoPlayerController.networkUrl(Uri.parse(widget.url!))
        : VideoPlayerController.file(File(widget.path!));
    _controller = c;
    c.initialize().then((_) {
      if (!mounted) return;
      c
        ..setLooping(true)
        ..setVolume(0)
        ..play();
      setState(() {});
    }).catchError((_) {
      if (mounted) setState(() => _error = true);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggleMute() {
    final c = _controller;
    if (c == null) return;
    setState(() => _muted = !_muted);
    c.setVolume(_muted ? 0 : 1);
  }

  // Tap the reel → open the immersive full-screen player (keeps playing from
  // the current spot). Pause the inline copy while away, resume on return.
  Future<void> _openFullScreen() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final pos = c.value.position;
    c.pause();
    await Navigator.of(context).push(PageRouteBuilder(
      opaque: false, // lets the feed show through while swiping to dismiss
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => FullScreenReelPage(
        path: widget.path,
        url: widget.url,
        startAt: pos,
        author: widget.author,
        caption: widget.caption,
        saved: widget.saved,
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ));
    if (mounted) c.play(); // resume inline playback when the user comes back
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (_error) {
      return Container(
        color: AppColors.forest900,
        alignment: Alignment.center,
        child: const Icon(Icons.videocam_off_rounded,
            color: Colors.white54, size: 48),
      );
    }
    if (c == null || !c.value.isInitialized) {
      return Container(
        color: AppColors.forest900,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
            color: Colors.white54, strokeWidth: 2),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openFullScreen,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cover-fit the video within the square frame.
          ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            ),
          ),
          // Tap-to-expand hint
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fullscreen_rounded,
                  size: 16, color: Colors.white),
            ),
          ),
          // Mute toggle (its own tap target, doesn't trigger full-screen)
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: _toggleMute,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sits over a freshly-picked post's media while `POST /api/posts` runs, and
/// turns into a retry prompt if the upload fails — so a dropped connection
/// never silently swallows a post the user thought they shared.
class _UploadOverlay extends StatelessWidget {
  const _UploadOverlay({required this.post});
  final UserPost post;

  @override
  Widget build(BuildContext context) {
    final failed = post.failed;
    return Container(
      color: Colors.black.withValues(alpha: failed ? 0.55 : 0.35),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!failed) ...[
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text('Uploading…',
                style: body(13,
                    weight: FontWeight.w600, color: Colors.white)),
          ] else ...[
            const Icon(Icons.cloud_off_rounded,
                size: 34, color: Colors.white),
            const SizedBox(height: 8),
            Text('Upload failed',
                style: body(13,
                    weight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () async {
                    try {
                      await FeedStore.instance.retry(post);
                    } catch (e) {
                      if (!context.mounted) return;
                      _showSnack(context,
                          e is ApiException ? e.message : 'Still offline');
                    }
                  },
                  child: Text('Retry',
                      style: body(13,
                          weight: FontWeight.w700, color: Colors.white)),
                ),
                TextButton(
                  onPressed: () => FeedStore.instance.remove(post),
                  child: Text('Discard',
                      style: body(13, color: Colors.white70)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.onTap,
    this.color = AppColors.label,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 26, color: color),
      onPressed: onTap,
      splashRadius: 22,
    );
  }
}

/// Initials avatar on a forest gradient (matches the app's no-stock-photo look).
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.size = 36});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Reuse PexelsImage's initials fallback by passing an empty url.
    return PexelsImage(url: '', name: name, size: size);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message, style: body(13, color: Colors.white)),
      backgroundColor: AppColors.forest800,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
    ));
}
