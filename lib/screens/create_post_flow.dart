import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/feed_store.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/location_picker_sheet.dart';
import '../widgets/ui_kit.dart';

const _videoExtensions = <String>[
  'mp4', 'mov', 'mkv', 'webm', '3gp', 'avi', 'm4v', 'flv', 'wmv',
];

/// Create (+) → post from files only (no camera; the camera lives on the
/// "Your Story" flow). Picks an image or video from the device, then composes
/// and uploads it.
Future<void> showCreateOptions(BuildContext context) async {
  final auth = context.read<AuthService>();
  final router = GoRouter.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final t = AppLocalizations.of(context);

  String? path;
  try {
    // FileType.media = photos + videos ("anything").
    final result = await FilePicker.platform.pickFiles(type: FileType.media);
    path = result?.files.single.path;
  } catch (e) {
    messenger.showSnackBar(
        SnackBar(content: Text(t.postCouldNotPickMedia('$e'))));
    return;
  }
  if (path == null) return; // cancelled or no path

  final isReel = _videoExtensions.contains(path.split('.').last.toLowerCase());
  final navContext = router.routerDelegate.navigatorKey.currentContext ?? context;
  if (!navContext.mounted) return;
  await _composeAndUpload(
    navContext,
    auth: auth,
    router: router,
    path: path,
    isReel: isReel,
  );
}

/// Shared tail for both entry points: caption composer → optimistic feed jump →
/// upload, with success/failure snackbars.
Future<void> _composeAndUpload(
  BuildContext navContext, {
  required AuthService auth,
  required GoRouter router,
  required String path,
  required bool isReel,
}) async {
  final messenger = ScaffoldMessenger.of(navContext);
  final t = AppLocalizations.of(navContext);
  final user = auth.user;

  final result = await _composeCaption(
    navContext,
    mediaPath: path,
    isReel: isReel,
  );
  if (result == null) return; // cancelled at composer

  // Jump to the feed first: the card shows straight away from the local file
  // with an "Uploading…" overlay, and settles once POST /api/posts returns.
  router.go('/dashboard');

  try {
    await FeedStore.instance.upload(
      mediaPath: path,
      caption: result.caption,
      isReel: isReel,
      author: user?.name ?? t.postAuthorFallback,
      // Only the place the author explicitly picked — no "Samaj Member" label
      // and no auto-filled native place.
      location: result.location,
      hashtags: _hashtagsIn(result.caption),
    );
    messenger.showSnackBar(SnackBar(
      content: Text(isReel ? t.postReelShared : t.postShared,
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
          t.postUploadFailed(
              e is ApiException ? e.message : t.postCheckConnection),
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

/// What the composer returns: the caption plus the (optional) place the author
/// attached. `location` is '' when none was picked.
class _ComposeResult {
  const _ComposeResult(this.caption, this.location);
  final String caption;
  final String location;
}

/// Full-screen composer: preview + caption + current location + Share. Returns the
/// caption + location, or null if the user backed out.
Future<_ComposeResult?> _composeCaption(
  BuildContext context, {
  required String mediaPath,
  required bool isReel,
}) {
  final controller = TextEditingController();
  final t = AppLocalizations.of(context);
  String location = ''; // the place the author picks, if any
  bool locating = false; // fetching the current GPS location
  return showModalBottomSheet<_ComposeResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
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
                        Text(isReel ? t.postNewReel : t.postNewPost,
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
                              hintText: t.postCaptionHint,
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
                    const SizedBox(height: 12),
                    // The device's current location, attached with one tap.
                    // Once set it shows as a removable chip.
                    _LocationRow(
                      location: location,
                      locating: locating,
                      t: t,
                      onUseCurrent: () async {
                        if (locating) return;
                        setSheetState(() => locating = true);
                        try {
                          final place = await currentLocationName();
                          setSheetState(() {
                            location = place;
                            locating = false;
                          });
                        } on LocationFailure catch (e) {
                          setSheetState(() => locating = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(e.message)),
                            );
                          }
                        } catch (_) {
                          setSheetState(() => locating = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(t.postCouldNotGetLocation)),
                            );
                          }
                        }
                      },
                      onClear: () => setSheetState(() => location = ''),
                    ),
                    const SizedBox(height: 16),
                    ForestButton(
                      label: t.postShareButton,
                      icon: Icons.send_rounded,
                      expand: true,
                      onPressed: () => Navigator.of(ctx).pop(
                        _ComposeResult(
                          controller.text.trim().isEmpty
                              ? (isReel
                                  ? t.postDefaultReelCaption
                                  : t.postDefaultPostCaption)
                              : controller.text.trim(),
                          location,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// The location affordance in the composer — when empty, a single "Current
/// location" (GPS) action; once set, a pin + place name with a clear button.
class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.location,
    required this.locating,
    required this.onUseCurrent,
    required this.onClear,
    required this.t,
  });
  final String location;
  final bool locating;
  final VoidCallback onUseCurrent;
  final VoidCallback onClear;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    if (location.isEmpty) {
      return _Action(
        icon: Icons.my_location_rounded,
        label: locating ? t.postLocating : t.postCurrentLocation,
        onTap: onUseCurrent,
        busy: locating,
      );
    }
    return InkWell(
      onTap: onUseCurrent, // tap the row to refresh it
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded,
                size: 20, color: AppColors.gold700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: body(14,
                      weight: FontWeight.w600, color: AppColors.forest900)),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.hint),
              onPressed: onClear,
              tooltip: t.postRemoveLocation,
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact pill button used for the two empty-state location choices.
class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.busy = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.forest700),
                  )
                : Icon(icon, size: 18, color: AppColors.forest700),
            const SizedBox(width: 8),
            Text(label,
                style: body(13,
                    weight: FontWeight.w600, color: AppColors.forest800)),
          ],
        ),
      ),
    );
  }
}
