import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/demo_data.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/pexels_image.dart';

/// Opens the Instagram-style share sheet for a post or reel.
void showShareSheet(
  BuildContext context, {
  required String author,
  required String caption,
  bool isReel = false,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _ShareSheet(author: author, caption: caption, isReel: isReel),
  );
}

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({
    required this.author,
    required this.caption,
    required this.isReel,
  });
  final String author;
  final String caption;
  final bool isReel;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final Set<String> _sentTo = {};

  // Stable wire value for the deep-link slug — never localized.
  String get _kind => widget.isReel ? 'reel' : 'post';

  String _kindLabel(AppLocalizations t) => widget.isReel ? t.shareReel : t.sharePost;

  // A shareable deep link for this item (placeholder domain).
  String get _link {
    final slug = widget.author.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    return 'https://samaj.app/$_kind/$slug';
  }

  String _shareText(AppLocalizations t) => t.shareTextTemplate(
      widget.author, _kindLabel(t), widget.caption, _link);

  void _toggleSend(Map<String, dynamic> member) {
    final id = member['id'] as String;
    setState(() {
      if (_sentTo.contains(id)) {
        _sentTo.remove(id);
      } else {
        _sentTo.add(id);
      }
    });
  }

  Future<void> _copyLink(AppLocalizations t) async {
    await Clipboard.setData(ClipboardData(text: _link));
    if (!mounted) return;
    Navigator.of(context).pop();
    _toast(context, t.shareLinkCopied);
  }

  Future<void> _shareExternal(AppLocalizations t) async {
    // Native OS share sheet (WhatsApp, Gmail, etc.).
    await Share.share(_shareText(t), subject: t.shareSubjectTemplate(_kindLabel(t)));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final mq = MediaQuery.of(context);
    final members = kCommunityMembers;

    return SizedBox(
      height: mq.size.height * 0.62,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999)),
            ),
            const SizedBox(height: 10),
            Text(t.shareTitle, style: display(17, color: AppColors.forest900)),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.border),

            // Send to Samaj members
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(t.shareSendTo,
                    style: body(12,
                        weight: FontWeight.w700,
                        color: AppColors.gold700,
                        letterSpacing: 1.2)),
              ),
            ),
            SizedBox(
              height: 184,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 82,
                  crossAxisSpacing: 8,
                ),
                itemCount: members.length,
                itemBuilder: (_, i) {
                  final m = members[i];
                  final sent = _sentTo.contains(m['id']);
                  return _MemberChip(
                    name: m['name'] as String,
                    sent: sent,
                    onTap: () => _toggleSend(m),
                  );
                },
              ),
            ),

            // Send button (appears once someone is selected)
            if (_sentTo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.forest700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final n = _sentTo.length;
                      Navigator.of(context).pop();
                      _toast(context, t.shareSentToMembers(n));
                    },
                    child: Text(t.shareSendButton,
                        style: body(15,
                            weight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ),

            const Divider(height: 20, color: AppColors.border),

            // Quick actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Action(
                    icon: Icons.link_rounded,
                    label: t.shareCopyLink,
                    onTap: () => _copyLink(t),
                  ),
                  _Action(
                    icon: Icons.auto_stories_outlined,
                    label: t.shareAddToStory,
                    onTap: () {
                      Navigator.of(context).pop();
                      _toast(context, t.shareAddedToStory);
                    },
                  ),
                  _Action(
                    icon: Icons.ios_share_rounded,
                    label: t.shareViaEllipsis,
                    onTap: () => _shareExternal(t),
                  ),
                ],
              ),
            ),
            SafeArea(top: false, child: const SizedBox(height: 8)),
          ],
        ),
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip(
      {required this.name, required this.sent, required this.onTap});
  final String name;
  final bool sent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final first = name.split(' ').first;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                PexelsImage(url: '', name: name, size: 50),
                if (sent)
                  Container(
                    decoration: const BoxDecoration(
                        color: AppColors.forest700, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(2),
                    child: const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: body(12,
                    color: sent ? AppColors.forest800 : AppColors.label,
                    weight: sent ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, color: AppColors.forest800, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: body(12, color: AppColors.label)),
          ],
        ),
      ),
    );
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message, style: body(13, color: Colors.white)),
      backgroundColor: AppColors.forest800,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
}
