import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/chat_service.dart';
import '../data/repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

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
  final List<Map<String, dynamic>> _messages = [];
  final Set<String> _seenIds = {};
  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _loading = true;
  bool _sending = false;
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : 'Message not sent'),
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
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
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        child: Text('Say hello 👋',
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
                            mine: mine,
                          );
                        },
                      ),
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _composer() {
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
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _send(),
                style: body(14, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Message…',
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
  const _Bubble({required this.text, required this.mine});
  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
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
        child: Text(
          text,
          style: body(14, color: mine ? Colors.white : AppColors.ink),
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
