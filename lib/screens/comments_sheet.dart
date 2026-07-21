import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/comment_store.dart';
import '../data/demo_data.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pexels_image.dart';

/// Opens the Instagram-style comments sheet for a post.
void showCommentsSheet(BuildContext context, {required String postId}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CommentsSheet(postId: postId),
  );
}

/// Members available to @mention, sorted by name (deduped).
final List<String> _taggableNames = () {
  final names = <String>{
    for (final m in kCommunityMembers) m['name'] as String,
    for (final m in kFamilyMembers) m['name'] as String,
  }.toList()
    ..sort();
  return names;
}();

/// A mention token is the name with spaces removed, e.g. "@AnanyaKolwekar".
String _handleOf(String name) => '@${name.replaceAll(RegExp(r'\s+'), '')}';

final _mentionRegExp = RegExp(r'@\w+');

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.postId});
  final String postId;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  List<String> _suggestions = const [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Pull this post's comments from the API the first time its sheet opens.
    CommentStore.instance.load(widget.postId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ── @mention autocomplete ────────────────────────────────────────────────
  void _onChanged(String text) {
    final cursor = _controller.selection.baseOffset;
    if (cursor < 0) {
      _setSuggestions(const []);
      return;
    }
    final upToCursor = text.substring(0, cursor);
    final match = RegExp(r'@(\w*)$').firstMatch(upToCursor);
    if (match == null) {
      _setSuggestions(const []);
      return;
    }
    final q = match.group(1)!.toLowerCase();
    final results = _taggableNames.where((n) {
      final flat = n.toLowerCase().replaceAll(' ', '');
      return q.isEmpty || flat.contains(q) || n.toLowerCase().contains(q);
    }).take(6).toList();
    _setSuggestions(results);
  }

  void _setSuggestions(List<String> s) {
    if (!listEquals(s, _suggestions)) setState(() => _suggestions = s);
  }

  void _insertMention(String name) {
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;
    final upToCursor = text.substring(0, cursor);
    final match = RegExp(r'@(\w*)$').firstMatch(upToCursor);
    if (match == null) return;
    final mention = '${_handleOf(name)} ';
    final newText =
        text.replaceRange(match.start, cursor, mention) + text.substring(cursor);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: match.start + mention.length),
    );
    _setSuggestions(const []);
    _focus.requestFocus();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    final me = context.read<AuthService>().user?.name ?? 'You';

    // Clear the field up front — the comment is appended optimistically, and
    // CommentStore rolls it back if the POST fails.
    _controller.clear();
    _setSuggestions(const []);
    setState(() => _sending = true);
    try {
      await CommentStore.instance
          .send(widget.postId, text: text, author: me);
    } catch (e) {
      if (!mounted) return;
      _controller.text = text; // give the user their text back to retry
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not post comment: ${_message(e)}')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _message(Object e) =>
      e is ApiException ? e.message : 'check your connection';

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final available = mq.size.height - mq.padding.top - mq.viewInsets.bottom - 8;
    final height = (mq.size.height * 0.85).clamp(240.0, available);
    final me = context.watch<AuthService>().user;

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              // Grabber + title
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 10),
              Text('Comments', style: display(17, color: AppColors.forest900)),
              const SizedBox(height: 8),
              const Divider(height: 1, color: AppColors.border),

              // Comment list
              Expanded(
                child: ListenableBuilder(
                  listenable: CommentStore.instance,
                  builder: (context, _) {
                    final comments =
                        CommentStore.instance.commentsFor(widget.postId);
                    if (comments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.mode_comment_outlined,
                                size: 40, color: AppColors.hint),
                            const SizedBox(height: 10),
                            Text('No comments yet',
                                style: body(15,
                                    weight: FontWeight.w600,
                                    color: AppColors.label)),
                            const SizedBox(height: 4),
                            Text('Start the conversation.',
                                style: body(13, color: AppColors.hint)),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: comments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (_, i) => _CommentRow(comment: comments[i]),
                    );
                  },
                ),
              ),

              // @mention suggestions
              if (_suggestions.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (_, i) {
                      final name = _suggestions[i];
                      return ListTile(
                        dense: true,
                        leading: PexelsImage(url: '', name: name, size: 34),
                        title: Text(name,
                            style: body(13,
                                weight: FontWeight.w600,
                                color: AppColors.forest900)),
                        subtitle: Text(_handleOf(name),
                            style: body(11, color: AppColors.hint)),
                        onTap: () => _insertMention(name),
                      );
                    },
                  ),
                ),

              // Input row
              SafeArea(
                top: false,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(
                    children: [
                      PexelsImage(url: '', name: me?.name ?? 'You', size: 34),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focus,
                          onChanged: _onChanged,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 1,
                          maxLines: 4,
                          style: body(14, color: AppColors.ink),
                          decoration: InputDecoration(
                            hintText: 'Add a comment…  (type @ to tag)',
                            hintStyle: body(13, color: AppColors.hint),
                            isDense: true,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      // Send button — enabled only when there's text.
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _controller,
                        builder: (_, value, __) {
                          final enabled =
                              value.text.trim().isNotEmpty && !_sending;
                          return TextButton(
                            onPressed: enabled ? _send : null,
                            child: Text(_sending ? 'Posting…' : 'Post',
                                style: body(14,
                                    weight: FontWeight.w700,
                                    color: enabled
                                        ? AppColors.forest700
                                        : AppColors.hint)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.comment});
  final Comment comment;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PexelsImage(url: '', name: comment.author, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: '${comment.author}  ',
                    style: body(13,
                        weight: FontWeight.w700, color: AppColors.forest900),
                  ),
                  ..._withMentions(comment.text),
                ]),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(comment.time, style: body(11, color: AppColors.hint)),
                  if (comment.likeCount > 0) ...[
                    const SizedBox(width: 12),
                    Text(
                      '${comment.likeCount} like${comment.likeCount == 1 ? '' : 's'}',
                      style: body(11,
                          weight: FontWeight.w600, color: AppColors.hint),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // Liking needs the server id, so the heart is inert for the moment a
        // comment is still being posted.
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          iconSize: 16,
          icon: Icon(
            comment.likedByMe
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: comment.likedByMe
                ? const Color(0xFFE0245E)
                : AppColors.hint,
          ),
          onPressed: comment.id == null
              ? null
              : () async {
                  try {
                    await CommentStore.instance.toggleLike(comment);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Could not like: ${e is ApiException ? e.message : 'check your connection'}'),
                    ));
                  }
                },
        ),
      ],
    );
  }

  /// Splits a comment body, styling @mentions in forest green.
  List<TextSpan> _withMentions(String text) {
    final spans = <TextSpan>[];
    var last = 0;
    for (final m in _mentionRegExp.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(
            text: text.substring(last, m.start),
            style: body(13, color: AppColors.label)));
      }
      spans.add(TextSpan(
          text: m.group(0),
          style: body(13, weight: FontWeight.w600, color: AppColors.forest700)));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(
          text: text.substring(last), style: body(13, color: AppColors.label)));
    }
    return spans;
  }
}
