import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/story_store.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/family_search_sheet.dart';
import '../widgets/story_text_overlay.dart';
import '../widgets/ui_kit.dart';

/// "Share Story" composer — shown after picking media, before it's posted.
/// Preview + caption + options, then "Post to Community" uploads to the backend
/// (`POST /api/stories`). Caption and visibility are persisted; the tag/location/
/// tree-node options are UI affordances the stories endpoint doesn't store yet.
class StoryComposeScreen extends StatefulWidget {
  const StoryComposeScreen({
    super.key,
    required this.filePath,
    required this.isVideo,
  });

  final String filePath;
  final bool isVideo;

  @override
  State<StoryComposeScreen> createState() => _StoryComposeScreenState();
}

class _StoryComposeScreenState extends State<StoryComposeScreen> {
  final _captionCtrl = TextEditingController();
  final _overlayKey = GlobalKey<StoryTextOverlayEditorState>();
  final _videoOverlayKey = GlobalKey<StoryVideoTextOverlayEditorState>();
  String _visibility = 'community';
  final List<Map<String, dynamic>> _tagged = [];
  Map<String, dynamic>? _treeNode;
  String? _locationName;
  String? _locationKind;
  bool _posting = false;

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  ({String label, IconData icon}) _visInfo(AppLocalizations t) =>
      switch (_visibility) {
        'followers' => (
          label: t.storyVisFamilyFollowers,
          icon: Icons.groups_outlined,
        ),
        'private' => (label: t.storyVisOnlyMe, icon: Icons.lock_outline),
        _ => (label: t.storyVisCommunity, icon: Icons.public),
      };

  Future<void> _pickTagged() async {
    final t = AppLocalizations.of(context);
    final res = await showFamilySearchSheet(
      context,
      title: t.storyTagFamilyMembers,
      multi: true,
      selectedIds: _tagged.map((m) => (m['_id'] ?? '').toString()).toSet(),
    );
    if (res != null) {
      setState(() {
        _tagged
          ..clear()
          ..addAll(res);
      });
    }
  }

  Future<void> _pickTreeNode() async {
    final res = await showFamilySearchSheet(
      context,
      title: AppLocalizations.of(context).storyLinkAncestor,
      multi: false,
    );
    if (res != null && res.isNotEmpty) {
      setState(() => _treeNode = res.first);
    }
  }

  Future<void> _pickLocation() async {
    final result = await showModalBottomSheet<({String name, String kind})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _LocationSheet(
        initialName: _locationName ?? '',
        initialKind: _locationKind ?? 'village',
      ),
    );
    if (result != null) {
      setState(() {
        _locationName = result.name.isEmpty ? null : result.name;
        _locationKind = result.name.isEmpty ? null : result.kind;
      });
    }
  }

  Future<void> _pickVisibility() async {
    final t = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Text(
              t.storyWhoCanSee,
              style: display(17, color: AppColors.forest900),
            ),
            const SizedBox(height: 6),
            _visTile(
              'community',
              Icons.public,
              t.storyVisCommunity,
              t.storyVisCommunityDesc,
            ),
            _visTile(
              'followers',
              Icons.groups_outlined,
              t.storyVisFamilyFollowers,
              t.storyVisFollowersDesc,
            ),
            _visTile(
              'private',
              Icons.lock_outline,
              t.storyVisOnlyMe,
              t.storyVisPrivateDesc,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (choice != null) setState(() => _visibility = choice);
  }

  Widget _visTile(String value, IconData icon, String title, String subtitle) {
    final selected = _visibility == value;
    return ListTile(
      leading: Icon(icon, color: AppColors.forest700),
      title: Text(
        title,
        style: body(14, weight: FontWeight.w600, color: AppColors.ink),
      ),
      subtitle: Text(subtitle, style: body(12, color: AppColors.textMuted)),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppColors.forest700)
          : null,
      onTap: () => Navigator.of(context).pop(value),
    );
  }

  Future<void> _post() async {
    setState(() => _posting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final t = AppLocalizations.of(context);
    try {
      // A photo's text is baked straight into the pixels before upload — the
      // backend just stores an image, it has no concept of a text layer. A
      // video can't be baked the same way (that means real encoding), so its
      // text travels as data instead and is composited live by the viewer.
      final path = widget.isVideo
          ? widget.filePath
          : await (_overlayKey.currentState?.export() ??
                Future.value(widget.filePath));
      final textOverlays = widget.isVideo
          ? (_videoOverlayKey.currentState?.exportOverlays() ?? const [])
          : const <Map<String, dynamic>>[];
      await StoryStore.instance.addStory(
        path,
        caption: _captionCtrl.text.trim(),
        visibility: _visibility,
        taggedMembers: _tagged.map((m) => (m['_id'] ?? '').toString()).toList(),
        treeNodeId: (_treeNode?['_id'] ?? '').toString().isEmpty
            ? null
            : _treeNode!['_id'].toString(),
        locationName: _locationName,
        locationKind: _locationKind,
        textOverlays: textOverlays,
      );
      if (!mounted) return;
      navigator.pop(); // back to the feed
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.storyShared, style: body(13, color: Colors.white)),
          backgroundColor: AppColors.forest800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _posting = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            t.storyCouldNotPost(
              e is ApiException ? e.message : t.storyPleaseTryAgain,
            ),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final vis = _visInfo(t);
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
          t.storyShareTitle,
          style: display(
            18,
            color: context.onBrightness(
              light: AppColors.forest900,
              dark: AppColors.darkText,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                // Preview — both get the "Aa" text-overlay editor. A photo's
                // text is baked into the pixels on post; a video's travels as
                // data and is composited live by the story viewer instead.
                if (widget.isVideo)
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.55,
                      ),
                      child: StoryVideoTextOverlayEditor(
                        key: _videoOverlayKey,
                        videoPath: widget.filePath,
                      ),
                    ),
                  )
                else
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.55,
                      ),
                      child: StoryTextOverlayEditor(
                        key: _overlayKey,
                        imagePath: widget.filePath,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    widget.isVideo
                        ? t.storyReviewRecording
                        : t.storyReviewPhoto,
                    style: body(
                      12,
                      color: context.onBrightness(
                        light: AppColors.textMuted,
                        dark: AppColors.darkTextMuted,
                      ),
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 18),

                // Caption
                Text(
                  t.storyCaption,
                  style: body(
                    14,
                    weight: FontWeight.w700,
                    color: context.onBrightness(
                      light: AppColors.forest900,
                      dark: AppColors.darkText,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _captionCtrl,
                  maxLines: 4,
                  minLines: 3,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  style: body(14, color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: t.storyCaptionHint,
                    hintStyle: body(13, color: AppColors.hint),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.forest700,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Options
                _OptionCard(
                  iconBg: const Color(0xFFF3D9CE),
                  icon: Icons.person_add_alt_1_outlined,
                  iconColor: const Color(0xFFB05E7A),
                  title: t.storyTagFamilyMembers,
                  subtitle: _tagged.isEmpty
                      ? t.storySearchVamshaVruksha
                      : _tagged.map((m) => m['name']).join(', '),
                  onTap: _pickTagged,
                ),
                const SizedBox(height: 10),
                _OptionCard(
                  iconBg: const Color(0xFFE7E2DA),
                  icon: Icons.place_outlined,
                  iconColor: AppColors.forest700,
                  title: t.storyAddLocation,
                  subtitle: _locationName == null
                      ? t.storyLocationSubtitle
                      : '$_locationName · ${_locationKind ?? ''}',
                  onTap: _pickLocation,
                ),
                const SizedBox(height: 10),
                _OptionCard(
                  iconBg: AppColors.forest700,
                  icon: Icons.account_tree_outlined,
                  iconColor: Colors.white,
                  title: t.storyLinkToTreeNode,
                  subtitle: _treeNode == null
                      ? t.storyAttachAncestor
                      : t.storyLinkedTo(_treeNode!['name']),
                  onTap: _pickTreeNode,
                  trailing: Switch(
                    value: _treeNode != null,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.forest600,
                    onChanged: (v) {
                      if (v) {
                        _pickTreeNode();
                      } else {
                        setState(() => _treeNode = null);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Bottom bar: visibility + post
          Container(
            decoration: const BoxDecoration(
              color: AppColors.cream,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickVisibility,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t.storyVisibleTo,
                            style: body(11, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                vis.icon,
                                size: 14,
                                color: AppColors.forest700,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  vis.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: body(
                                    13,
                                    weight: FontWeight.w700,
                                    color: AppColors.forest800,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: AppColors.forest700,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ForestButton(
                    label: t.storyPostToCommunity,
                    icon: Icons.send_rounded,
                    loading: _posting,
                    onPressed: _posting ? null : _post,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sheet to name a place and pick its kind (village/temple/…). Returns
/// `(name, kind)`; an empty name means "remove the location".
class _LocationSheet extends StatefulWidget {
  const _LocationSheet({required this.initialName, required this.initialKind});
  final String initialName;
  final String initialKind;

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.initialName,
  );
  late String _kind = widget.initialKind;

  List<(String, String)> _kindsOf(AppLocalizations t) => [
    ('village', t.storyKindVillage),
    ('temple', t.storyKindTemple),
    ('community_center', t.storyKindCommunityCenter),
    ('other', t.storyKindOther),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
              const SizedBox(height: 14),
              Text(
                t.storyAddLocation,
                style: display(17, color: AppColors.forest900),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: body(14, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: t.storyLocationHint,
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.forest700,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final k in _kindsOf(t))
                    ChoiceChip(
                      label: Text(k.$2),
                      selected: _kind == k.$1,
                      onSelected: (_) => setState(() => _kind = k.$1),
                      selectedColor: AppColors.forest700,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
                      labelStyle: body(
                        12,
                        color: _kind == k.$1 ? Colors.white : AppColors.label,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (widget.initialName.isNotEmpty)
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop((name: '', kind: '')),
                      child: Text(
                        t.commonRemove,
                        style: body(14, color: Colors.red),
                      ),
                    ),
                  const Spacer(),
                  ForestButton(
                    label: t.commonSave,
                    onPressed: () => Navigator.of(
                      context,
                    ).pop((name: _ctrl.text.trim(), kind: _kind)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: body(
                        14,
                        weight: FontWeight.w700,
                        color: AppColors.forest900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: body(12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.hint,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
