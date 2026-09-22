import 'dart:io';

import 'package:flutter/material.dart';

import '../data/saved_store.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Immersive full-screen photo viewer — the image-post counterpart to
/// [FullScreenReelPage]. Pinch-to-zoom via [InteractiveViewer]; a ✕ in the
/// top-left corner (or the system back gesture) closes it.
class FullScreenImagePage extends StatelessWidget {
  const FullScreenImagePage({
    super.key,
    this.path,
    this.url,
    this.author = '',
    this.caption = '',
    this.saved,
  }) : assert(path != null || url != null, 'need a local path or a remote url');

  final String? path; // local file
  final String? url; // remote (Cloudinary) image
  final String author;
  final String caption;

  /// The bookmarkable form of this post. When non-null a save button appears
  /// in the top bar; tapping it toggles the post in the app-wide [SavedStore].
  final SavedItem? saved;

  void _toggleSave(BuildContext context) {
    final item = saved!;
    final nowSaved = SavedStore.instance.toggle(item);
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            nowSaved ? t.reelSavedToProfile : t.reelRemovedFromSaved,
            style: body(13, color: Colors.white),
          ),
          backgroundColor: AppColors.forest800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
  }

  Widget _saveButton(BuildContext context) {
    return ListenableBuilder(
      listenable: SavedStore.instance,
      builder: (context, _) {
        final isSaved = SavedStore.instance.isSaved(saved!.id);
        return IconButton(
          icon: Icon(
            isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: isSaved ? AppColors.gold500 : Colors.white,
          ),
          onPressed: () => _toggleSave(context),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = path != null
        ? Image.file(File(path!), fit: BoxFit.contain)
        : Image.network(
            url!,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 48,
            ),
          );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: InteractiveViewer(maxScale: 4, child: image)),

          // Top bar: ✕ (left corner), author, save.
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
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: body(
                          15,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (saved != null) _saveButton(context),
                  ],
                ),
              ),
            ),
          ),

          // Caption at the bottom.
          if (caption.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    caption,
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
