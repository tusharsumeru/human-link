import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../data/story_store.dart';
import '../theme/app_theme.dart';

/// One frame in the story viewer. Media is a Cloudinary URL (image or video);
/// the gradient+emoji path is a fallback when there's no media.
class StorySlide {
  StorySlide({
    required this.author,
    required this.createdAt,
    this.mediaUrl,
    this.isVideo = false,
    this.emoji,
    this.gradient = const [Color(0xFF1B4332), Color(0xFF2D6A4F)],
    this.caption = '',
    this.isMine = false,
    this.storyId,
    this.viewCount = 0,
    this.onShown,
    this.onDeleted,
  });

  final String author;
  final DateTime createdAt;
  final String? mediaUrl; // Cloudinary image/video
  final bool isVideo;
  final String? emoji; // fallback placeholder glyph
  final List<Color> gradient;
  final String caption;
  final bool isMine;
  final String? storyId; // links to the backend for views / delete
  final int viewCount;
  final VoidCallback? onShown; // e.g. mark viewed on the backend
  final VoidCallback? onDeleted; // refresh the rail after a delete
}

/// Immersive, auto-advancing story player. Tap right → next, left → previous,
/// hold to pause, swipe down to dismiss. Your own stories show a live "Seen by"
/// footer and a delete action.
class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.slides,
    this.initialIndex = 0,
  });

  final List<StorySlide> slides;
  final int initialIndex;

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  static const _imageDuration = Duration(seconds: 5);
  late final AnimationController _progress;
  VideoPlayerController? _video;
  late int _i;

  @override
  void initState() {
    super.initState();
    _i = widget.initialIndex.clamp(0, widget.slides.length - 1);
    _progress = AnimationController(vsync: this, duration: _imageDuration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _next();
      });
    _show();
  }

  @override
  void dispose() {
    _disposeVideo();
    _progress.dispose();
    super.dispose();
  }

  void _disposeVideo() {
    _video?.dispose();
    _video = null;
  }

  void _show() {
    final s = widget.slides[_i];
    s.onShown?.call();
    _disposeVideo();

    if (s.isVideo && s.mediaUrl != null && s.mediaUrl!.isNotEmpty) {
      final vc = VideoPlayerController.networkUrl(Uri.parse(s.mediaUrl!));
      _video = vc;
      vc.initialize().then((_) {
        if (!mounted || _video != vc) return;
        vc
          ..setLooping(false)
          ..play();
        final ms = vc.value.duration.inMilliseconds.clamp(3000, 30000);
        _progress
          ..duration = Duration(milliseconds: ms)
          ..reset()
          ..forward();
        setState(() {});
      }).catchError((_) {
        if (!mounted || _video != vc) return;
        _progress
          ..duration = _imageDuration
          ..reset()
          ..forward();
      });
    } else {
      _progress
        ..duration = _imageDuration
        ..reset()
        ..forward();
    }
  }

  void _next() {
    if (_i < widget.slides.length - 1) {
      setState(() => _i++);
      _show();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _prev() {
    if (_i > 0) {
      setState(() => _i--);
      _show();
    } else {
      _progress
        ..reset()
        ..forward();
    }
  }

  void _pause() {
    _progress.stop();
    _video?.pause();
  }

  void _resume() {
    _video?.play();
    _progress.forward();
  }

  void _onTapUp(TapUpDetails d) {
    final w = MediaQuery.of(context).size.width;
    if (d.localPosition.dx < w / 3) {
      _prev();
    } else {
      _next();
    }
  }

  Future<void> _showViewers(String storyId) async {
    _pause();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _ViewersSheet(storyId: storyId),
    );
    if (mounted) _resume();
  }

  Future<void> _confirmDelete(StorySlide slide) async {
    _pause();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: Text('Delete story?', style: display(18, color: AppColors.forest900)),
        content: Text('This removes it for everyone.',
            style: body(13, color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: body(14, color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete',
                style: body(14, weight: FontWeight.w700, color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) {
      if (mounted) _resume();
      return;
    }
    try {
      await StoryStore.instance.deleteStory(slide.storyId!);
      slide.onDeleted?.call();
    } catch (_) {/* ignore; keep going */}
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.slides[_i];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: _media(slide)),

          // Tap / hold / swipe gestures.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: _onTapUp,
              onLongPressStart: (_) => _pause(),
              onLongPressEnd: (_) => _resume(),
              onVerticalDragEnd: (d) {
                if (d.velocity.pixelsPerSecond.dy > 200) {
                  Navigator.of(context).maybePop();
                }
              },
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                  child: _progressBars(),
                ),
                _header(slide),
              ],
            ),
          ),

          if (slide.caption.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: slide.isMine ? 84 : 28,
              child: Text(slide.caption,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: body(14, color: Colors.white, height: 1.4)),
            ),

          if (slide.isMine && slide.storyId != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(top: false, child: _seenByBar(slide)),
            ),
        ],
      ),
    );
  }

  Widget _media(StorySlide s) {
    final vc = _video;
    if (s.isVideo && vc != null && vc.value.isInitialized) {
      return AspectRatio(
        aspectRatio: vc.value.aspectRatio == 0 ? 9 / 16 : vc.value.aspectRatio,
        child: VideoPlayer(vc),
      );
    }
    if (s.isVideo && s.mediaUrl != null) {
      return const CircularProgressIndicator(color: Colors.white54, strokeWidth: 2);
    }
    if (s.mediaUrl != null && s.mediaUrl!.isNotEmpty) {
      return Image.network(
        s.mediaUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center(
                child: CircularProgressIndicator(
                    color: Colors.white54, strokeWidth: 2)),
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined,
            color: Colors.white54, size: 48),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: s.gradient,
        ),
      ),
      child: Center(
          child: Text(s.emoji ?? '✦', style: const TextStyle(fontSize: 96))),
    );
  }

  Widget _progressBars() {
    return Row(
      children: [
        for (var idx = 0; idx < widget.slides.length; idx++)
          Expanded(
            child: Container(
              height: 2.5,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: idx < _i
                  ? _fill(1)
                  : idx == _i
                      ? AnimatedBuilder(
                          animation: _progress,
                          builder: (_, __) => _fill(_progress.value),
                        )
                      : const SizedBox.shrink(),
            ),
          ),
      ],
    );
  }

  Widget _fill(double v) => FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: v.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _header(StorySlide s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 4, 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.forest600,
            child: Text(
              s.author.trim().isEmpty ? '?' : s.author.trim()[0].toUpperCase(),
              style: body(13, weight: FontWeight.w700, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(s.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: body(14,
                          weight: FontWeight.w700, color: Colors.white)),
                ),
                const SizedBox(width: 8),
                Text(_ago(s.createdAt), style: body(12, color: Colors.white70)),
              ],
            ),
          ),
          if (s.isMine && s.storyId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.white, size: 24),
              onPressed: () => _confirmDelete(s),
            ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _seenByBar(StorySlide slide) {
    return GestureDetector(
      onTap: () => _showViewers(slide.storyId!),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              slide.viewCount == 0 ? 'No views yet' : 'Seen by ${slide.viewCount}',
              style: body(14, weight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_up_rounded,
                color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet listing who viewed one of your stories (fetched from the API).
class _ViewersSheet extends StatefulWidget {
  const _ViewersSheet({required this.storyId});
  final String storyId;

  @override
  State<_ViewersSheet> createState() => _ViewersSheetState();
}

class _ViewersSheetState extends State<_ViewersSheet> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = StoryStore.instance.viewers(widget.storyId);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          final viewers = snap.data ?? const [];
          final loading = snap.connectionState == ConnectionState.waiting;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_outlined,
                        size: 18, color: AppColors.forest700),
                    const SizedBox(width: 8),
                    Text(
                        loading ? 'Viewers' : 'Viewers · ${viewers.length}',
                        style: display(16, color: AppColors.forest900)),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              if (loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.forest700, strokeWidth: 2)),
                )
              else if (viewers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text('No one has viewed this story yet.',
                        style: body(13, color: AppColors.textMuted)),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: viewers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (context, i) {
                      final v = viewers[i];
                      final user = v['user'];
                      final name = (user is Map ? user['userName'] : null)
                              ?.toString() ??
                          'Member';
                      final at =
                          DateTime.tryParse((v['viewedAt'] ?? '').toString());
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.forest600,
                          child: Text(
                            name.trim().isEmpty
                                ? '?'
                                : name.trim()[0].toUpperCase(),
                            style: body(14,
                                weight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                        title: Text(name,
                            style: body(14,
                                weight: FontWeight.w600, color: AppColors.ink)),
                        trailing: at == null
                            ? null
                            : Text(_ago(at), style: body(12, color: AppColors.hint)),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}

/// Compact relative time ("Just now", "3m", "2h").
String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 24) return '${d.inHours}h';
  return '${d.inDays}d';
}
