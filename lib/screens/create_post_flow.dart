import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/feed_store.dart';
import '../data/repository.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/ad_checkout.dart';
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

  String? postId;
  try {
    postId = await FeedStore.instance.upload(
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
    // A sponsored post reports its own outcome once the payment settles.
    if (result.adPlan == null) {
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
    }
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
    return;
  }

  final plan = result.adPlan;
  if (plan == null) return; // a normal post — done

  // Sponsored post: the post itself is already shared like any other. Paying
  // for the chosen plan is what starts its campaign; if the payment is
  // cancelled or fails, it simply stays a normal post.
  void notify(String text, {bool ok = true}) => messenger.showSnackBar(
    SnackBar(
      content: Text(text, style: body(13, color: Colors.white)),
      backgroundColor: ok ? AppColors.forest800 : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ),
  );

  if (postId == null || postId.isEmpty) {
    notify(
      'Post shared as a normal post — the sponsored payment could not start.',
      ok: false,
    );
    return;
  }
  final outcome = await AdCheckout.instance.promote(
    postId: postId,
    planId: (plan['id'] ?? '').toString(),
    name: user?.name ?? '',
    phone: user?.phone ?? '',
  );
  switch (outcome.status) {
    case AdCheckoutStatus.paid:
      notify('Post shared and sponsored for ${plan['durationDays']} days.');
    case AdCheckoutStatus.cancelled:
      notify('Post shared as a normal post — payment was not completed.');
    case AdCheckoutStatus.failed:
      notify(
        'Post shared as a normal post. ${outcome.message ?? ''}'.trim(),
        ok: false,
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
  const _ComposeResult(this.caption, this.location, this.tagged, this.adPlan);
  final String caption;
  final String location;
  final List<Map<String, dynamic>> tagged;

  /// The plan picked for a sponsored post (`{ id, name, durationDays, price,
  /// currency }` from GET /api/ad-plans), or null for a normal post.
  final Map<String, dynamic>? adPlan;
}

String _planPrice(Map<String, dynamic> plan) {
  final price = (plan['price'] as num?)?.toInt() ?? 0;
  final currency = (plan['currency'] ?? 'INR').toString();
  return currency == 'INR' ? '₹$price' : '$price $currency';
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
  // Post type: a normal post (the default) or a sponsored one, which is the
  // same post plus a paid campaign for the plan picked below.
  bool sponsored = false;
  List<Map<String, dynamic>>? plans; // null until first loaded
  bool loadingPlans = false;
  String? plansError;
  Map<String, dynamic>? plan; // the chosen plan
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

          Future<void> loadPlans() async {
            setSheetState(() {
              loadingPlans = true;
              plansError = null;
            });
            try {
              final loaded = await Repository.instance.adPlans();
              if (!ctx.mounted) return;
              setSheetState(() {
                plans = loaded;
                loadingPlans = false;
              });
            } catch (e) {
              if (!ctx.mounted) return;
              setSheetState(() {
                loadingPlans = false;
                plansError = e is ApiException
                    ? e.message
                    : 'Could not load the sponsored plans.';
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SafeArea(
              child: SingleChildScrollView(
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
                    const SizedBox(height: 14),
                    // Normal post (default) or sponsored post.
                    _PostTypeRow(
                      sponsored: sponsored,
                      onChanged: (value) {
                        setSheetState(() => sponsored = value);
                        if (value && plans == null && !loadingPlans) {
                          loadPlans();
                        }
                      },
                    ),
                    if (sponsored) ...[
                      const SizedBox(height: 10),
                      _AdPlanPicker(
                        plans: plans,
                        loading: loadingPlans,
                        error: plansError,
                        selected: plan,
                        onSelect: (p) => setSheetState(() => plan = p),
                        onRetry: loadPlans,
                      ),
                    ],
                    const SizedBox(height: 16),
                    ForestButton(
                      label: sponsored && plan != null
                          ? 'Share & pay ${_planPrice(plan!)}'
                          : t.postShareButton,
                      icon: Icons.send_rounded,
                      expand: true,
                      // A sponsored post needs a plan before it can be shared.
                      onPressed: sponsored && plan == null
                          ? null
                          : () => Navigator.of(ctx).pop(
                              _ComposeResult(
                                controller.text.trim().isEmpty
                                    ? (isReel
                                          ? t.postDefaultReelCaption
                                          : t.postDefaultPostCaption)
                                    : controller.text.trim(),
                                location,
                                tagged,
                                sponsored ? plan : null,
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

/// The two post types, side by side: a normal post (selected by default) and
/// a sponsored post.
class _PostTypeRow extends StatelessWidget {
  const _PostTypeRow({required this.sponsored, required this.onChanged});
  final bool sponsored;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PostTypeOption(
            icon: Icons.photo_library_outlined,
            title: 'Normal post',
            subtitle: 'Free',
            selected: !sponsored,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PostTypeOption(
            icon: Icons.campaign_outlined,
            title: 'Sponsored post',
            subtitle: 'Paid promotion',
            selected: sponsored,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

class _PostTypeOption extends StatelessWidget {
  const _PostTypeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.forest700 : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.forest700 : AppColors.hint,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: body(
                      13,
                      weight: FontWeight.w700,
                      color: AppColors.forest900,
                    ),
                  ),
                  Text(subtitle, style: body(11, color: AppColors.hint)),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: selected ? AppColors.forest700 : AppColors.hint,
            ),
          ],
        ),
      ),
    );
  }
}

/// Plan choice for a sponsored post — the durations and prices an admin has
/// set on the server (7 / 15 / 30 days …).
class _AdPlanPicker extends StatelessWidget {
  const _AdPlanPicker({
    required this.plans,
    required this.loading,
    required this.error,
    required this.selected,
    required this.onSelect,
    required this.onRetry,
  });
  final List<Map<String, dynamic>>? plans;
  final bool loading;
  final String? error;
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.forest700,
          ),
        ),
      );
    }
    if (error != null) {
      return Row(
        children: [
          Expanded(
            child: Text(error!, style: body(12, color: Colors.red.shade700)),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      );
    }
    final available = plans ?? const <Map<String, dynamic>>[];
    if (available.isEmpty) {
      return Text(
        'Sponsored posts are not available right now.',
        style: body(12, color: AppColors.hint),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Promote in the feed for',
          style: body(12, weight: FontWeight.w600, color: AppColors.hint),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in available)
              ChoiceChip(
                label: Text(
                  '${p['name']} · ${_planPrice(p)}',
                  style: body(
                    12,
                    weight: FontWeight.w600,
                    color: AppColors.forest800,
                  ),
                ),
                selected: selected != null && selected!['id'] == p['id'],
                onSelected: (_) => onSelect(p),
                showCheckmark: false,
                backgroundColor: Colors.white,
                selectedColor: AppColors.forest700.withValues(alpha: 0.14),
                side: BorderSide(
                  color: selected != null && selected!['id'] == p['id']
                      ? AppColors.forest700
                      : AppColors.border,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Your post is shared first, then you pay. If the payment is not '
          'completed it stays a normal post.',
          style: body(11, color: AppColors.hint),
        ),
      ],
    );
  }
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
