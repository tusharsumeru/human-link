import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/feed_store.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

/// How the user started the create flow — decides which files the picker shows
/// and whether the result is treated as a photo post or a video reel.
enum _CreateMode { post, reel, file }

const _videoExtensions = <String>[
  'mp4', 'mov', 'mkv', 'webm', '3gp', 'avi', 'm4v', 'flv', 'wmv',
];

/// Bottom sheet launched from the bottom bar's "+" — choose New Post or Reel.
Future<void> showCreateOptions(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetCtx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Text('Create', style: display(20, color: AppColors.forest900)),
            const SizedBox(height: 12),
            _CreateTile(
              icon: Icons.add_photo_alternate_outlined,
              title: 'New Post',
              subtitle: 'Share a photo with the Samaj',
              onTap: () => _startCreate(sheetCtx, mode: _CreateMode.post),
            ),
            const SizedBox(height: 10),
            _CreateTile(
              icon: Icons.movie_creation_outlined,
              title: 'New Reel',
              subtitle: 'Share a short video moment',
              onTap: () => _startCreate(sheetCtx, mode: _CreateMode.reel),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CreateTile extends StatelessWidget {
  const _CreateTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppGradients.forest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: body(14,
                        weight: FontWeight.w700, color: AppColors.forest900)),
                const SizedBox(height: 2),
                Text(subtitle, style: body(12, color: AppColors.hint)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.hint),
        ],
      ),
    );
  }
}

/// Picks a photo (post), a video (reel), or any media file ("Select File",
/// type auto-detected), then opens the caption composer.
Future<void> _startCreate(
  BuildContext sheetCtx, {
  required _CreateMode mode,
}) async {
  final auth = sheetCtx.read<AuthService>();
  final router = GoRouter.of(sheetCtx);
  final messenger = ScaffoldMessenger.of(sheetCtx);

  // Uses the system Files picker (Storage Access Framework) — no Google
  // account required, unlike the Photos-backed gallery intent.
  String? path;
  try {
    final result = await FilePicker.platform.pickFiles(
      type: switch (mode) {
        _CreateMode.post => FileType.image,
        _CreateMode.reel => FileType.video,
        _CreateMode.file => FileType.media, // photos + videos
      },
    );
    path = result?.files.single.path;
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Could not pick media: $e')));
    return;
  }
  if (path == null) return; // user cancelled or no path

  // Decide post vs reel. For "Select File", infer from the extension.
  final ext = path.split('.').last.toLowerCase();
  final isReel = switch (mode) {
    _CreateMode.post => false,
    _CreateMode.reel => true,
    _CreateMode.file => _videoExtensions.contains(ext),
  };

  // Close the options sheet before showing the composer.
  if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();

  final user = auth.user;
  final caption = await _composeCaption(
    router.routerDelegate.navigatorKey.currentContext ?? sheetCtx,
    mediaPath: path,
    isReel: isReel,
  );
  if (caption == null) return; // cancelled at composer

  // Jump to the feed first: the card shows straight away from the local file
  // with an "Uploading…" overlay, and settles once POST /api/posts returns.
  router.go('/dashboard');

  try {
    await FeedStore.instance.upload(
      mediaPath: path,
      caption: caption,
      isReel: isReel,
      author: user?.name ?? 'You',
      subtitle: (user?.native.split(',').first.trim().isNotEmpty ?? false)
          ? user!.native.split(',').first.trim()
          : 'Daivajna Samaja',
      hashtags: _hashtagsIn(caption),
    );
    messenger.showSnackBar(SnackBar(
      content: Text(isReel ? 'Reel shared 🎬' : 'Post shared ✨',
          style: body(13, color: Colors.white)),
      backgroundColor: AppColors.forest800,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  } catch (e) {
    // The card stays in the feed marked "Upload failed — Retry", so the user
    // never loses the pick just because the network dropped.
    messenger.showSnackBar(SnackBar(
      content: Text(
          'Upload failed: ${e is ApiException ? e.message : 'check your connection'}',
          style: body(13, color: Colors.white)),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ));
  }
}

/// "#kumta #heritage" in the caption → `['kumta', 'heritage']` for the API's
/// optional hashtags field.
List<String> _hashtagsIn(String caption) => RegExp(r'#(\w+)')
    .allMatches(caption)
    .map((m) => m.group(1)!)
    .toSet()
    .toList();

/// Full-screen composer: preview + caption + Share. Returns the caption, or
/// null if the user backed out.
Future<String?> _composeCaption(
  BuildContext context, {
  required String mediaPath,
  required bool isReel,
}) {
  final controller = TextEditingController();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    Text(isReel ? 'New Reel' : 'New Post',
                        style: display(18, color: AppColors.forest900)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: isReel
                          ? Container(
                              width: 84,
                              height: 84,
                              color: AppColors.forest900,
                              child: const Center(
                                child: Icon(Icons.play_circle_fill_rounded,
                                    color: Colors.white70, size: 30),
                              ),
                            )
                          : Image.file(File(mediaPath),
                              width: 84, height: 84, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        maxLines: 4,
                        minLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        style: body(13, color: AppColors.ink),
                        decoration: InputDecoration(
                          hintText: 'Write a caption…',
                          hintStyle: body(13, color: AppColors.hint),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.forest700, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ForestButton(
                  label: 'Share',
                  icon: Icons.send_rounded,
                  expand: true,
                  onPressed: () => Navigator.of(ctx).pop(
                    controller.text.trim().isEmpty
                        ? (isReel ? 'New reel' : 'New post')
                        : controller.text.trim(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
