import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pexels_image.dart';
import 'profile_screen.dart' show FollowListMode, FollowListSheet;

/// Another registered member's public profile — Instagram-style: avatar,
/// name/bio, Followers/Following/Posts stats (tap Followers/Following for the
/// list, same sheet the self-profile uses), a Follow button, and their
/// public-visibility posts grid.
///
/// Distinct from [ProfileScreen]: that screen's `id` is read as a family-tree
/// member (or "me" when absent) — a real account id like a post's author or a
/// follow-list row would 404 there and silently fall back to showing your own
/// profile. This screen's `userId` is always a real `users` collection id.
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _user = const {};
  int _followers = 0;
  int _following = 0;
  int _postCount = 0;
  List<Map<String, dynamic>> _posts = const [];
  // Separate from [_error]: the posts grid can fail on its own (e.g. a
  // backend still missing GET /api/posts/user/:id) without taking down the
  // header, which already has everything it needs from userFut/countsFut.
  String? _postsError;
  bool _isFollowing = false;
  bool _followBusy = false;
  bool _isMe = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _postsError = null;
    });
    final myId = context.read<AuthService>().user?.id ?? '';
    final isMe = myId.isNotEmpty && myId == widget.userId;
    // Started together (not awaited yet) so they run concurrently.
    final userFut = Repository.instance.userById(widget.userId);
    final countsFut = Repository.instance.followCounts(widget.userId);
    final followingFut = (!isMe && myId.isNotEmpty)
        ? Repository.instance.following(myId)
        : Future.value(<Map<String, dynamic>>[]);
    // Posts are fetched and awaited separately (own try/catch below) so a
    // failure here shows an inline error in the grid instead of blanking
    // out the whole profile — name/avatar/follow button don't depend on it.
    final postsFut = Repository.instance.userPosts(widget.userId, limit: 30);

    try {
      final user = await userFut;
      final counts = await countsFut;
      final myFollowing = await followingFut;
      final alreadyFollowing = myFollowing.any((rel) {
        final f = rel['followingId'];
        final id = f is Map ? (f['_id'] ?? f['id'])?.toString() : f?.toString();
        return id == widget.userId;
      });
      if (!mounted) return;
      setState(() {
        _isMe = isMe;
        _user = user;
        _followers = counts.followers;
        _following = counts.following;
        _isFollowing = alreadyFollowing;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Could not load this profile';
        _loading = false;
      });
      return;
    }

    try {
      final postsRes = await postsFut;
      final posts = ((postsRes['posts'] as List?) ?? const [])
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .toList();
      if (!mounted) return;
      setState(() {
        _postCount = (postsRes['count'] as num?)?.toInt() ?? posts.length;
        _posts = posts;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _postsError = e is ApiException ? e.message : "Couldn't load posts";
      });
    }
  }

  /// Same optimistic-flip-then-revert-on-failure pattern used for follow
  /// toggles elsewhere in the app (see dashboard_screen.dart's post cards).
  Future<void> _toggleFollow() async {
    final myId = context.read<AuthService>().user?.id ?? '';
    if (myId.isEmpty || _followBusy) return;
    final was = _isFollowing;
    setState(() {
      _isFollowing = !was;
      _followers += was ? -1 : 1;
      _followBusy = true;
    });
    try {
      if (was) {
        await Repository.instance.unfollowUser(
          followerId: myId,
          followingId: widget.userId,
        );
      } else {
        await Repository.instance.followUser(
          followerId: myId,
          followingId: widget.userId,
        );
      }
      if (!mounted) return;
      setState(() => _followBusy = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFollowing = was;
        _followers += was ? 1 : -1;
        _followBusy = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.message : 'Could not update follow',
              style: body(13, color: Colors.white),
            ),
            backgroundColor: AppColors.forest800,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  void _openList(FollowListMode mode) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FollowListSheet(userId: widget.userId, mode: mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (_user['name'] ?? _user['userName'] ?? '').toString();
    return Scaffold(
      backgroundColor: context.onBrightness(
        light: AppColors.cream,
        dark: AppColors.darkBg,
      ),
      appBar: AppBar(
        backgroundColor: context.onBrightness(
          light: AppColors.cream,
          dark: AppColors.darkSurface,
        ),
        elevation: 0,
        foregroundColor: context.onBrightness(
          light: AppColors.forest900,
          dark: AppColors.darkText,
        ),
        title: Text(
          _loading ? '' : (name.isEmpty ? 'Profile' : name),
          style: display(
            17,
            color: context.onBrightness(
              light: AppColors.forest900,
              dark: AppColors.darkText,
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.forest700),
            )
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: body(
                  14,
                  color: context.onBrightness(
                    light: AppColors.textMuted,
                    dark: AppColors.darkTextMuted,
                  ),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _header(context)),
                  _postsGrid(context),
                ],
              ),
            ),
    );
  }

  Widget _header(BuildContext context) {
    final name = (_user['name'] ?? _user['userName'] ?? '').toString();
    final userName = (_user['userName'] ?? '').toString();
    final samajId = (_user['samajId'] ?? '').toString();
    final bio = (_user['bio'] ?? '').toString();
    final gotra = (_user['gotra'] ?? '').toString();
    final native = (_user['native'] ?? '').toString();
    final photo = (_user['profileUrl'] ?? '').toString();
    final subtitleParts = [
      if (userName.isNotEmpty) '@$userName',
      if (samajId.isNotEmpty) samajId,
    ];
    final detailParts = [
      if (gotra.isNotEmpty) gotra,
      if (native.isNotEmpty) native,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PexelsImage(url: photo, name: name, size: 88),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat('Posts', _postCount, null),
                    _stat(
                      'Followers',
                      _followers,
                      () => _openList(FollowListMode.followers),
                    ),
                    _stat(
                      'Following',
                      _following,
                      () => _openList(FollowListMode.following),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            name.isEmpty ? 'Samaj member' : name,
            style: body(
              15,
              weight: FontWeight.w700,
              color: context.onBrightness(
                light: AppColors.forest900,
                dark: AppColors.darkText,
              ),
            ),
          ),
          if (subtitleParts.isNotEmpty)
            Text(
              subtitleParts.join(' · '),
              style: body(
                12,
                color: context.onBrightness(
                  light: AppColors.textMuted,
                  dark: AppColors.darkTextMuted,
                ),
              ),
            ),
          if (detailParts.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              detailParts.join(' · '),
              style: body(
                12,
                color: context.onBrightness(
                  light: AppColors.textMuted,
                  dark: AppColors.darkTextMuted,
                ),
              ),
            ),
          ],
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              bio,
              style: body(
                13,
                color: context.onBrightness(
                  light: AppColors.ink,
                  dark: AppColors.darkText,
                ),
                height: 1.4,
              ),
            ),
          ],
          if (!_isMe) ...[const SizedBox(height: 14), _followButton(context)],
          const SizedBox(height: 12),
          Divider(
            color: context.onBrightness(
              light: AppColors.border,
              dark: AppColors.darkBorder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int count, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            '$count',
            style: display(
              17,
              color: context.onBrightness(
                light: AppColors.forest900,
                dark: AppColors.darkText,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: body(
              12,
              color: context.onBrightness(
                light: AppColors.textMuted,
                dark: AppColors.darkTextMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _followButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: _isFollowing
          ? OutlinedButton(
              onPressed: _followBusy ? null : _toggleFollow,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: context.onBrightness(
                    light: AppColors.border,
                    dark: AppColors.darkBorder,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Following',
                style: body(
                  14,
                  weight: FontWeight.w600,
                  color: context.onBrightness(
                    light: AppColors.ink,
                    dark: AppColors.darkText,
                  ),
                ),
              ),
            )
          : FilledButton(
              onPressed: _followBusy ? null : _toggleFollow,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.forest700,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Follow',
                style: body(14, weight: FontWeight.w600, color: Colors.white),
              ),
            ),
    );
  }

  Widget _postsGrid(BuildContext context) {
    if (_postsError != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 28,
                  color: context.onBrightness(
                    light: AppColors.textMuted,
                    dark: AppColors.darkTextMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Couldn't load posts",
                  textAlign: TextAlign.center,
                  style: body(
                    13,
                    weight: FontWeight.w600,
                    color: context.onBrightness(
                      light: AppColors.textMuted,
                      dark: AppColors.darkTextMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _postsError!,
                  textAlign: TextAlign.center,
                  style: body(
                    12,
                    color: context.onBrightness(
                      light: AppColors.textMuted,
                      dark: AppColors.darkTextMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }
    if (_posts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Text(
              'No posts yet',
              style: body(
                13,
                color: context.onBrightness(
                  light: AppColors.textMuted,
                  dark: AppColors.darkTextMuted,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.all(2),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => _PostThumb(post: _posts[i]),
          childCount: _posts.length,
        ),
      ),
    );
  }
}

class _PostThumb extends StatelessWidget {
  const _PostThumb({required this.post});
  final Map<String, dynamic> post;

  @override
  Widget build(BuildContext context) {
    final urls = post['mediaUrls'];
    final mediaUrl = urls is List && urls.isNotEmpty
        ? urls.first.toString()
        : '';
    final isVideo = (post['postType'] ?? '').toString() == 'video';
    return Stack(
      fit: StackFit.expand,
      children: [
        mediaUrl.isEmpty
            ? const ColoredBox(color: AppColors.forest900)
            : Image.network(
                mediaUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: AppColors.forest900),
              ),
        if (isVideo)
          const Positioned(
            top: 4,
            right: 4,
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 18,
              shadows: [Shadow(blurRadius: 4, color: Colors.black87)],
            ),
          ),
      ],
    );
  }
}
