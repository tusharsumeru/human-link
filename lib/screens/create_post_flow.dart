import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/feed_store.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

final _picker = ImagePicker();

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
              onTap: () => _startCreate(sheetCtx, isReel: false),
            ),
            const SizedBox(height: 10),
            _CreateTile(
              icon: Icons.movie_creation_outlined,
              title: 'New Reel',
              subtitle: 'Share a short video moment',
              onTap: () => _startCreate(sheetCtx, isReel: true),
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

/// Picks an image, then opens the caption composer.
Future<void> _startCreate(BuildContext sheetCtx, {required bool isReel}) async {
  final auth = sheetCtx.read<AuthService>();
  final router = GoRouter.of(sheetCtx);
  final messenger = ScaffoldMessenger.of(sheetCtx);

  XFile? picked;
  try {
    picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 88,
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Could not pick media: $e')));
    return;
  }
  if (picked == null) return; // user cancelled

  // Close the options sheet before showing the composer.
  if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();

  final user = auth.user;
  final caption = await _composeCaption(
    router.routerDelegate.navigatorKey.currentContext ?? sheetCtx,
    imagePath: picked.path,
    isReel: isReel,
  );
  if (caption == null) return; // cancelled at composer

  FeedStore.instance.add(UserPost(
    author: user?.name ?? 'You',
    subtitle: (user?.native.split(',').first.trim().isNotEmpty ?? false)
        ? user!.native.split(',').first.trim()
        : 'Daivajna Samaja',
    imagePath: picked.path,
    caption: caption,
    isReel: isReel,
  ));

  messenger.showSnackBar(SnackBar(
    content: Text(isReel ? 'Reel shared 🎬' : 'Post shared ✨',
        style: body(13, color: Colors.white)),
    backgroundColor: AppColors.forest800,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 2),
  ));

  router.go('/dashboard'); // jump to the feed to show it
}

/// Full-screen composer: preview + caption + Share. Returns the caption, or
/// null if the user backed out.
Future<String?> _composeCaption(
  BuildContext context, {
  required String imagePath,
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
                      child: Stack(
                        children: [
                          Image.file(File(imagePath),
                              width: 84, height: 84, fit: BoxFit.cover),
                          if (isReel)
                            const Positioned.fill(
                              child: Center(
                                child: Icon(Icons.play_circle_fill_rounded,
                                    color: Colors.white70, size: 28),
                              ),
                            ),
                        ],
                      ),
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
