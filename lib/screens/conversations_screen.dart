import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

/// The messages inbox: my conversations, newest activity first. Tapping a row
/// opens the real-time chat with that member.
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<Map<String, dynamic>> _conversations = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await Repository.instance.conversations();
      if (mounted) {
        setState(() {
          _conversations = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _name(Map<String, dynamic>? user) {
    if (user == null) return 'Member';
    final n = (user['name'] ?? '').toString().trim();
    if (n.isNotEmpty) return n;
    final u = (user['userName'] ?? '').toString().trim();
    return u.isEmpty ? 'Member' : u;
  }

  Future<void> _openChat(Map<String, dynamic> convo) async {
    final other = convo['otherUser'] as Map<String, dynamic>?;
    final id = (other?['_id'] ?? '').toString();
    if (id.isEmpty) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatScreen(
        otherUserId: id,
        otherName: _name(other),
        otherAvatarUrl: (other?['profileUrl'] ?? '').toString(),
      ),
    ));
    _load(); // refresh unread badges / last message on return
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
        centerTitle: true,
        title: Text('Messages', style: display(20, color: AppColors.forest700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, indent: 76, color: AppColors.border),
                    itemBuilder: (_, i) => _row(_conversations[i]),
                  ),
                ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined, size: 48, color: AppColors.hint),
            const SizedBox(height: 12),
            Text('No messages yet',
                style: display(16, color: AppColors.forest900)),
            const SizedBox(height: 4),
            Text('Message a member from the directory to start a chat.',
                textAlign: TextAlign.center,
                style: body(13, color: AppColors.hint)),
          ],
        ),
      ),
    );
  }

  Widget _row(Map<String, dynamic> convo) {
    final other = convo['otherUser'] as Map<String, dynamic>?;
    final name = _name(other);
    final last = (convo['lastText'] ?? '').toString();
    final unread = (convo['unread'] as num?)?.toInt() ?? 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: _InitialsAvatar(name: name, size: 46),
      title: Text(name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: body(14,
              weight: FontWeight.w700, color: AppColors.forest900)),
      subtitle: Text(last.isEmpty ? 'Tap to chat' : last,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: body(12,
              weight: unread > 0 ? FontWeight.w700 : FontWeight.w400,
              color: unread > 0 ? AppColors.forest800 : AppColors.hint)),
      trailing: unread > 0
          ? Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                  color: AppColors.forest800, shape: BoxShape.circle),
              child: Text('$unread',
                  style: body(11, weight: FontWeight.w700, color: Colors.white)),
            )
          : null,
      onTap: () => _openChat(convo),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name, this.size = 46});
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
          style: body(15, weight: FontWeight.w700, color: Colors.white)),
    );
  }
}
