import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/api_client.dart';
import '../data/chat_service.dart';
import '../data/repository.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'full_screen_reel.dart';

/// A 1:1 real-time chat with another member. Loads history over REST, then
/// streams live messages from the socket. Both my sent messages and the other
/// party's arrive via the same `message:new` stream, deduped by `_id`.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherName,
    this.otherAvatarUrl = '',
  });

  final String otherUserId;
  final String otherName;
  final String otherAvatarUrl;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();
  final List<Map<String, dynamic>> _messages = [];
  final Set<String> _seenIds = {};
  StreamSubscription<Map<String, dynamic>>? _sub;
  StreamSubscription<String>? _readSub;
  bool _loading = true;
  bool _sending = false;
  bool _uploading = false;
  late final String _myId;

  @override
  void initState() {
    super.initState();
    // Prefer the JWT's `sub` (always present when logged in) so bubble sides are
    // correct even for a session persisted before AppUser carried an id.
    _myId = _jwtSub(ApiAuth.token) ??
        (context.read<AuthService>().user?.id ?? '');
    ChatService.instance.ensureConnected();
    _sub = ChatService.instance.onMessage.listen(_onIncoming);
    _readSub = ChatService.instance.onRead.listen(_onRead);
    _load();
  }

  Future<void> _load() async {
    try {
      final history =
          await Repository.instance.messageHistory(widget.otherUserId);
      for (final m in history) {
        _insert(m, notify: false);
      }
    } catch (_) {
      // Leave the thread empty; the composer still works.
    }
    if (mounted) setState(() => _loading = false);
    _scrollToBottom();
    // Best-effort: clear the unread badge for this thread.
    Repository.instance.markConversationRead(widget.otherUserId).ignore();
  }

  // Only messages belonging to THIS conversation (me ↔ other).
  bool _belongsHere(Map<String, dynamic> m) {
    final from = (m['senderId'] ?? '').toString();
    final to = (m['recipientId'] ?? '').toString();
    return (from == _myId && to == widget.otherUserId) ||
        (from == widget.otherUserId && to == _myId);
  }

  void _onIncoming(Map<String, dynamic> m) {
    if (!_belongsHere(m)) return;
    _insert(m);
    _scrollToBottom();
    if ((m['senderId'] ?? '').toString() == widget.otherUserId) {
      Repository.instance.markConversationRead(widget.otherUserId).ignore();
    }
  }

  // The other party just read our conversation — stamp every message I sent
  // them that wasn't already marked read, so those bubbles flip from a single
  // to a double (read) tick without a reload.
  void _onRead(String byUserId) {
    if (byUserId != widget.otherUserId) return;
    var changed = false;
    final now = DateTime.now().toIso8601String();
    for (final m in _messages) {
      if ((m['senderId'] ?? '').toString() == _myId && m['readAt'] == null) {
        m['readAt'] = now;
        changed = true;
      }
    }
    if (changed && mounted) setState(() {});
  }

  // Insert deduped, keeping ascending createdAt order.
  void _insert(Map<String, dynamic> m, {bool notify = true}) {
    final id = (m['_id'] ?? '').toString();
    if (id.isEmpty || _seenIds.contains(id)) return;
    _seenIds.add(id);
    _messages.add(m);
    _messages.sort((a, b) => (a['createdAt'] ?? '')
        .toString()
        .compareTo((b['createdAt'] ?? '').toString()));
    if (notify && mounted) setState(() {});
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    _input.clear();
    setState(() => _sending = true);
    try {
      final saved = await ChatService.instance.send(widget.otherUserId, text);
      _insert(saved); // dedupes if the socket echo already added it
      _scrollToBottom();
    } catch (e) {
      _input.text = text; // let them retry
      if (mounted) {
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : t.chatMessageNotSent),
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showAttachmentOptions() async {
    if (_uploading) return;
    final t = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_outlined, color: AppColors.forest800),
              title: Text(t.chatPhotosVideos, style: body(14, color: AppColors.ink)),
              onTap: () => Navigator.pop(ctx, 'gallery_media'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.forest800),
              title: Text(t.chatCamera, style: body(14, color: AppColors.ink)),
              onTap: () => Navigator.pop(ctx, 'camera_photo'),
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined, color: AppColors.forest800),
              title: Text(t.chatDocuments, style: body(14, color: AppColors.ink)),
              onTap: () => Navigator.pop(ctx, 'document'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    if (choice == 'document') {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt',
        ],
      );
      final picked = result?.files.single;
      if (picked?.path == null || !mounted) return;
      await _sendAttachment(picked!.path!, fileName: picked.name);
      return;
    }

    XFile? file;
    switch (choice) {
      case 'gallery_media':
        // Unified image-or-video gallery picker — one entry for both, same
        // as the option label ("Photos/Videos"). maxWidth/imageQuality only
        // apply when the pick turns out to be an image; videos ignore them.
        file = await _picker.pickMedia(maxWidth: 1600, imageQuality: 85);
        break;
      case 'camera_photo':
        file = await _picker.pickImage(
            source: ImageSource.camera, maxWidth: 1600, imageQuality: 85);
        break;
    }
    if (file == null || !mounted) return;
    await _sendAttachment(file.path);
  }

  Future<void> _sendAttachment(String filePath, {String? fileName}) async {
    setState(() => _uploading = true);
    try {
      final saved = await Repository.instance.sendAttachmentMessage(
          widget.otherUserId, filePath,
          fileName: fileName);
      _insert(saved);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : t.chatCouldNotSendFile),
        ));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _readSub?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
        title: Row(
          children: [
            _InitialsAvatar(name: widget.otherName, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.otherName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: display(17, color: AppColors.forest900),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(t.chatSayHello,
                            style: body(14, color: AppColors.hint)),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final m = _messages[i];
                          final mine =
                              (m['senderId'] ?? '').toString() == _myId;
                          return _Bubble(
                            text: (m['text'] ?? '').toString(),
                            mediaUrl: (m['mediaUrl'] ?? '').toString(),
                            mediaType: (m['mediaType'] ?? '').toString(),
                            mediaName: (m['mediaName'] ?? '').toString(),
                            mine: mine,
                            read: m['readAt'] != null,
                            time: _formatMessageTime(m['createdAt']),
                          );
                        },
                      ),
          ),
          _composer(t),
        ],
      ),
    );
  }

  Widget _composer(AppLocalizations t) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: const BoxDecoration(
          color: AppColors.cream,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _uploading ? null : _showAttachmentOptions,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _uploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.forest800),
                        )
                      : const Icon(Icons.add_circle_outline,
                          color: AppColors.forest800, size: 24),
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _send(),
                style: body(14, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: t.chatMessageHint,
                  hintStyle: body(14, color: AppColors.hint),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide:
                        const BorderSide(color: AppColors.forest700, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Material(
              color: AppColors.forest800,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _sending ? null : _send,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "12:25 PM" in the device's local time, or '' if the message carries no
/// (or an unparseable) timestamp — never shown as a fake time.
String _formatMessageTime(Object? createdAt) {
  final iso = (createdAt ?? '').toString();
  if (iso.isEmpty) return '';
  final t = DateTime.tryParse(iso);
  if (t == null) return '';
  return DateFormat('h:mm a').format(t.toLocal());
}

/// Reads the `sub` (user id) claim out of a JWT, or null if it can't.
String? _jwtSub(String? token) {
  if (token == null || token.isEmpty) return null;
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final sub = (jsonDecode(payload) as Map<String, dynamic>)['sub'];
    return (sub == null || sub.toString().isEmpty) ? null : sub.toString();
  } catch (_) {
    return null;
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.mine,
    this.mediaUrl = '',
    this.mediaType = '',
    this.mediaName = '',
    this.time = '',
    this.read = false,
  });
  final String text;
  final bool mine;
  final String mediaUrl;
  final String mediaType;
  final String mediaName;
  final String time;
  // Only meaningful when [mine] — whether the other party has read this
  // message yet (single tick if not, double blue tick once they have).
  final bool read;

  Future<void> _openMedia(BuildContext context) async {
    if (mediaType == 'video') {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => FullScreenReelPage(url: mediaUrl),
      ));
    } else if (mediaType == 'document') {
      final uri = Uri.tryParse(mediaUrl);
      final opened =
          uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).chatNoAppForFile),
        ));
      }
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _FullScreenImage(url: mediaUrl),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = mediaUrl.isNotEmpty;
    final isDocument = mediaType == 'document';
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: hasMedia && !isDocument
                ? const EdgeInsets.all(4)
                : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(maxWidth: maxWidth),
            decoration: BoxDecoration(
              color: mine ? AppColors.forest800 : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(mine ? 16 : 4),
                bottomRight: Radius.circular(mine ? 4 : 16),
              ),
              border: mine ? null : Border.all(color: AppColors.border),
            ),
            child: Column(
              // Only stretch to the bubble's max width for an image (which
              // needs to fill it); a plain text or document bubble should
              // shrink-wrap to its content instead of always going full width.
              crossAxisAlignment: hasMedia && !isDocument
                  ? CrossAxisAlignment.stretch
                  : (mine ? CrossAxisAlignment.end : CrossAxisAlignment.start),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasMedia && isDocument)
                  GestureDetector(
                    onTap: () => _openMedia(context),
                    child: _DocumentCard(name: mediaName, mine: mine),
                  ),
                if (hasMedia && !isDocument)
                  GestureDetector(
                    onTap: () => _openMedia(context),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: mediaType == 'video'
                          ? _VideoThumb(maxWidth: maxWidth)
                          : CachedNetworkImage(
                              imageUrl: mediaUrl,
                              width: maxWidth,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => SizedBox(
                                width: maxWidth,
                                height: maxWidth * 0.75,
                                child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                              ),
                              errorWidget: (_, __, ___) => SizedBox(
                                width: maxWidth,
                                height: maxWidth * 0.75,
                                child: const Center(
                                    child: Icon(Icons.broken_image_outlined,
                                        color: AppColors.hint)),
                              ),
                            ),
                    ),
                  ),
                if (text.isNotEmpty)
                  Padding(
                    padding: hasMedia && !isDocument
                        ? const EdgeInsets.fromLTRB(10, 6, 10, 4)
                        : hasMedia
                            ? const EdgeInsets.only(top: 8)
                            : EdgeInsets.zero,
                    child: Text(
                      text,
                      style:
                          body(14, color: mine ? Colors.white : AppColors.ink),
                    ),
                  ),
              ],
            ),
          ),
          if (time.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 3, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(time, style: body(10, color: AppColors.hint)),
                  if (mine) ...[
                    const SizedBox(width: 3),
                    Icon(
                      read ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 13,
                      color: read ? const Color(0xFF34B7F1) : AppColors.hint,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A compact file row — icon + filename — for a document attachment. Tapping
/// the bubble opens it in an external app (PDF/Office viewer or browser).
class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.name, required this.mine});
  final String name;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final fg = mine ? Colors.white : AppColors.forest900;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.insert_drive_file_rounded, color: fg, size: 28),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            name.isEmpty ? AppLocalizations.of(context).chatDocumentFallback : name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: body(13, weight: FontWeight.w600, color: fg),
          ),
        ),
      ],
    );
  }
}

/// A dark placeholder card with a play glyph — video thumbnails aren't
/// fetched client-side, so this simply signals "tap to play".
class _VideoThumb extends StatelessWidget {
  const _VideoThumb({required this.maxWidth});
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: maxWidth,
      height: maxWidth * 0.75,
      color: Colors.black87,
      alignment: Alignment.center,
      child: const Icon(Icons.play_circle_fill_rounded,
          color: Colors.white, size: 44),
    );
  }
}

/// Simple pinch-to-zoom full-screen viewer for a chat image attachment.
class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Small circular avatar showing the member's initials.
class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name, this.size = 34});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.forest700,
        shape: BoxShape.circle,
      ),
      child: Text(initials,
          style: body(13, weight: FontWeight.w700, color: Colors.white)),
    );
  }
}
