import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../data/feed_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/pexels_image.dart';

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

class _Feed extends StatelessWidget {
  const _Feed();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FeedStore.instance,
      builder: (context, _) {
        // User-uploaded posts (newest first) sit above the seeded demo posts.
        final userPosts =
            FeedStore.instance.posts.map(_Post.fromUser).toList();
        final all = <_Post>[...userPosts, ..._posts];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
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
    required this.author,
    required this.subtitle,
    required this.emoji,
    required this.gradient,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.time,
    this.imagePath,
    this.isReel = false,
  });

  final String author;
  final String subtitle;
  final String emoji;
  final List<Color> gradient;
  final String caption;
  final int likes;
  final int comments;
  final String time;
  final String? imagePath; // real photo (user upload); null → gradient+emoji
  final bool isReel;

  /// Builds a feed card from a user-created upload.
  factory _Post.fromUser(UserPost p) => _Post(
        author: p.author,
        subtitle: p.subtitle,
        emoji: p.isReel ? '🎬' : '🖼️',
        gradient: const [AppColors.forest800, AppColors.forest600],
        caption: p.caption,
        likes: 0,
        comments: 0,
        time: 'Just now',
        imagePath: p.imagePath,
        isReel: p.isReel,
      );
}

const _posts = <_Post>[
  _Post(
    author: 'Venkatesh Haldankar',
    subtitle: 'Basavanagudi, Bengaluru',
    emoji: '📜',
    gradient: [Color(0xFF8B5E3C), Color(0xFFC4823A)],
    caption:
        'Sharing a treasured memory from the 1968 Samaj Utsava in Kumta. Our elders in their prime — the goldsmith community stood tall. 🙏',
    likes: 214,
    comments: 18,
    time: '2 hours ago',
  ),
  _Post(
    author: 'Shri Narayanarao Suvarna',
    subtitle: 'Elder & Admin · Rajajinagar',
    emoji: '🌳',
    gradient: [AppColors.forest800, AppColors.forest600],
    caption:
        'Verified the lineage of the Chickpete branch today. Three generations of the Suvarna family now mapped on the tree. Heritage preserved. ✅',
    likes: 342,
    comments: 27,
    time: 'Yesterday',
  ),
  _Post(
    author: 'Rekha Diwakar',
    subtitle: 'Jayanagar, Bengaluru',
    emoji: '🎂',
    gradient: [Color(0xFFB05E7A), Color(0xFFC4823A)],
    caption:
        'Thank you all for the birthday wishes from the Samaj family! Blessed to celebrate with our community. 🎉❤️',
    likes: 489,
    comments: 63,
    time: 'Today',
  ),
  _Post(
    author: 'Daivajna Samaja Bhavan',
    subtitle: 'Samaj Bhavan Renovation · Fundraiser',
    emoji: '🏛️',
    gradient: [Color(0xFF166534), Color(0xFF16A34A)],
    caption:
        '85% funded! The new 500-seat auditorium is taking shape. Thank you to our 328 backers. Every contribution builds our future. 🙏',
    likes: 176,
    comments: 12,
    time: '2 days ago',
  ),
  _Post(
    author: 'Karthik Revankar',
    subtitle: 'Jayanagar, Bengaluru',
    emoji: '🎶',
    gradient: [Color(0xFF3B4C8A), Color(0xFF1B4332)],
    caption:
        'Carnatic vocal session at this year\'s cultural evening. Nothing like our traditions coming alive on stage. 🎵',
    likes: 231,
    comments: 21,
    time: '3 days ago',
  ),
];

class _PostCard extends StatefulWidget {
  const _PostCard({required this.post});
  final _Post post;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _liked = false;
  bool _saved = false;
  bool _burst = false;
  Timer? _burstTimer;

  @override
  void dispose() {
    _burstTimer?.cancel();
    super.dispose();
  }

  int get _likeCount => widget.post.likes + (_liked ? 1 : 0);

  void _toggleLike() => setState(() => _liked = !_liked);

  void _doubleTapLike() {
    setState(() {
      _liked = true;
      _burst = true;
    });
    _burstTimer?.cancel();
    _burstTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _burst = false);
    });
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
          // Media
          GestureDetector(
            onDoubleTap: _doubleTapLike,
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (p.imagePath != null)
                    Image.file(File(p.imagePath!), fit: BoxFit.cover)
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
                  onTap: () => _showSnack(context, 'View comments'),
                ),
                _ActionIcon(
                  icon: Icons.send_outlined,
                  onTap: () => _showSnack(context, 'Share post'),
                ),
                const Spacer(),
                _ActionIcon(
                  icon: _saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: _saved ? AppColors.gold700 : AppColors.label,
                  onTap: () => setState(() => _saved = !_saved),
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
                GestureDetector(
                  onTap: () => _showSnack(context, 'View comments'),
                  child: Text('View all ${p.comments} comments',
                      style: body(12, color: AppColors.hint)),
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
