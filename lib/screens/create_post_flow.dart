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
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';
import '../widgets/user_search_sheet.dart';

const _videoExtensions = <String>[
  'mp4',
  'mov',
  'mkv',
  'webm',
  '3gp',
  'avi',
  'm4v',
  'flv',
  'wmv',
];

/// Create (+) → post from files only (no camera; the camera lives on the
/// "Your Story" flow). Picks one or more images (or a single video) from the
/// device, then composes and uploads them as one post — multiple images
/// become an Instagram-style carousel.
Future<void> showCreateOptions(BuildContext context) async {
  final auth = context.read<AuthService>();
  final router = GoRouter.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final t = AppLocalizations.of(context);

  List<String> paths;
  try {
    // FileType.media = photos + videos ("anything").
    final result = await FilePicker.platform.pickFiles(
      type: FileType.media,
      allowMultiple: true,
    );
    paths = (result?.files ?? const [])
        .map((f) => f.path)
        .whereType<String>()
        .toList();
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(t.postCouldNotPickMedia('$e'))),
    );
    return;
  }
  if (paths.isEmpty) return; // cancelled or no path

  bool isVideo(String p) =>
      _videoExtensions.contains(p.split('.').last.toLowerCase());

  bool isReel;
  if (paths.length > 1) {
    // A carousel is images only (Instagram-style) — a video mixed in with a
    // multi-select doesn't have a single-post representation here, so it's
    // silently dropped rather than blocking the whole selection.
    paths = paths.where((p) => !isVideo(p)).toList();
    isReel = false;
    if (paths.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Select at least one image')),
      );
      return;
    }
  } else {
    isReel = isVideo(paths.first);
  }

  final navContext =
      router.routerDelegate.navigatorKey.currentContext ?? context;
  if (!navContext.mounted) return;
  await _composeAndUpload(
    navContext,
    auth: auth,
    router: router,
    paths: paths,
    isReel: isReel,
  );
}

/// Shared tail for both entry points: caption composer → optimistic feed jump →
/// upload, with success/failure snackbars.
Future<void> _composeAndUpload(
  BuildContext navContext, {
  required AuthService auth,
  required GoRouter router,
  required List<String> paths,
  required bool isReel,
}) async {
  final messenger = ScaffoldMessenger.of(navContext);
  final t = AppLocalizations.of(navContext);
  final user = auth.user;

  final result = await _composeCaption(
    navContext,
    mediaPaths: paths,
    isReel: isReel,
  );
  if (result == null) return; // cancelled at composer

  // Jump to the feed first: the card shows straight away from the local file
  // with an "Uploading…" overlay, and settles once POST /api/posts returns.
  router.go('/dashboard');

  try {
    await FeedStore.instance.upload(
      mediaPaths: paths,
      caption: result.caption,
      isReel: isReel,
      author: user?.name ?? t.postAuthorFallback,
      // Only the place the author explicitly picked — no "Samaj Member" label
      // and no auto-filled native place.
      location: result.location,
      hashtags: _hashtagsIn(result.caption),
      taggedUsers: result.tagged
          .map((m) => (m['id'] ?? '').toString())
          .toList(),
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          isReel ? t.postReelShared : t.postShared,
          style: body(13, color: Colors.white),
        ),
        backgroundColor: AppColors.forest800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  } catch (e) {
    // The card stays in the feed marked "Upload failed — Retry", so the user
    // never loses the pick just because the network dropped.
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          t.postUploadFailed(
            e is ApiException ? e.message : t.postCheckConnection,
          ),
          style: body(13, color: Colors.white),
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

/// "#kumta #heritage" in the caption → `['kumta', 'heritage']` for the API's
/// optional hashtags field.
List<String> _hashtagsIn(String caption) => RegExp(
  r'#(\w+)',
).allMatches(caption).map((m) => m.group(1)!).toSet().toList();

/// What the composer returns: the caption, the (optional) place the author
/// attached (`location` is '' when none was picked), and whoever was tagged.
class _ComposeResult {
  const _ComposeResult(this.caption, this.location, this.tagged);
  final String caption;
  final String location;
  final List<Map<String, dynamic>> tagged;
}

/// Full-screen composer: preview + caption + current location + tag people +
/// Share. Returns the caption + location + tagged people, or null if the user
/// backed out.
Future<_ComposeResult?> _composeCaption(
  BuildContext context, {
  required List<String> mediaPaths,
  required bool isReel,
}) {
  final controller = TextEditingController();
  final t = AppLocalizations.of(context);
  String location = ''; // the place the author picks, if any
  bool locating = false; // fetching the current GPS location
  List<Map<String, dynamic>> tagged = const []; // people tagged in this post
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
                        Text(
                          isReel ? t.postNewReel : t.postNewPost,
                          style: display(18, color: AppColors.forest900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isReel)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 84,
                              height: 84,
                              color: AppColors.forest900,
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: Colors.white70,
                                  size: 30,
                                ),
                              ),
                            ),
                          )
                        else if (mediaPaths.length > 1)
                          SizedBox(
                            width: 84,
                            height: 84,
                            child: Stack(
                              children: [
                                ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: mediaPaths.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 6),
                                  itemBuilder: (_, i) => ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(mediaPaths[i]),
                                      width: 84,
                                      height: 84,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.55,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${mediaPaths.length}',
                                      style: body(
                                        10,
                                        weight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(mediaPaths.first),
                              width: 84,
                              height: 84,
                              fit: BoxFit.cover,
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
                              hintText: t.postCaptionHint,
                              hintStyle: body(13, color: AppColors.hint),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.forest700,
                                  width: 1.5,
                                ),
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
                            ScaffoldMessenger.of(
                              ctx,
                            ).showSnackBar(SnackBar(content: Text(e.message)));
                          }
                        } catch (_) {
                          setSheetState(() => locating = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(t.postCouldNotGetLocation),
                              ),
                            );
                          }
                        }
                      },
                      onClear: () => setSheetState(() => location = ''),
                    ),
                    const SizedBox(height: 10),
                    // Tag people in the post (Instagram-style) — searches all
                    // registered members, not just the caller's family tree.
                    _TagPeopleRow(
                      tagged: tagged,
                      onTap: () async {
                        final picked = await showUserSearchSheet(
                          ctx,
                          title: 'Tag people',
                          selectedIds: tagged
                              .map((m) => (m['id'] ?? '').toString())
                              .toSet(),
                        );
                        if (picked != null) {
                          setSheetState(() => tagged = picked);
                        }
                      },
                      onRemove: (id) => setSheetState(
                        () => tagged = tagged
                            .where((m) => (m['id'] ?? '').toString() != id)
                            .toList(),
                      ),
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
                          tagged,
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

/// The "tag people" affordance in the composer — when empty, a single action
/// that opens the member search sheet; once someone is tagged, their avatars
/// show as a horizontal row of removable chips plus an "Add" pill.
class _TagPeopleRow extends StatelessWidget {
  const _TagPeopleRow({
    required this.tagged,
    required this.onTap,
    required this.onRemove,
  });
  final List<Map<String, dynamic>> tagged;
  final VoidCallback onTap;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (tagged.isEmpty) {
      return _Action(
        icon: Icons.person_add_alt_1_rounded,
        label: 'Tag people',
        onTap: onTap,
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final m in tagged)
          Chip(
            avatar: PexelsImage(
              url: (m['profileUrl'] ?? '').toString(),
              name: (m['name'] ?? m['userName'] ?? '').toString(),
              size: 22,
            ),
            label: Text(
              (m['name'] ?? m['userName'] ?? '').toString(),
              style: body(
                12,
                weight: FontWeight.w600,
                color: AppColors.forest800,
              ),
            ),
            deleteIcon: const Icon(Icons.close_rounded, size: 16),
            onDeleted: () => onRemove((m['id'] ?? '').toString()),
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.border),
            visualDensity: VisualDensity.compact,
          ),
        InkWell(
          onTap: onTap,
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
                const Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: AppColors.forest700,
                ),
                const SizedBox(width: 4),
                Text(
                  'Add',
                  style: body(
                    12,
                    weight: FontWeight.w600,
                    color: AppColors.forest800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
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
            const Icon(
              Icons.location_on_rounded,
              size: 20,
              color: AppColors.gold700,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: body(
                  14,
                  weight: FontWeight.w600,
                  color: AppColors.forest900,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.hint,
              ),
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
                      strokeWidth: 2,
                      color: AppColors.forest700,
                    ),
                  )
                : Icon(icon, size: 18, color: AppColors.forest700),
            const SizedBox(width: 8),
            Text(
              label,
              style: body(
                13,
                weight: FontWeight.w600,
                color: AppColors.forest800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
