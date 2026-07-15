import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../data/saved_store.dart';
import '../theme/app_theme.dart';

/// Immersive full-screen reel player. Opens playing from where the feed left
/// off. Tap the video to pause/resume; swipe down to dismiss (Instagram-style);
/// a ✕ in the top-left corner also closes it.
class FullScreenReelPage extends StatefulWidget {
  const FullScreenReelPage({
    super.key,
    this.path,
    this.url,
    this.startAt = Duration.zero,
    this.author = '',
    this.caption = '',
    this.saved,
  }) : assert(path != null || url != null, 'need a local path or a remote url');

  final String? path; // local file
  final String? url; // remote (Cloudinary) video
  final Duration startAt;
  final String author;
  final String caption;

  /// The bookmarkable form of this reel. When non-null a save button appears in
  /// the top bar; tapping it toggles the reel in the app-wide [SavedStore].
  final SavedItem? saved;

  @override
  State<FullScreenReelPage> createState() => _FullScreenReelPageState();
}

class _FullScreenReelPageState extends State<FullScreenReelPage> {
  late final VideoPlayerController _c;
  bool _ready = false;
  bool _muted = false;
  double _dragDy = 0; // downward drag offset for swipe-to-dismiss

  static const _dismissDistance = 140.0;

  @override
  void initState() {
    super.initState();
    _c = widget.url != null
        ? VideoPlayerController.networkUrl(Uri.parse(widget.url!))
        : VideoPlayerController.file(File(widget.path!));
    _c.addListener(_onTick);
    _c.initialize().then((_) {
      if (!mounted) return;
      _c
        ..setLooping(true)
        ..setVolume(1);
      if (widget.startAt > Duration.zero) _c.seekTo(widget.startAt);
      _c.play();
      setState(() => _ready = true);
    }).catchError((_) {
      if (mounted) setState(() => _ready = false);
    });
  }

  @override
  void dispose() {
    _c.removeListener(_onTick);
    _c.dispose();
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _togglePlay() {
    if (!_c.value.isInitialized) return;
    _c.value.isPlaying ? _c.pause() : _c.play();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _c.setVolume(_muted ? 0 : 1);
  }

  void _toggleSave() {
    final item = widget.saved!;
    final nowSaved = SavedStore.instance.toggle(item);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(nowSaved ? 'Saved to your profile' : 'Removed from saved',
            style: body(13, color: Colors.white)),
        backgroundColor: AppColors.forest800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ));
  }

  /// Bookmark toggle that reflects live save-state (the "small rect").
  Widget _saveButton() {
    return ListenableBuilder(
      listenable: SavedStore.instance,
      builder: (context, _) {
        final saved = SavedStore.instance.isSaved(widget.saved!.id);
        return IconButton(
          icon: Icon(
            saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: saved ? AppColors.gold500 : Colors.white,
          ),
          onPressed: _toggleSave,
        );
      },
    );
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() => _dragDy = (_dragDy + d.delta.dy).clamp(0.0, 1000.0));
  }

  void _onDragEnd(DragEndDetails d) {
    if (_dragDy > _dismissDistance || d.velocity.pixelsPerSecond.dy > 800) {
      Navigator.of(context).pop();
    } else {
      setState(() => _dragDy = 0); // snap back
    }
  }

  @override
  Widget build(BuildContext context) {
    final paused = _ready && !_c.value.isPlaying;
    // As you drag down, the black backdrop fades so the feed shows behind.
    final dragProgress = (_dragDy / 300).clamp(0.0, 1.0);
    final backdropAlpha = (1 - dragProgress).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fading black backdrop (reveals the feed underneath while dragging).
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withValues(alpha: backdropAlpha)),
          ),

          // Video — follows the finger vertically during a dismiss drag.
          Center(
            child: Transform.translate(
              offset: Offset(0, _dragDy),
              child: _ready
                  ? AspectRatio(
                      aspectRatio: _c.value.aspectRatio == 0
                          ? 9 / 16
                          : _c.value.aspectRatio,
                      child: VideoPlayer(_c),
                    )
                  : const CircularProgressIndicator(color: Colors.white54),
            ),
          ),

          // Tap → pause/resume. Vertical drag → swipe-to-dismiss.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _togglePlay,
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
            ),
          ),

          // Big play glyph while paused (only when not mid-drag).
          if (paused && _dragDy == 0)
            const IgnorePointer(
              child: Center(
                child: Icon(Icons.play_arrow_rounded,
                    size: 88, color: Colors.white70),
              ),
            ),

          // Top bar pinned to the TOP: ✕ (left corner), author, mute.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        widget.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: body(15,
                            weight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    if (widget.saved != null) _saveButton(),
                    IconButton(
                      icon: Icon(
                        _muted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: Colors.white,
                      ),
                      onPressed: _toggleMute,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Caption at the bottom.
          if (widget.caption.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    widget.caption,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: body(14, color: Colors.white, height: 1.4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
