import 'package:flutter/foundation.dart';

import 'repository.dart';

/// A single comment on a post. Mentions are written inline as "@Name" tokens.
class Comment {
  Comment({
    required this.author,
    required this.text,
    this.time = 'Just now',
    this.id,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  final String author;
  final String text;
  final String time;

  /// Mongo `_id`. Null while a comment is still being posted (or on a
  /// local-only post) — liking needs a server id, so the heart waits for it.
  final String? id;

  int likeCount;
  bool likedByMe;

  /// From the API row: `{_id, userId: {userName, profileUrl}, content,
  /// createdAt, likeCount, likedByMe}`.
  factory Comment.fromApi(Map<String, dynamic> m) {
    final user = m['userId'];
    final name = (user is Map ? user['userName'] : null)?.toString() ?? '';
    return Comment(
      id: m['_id']?.toString(),
      author: name.trim().isEmpty ? 'Samaj Member' : name,
      text: (m['content'] ?? '').toString(),
      time: _ago(m['createdAt']?.toString()),
      likeCount: (m['likeCount'] as num?)?.toInt() ?? 0,
      likedByMe: m['likedByMe'] == true,
    );
  }
}

/// "3h ago", "Just now" — compact relative time from an ISO-8601 string.
String _ago(String? iso) {
  if (iso == null || iso.isEmpty) return 'Just now';
  final t = DateTime.tryParse(iso);
  if (t == null) return 'Just now';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${(d.inDays / 7).floor()}w ago';
}

/// Only backend posts have a Mongo ObjectId. Locally created posts (the ones
/// still uploading, and the demo cards) carry a client-side id the API would
/// reject with a 400, so those stay purely in-memory.
bool isBackendPostId(String id) =>
    RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id);

/// App-wide store of comments keyed by post id, backed by
/// `/api/posts/:postId/comments`. Server rows are loaded when a post's sheet
/// opens; new comments are POSTed to `/api/posts/comments` and appended
/// optimistically (newest last, Instagram-style).
class CommentStore extends ChangeNotifier {
  CommentStore._();
  static final CommentStore instance = CommentStore._();

  final _repo = Repository.instance;
  final Map<String, List<Comment>> _byPost = {};
  final Set<String> _loaded = {};

  List<Comment> commentsFor(String postId) =>
      List.unmodifiable(_byPost[postId] ?? const <Comment>[]);

  /// The count to render on the feed card. Falls back to the server's
  /// `commentCount` from the feed until this post's comments are loaded.
  int countFor(String postId, {int fallback = 0}) =>
      _byPost[postId]?.length ?? fallback;

  bool isLoaded(String postId) => _loaded.contains(postId);

  /// Fetches a post's comments once per session (pass [force] to refetch).
  /// Failures are swallowed: the sheet still opens and stays usable offline.
  Future<void> load(String postId, {bool force = false}) async {
    if (!isBackendPostId(postId)) return;
    if (_loaded.contains(postId) && !force) return;
    try {
      final rows = await _repo.postComments(postId);
      // The API returns newest first; the sheet reads oldest first.
      _byPost[postId] = rows.reversed.map(Comment.fromApi).toList();
      _loaded.add(postId);
      notifyListeners();
    } catch (_) {
      // Leave whatever is cached in place.
    }
  }

  /// Posts a comment to the API and appends it. Shows up immediately, and is
  /// rolled back if the request fails so the UI never shows a comment the
  /// server rejected. Throws so the caller can surface the error.
  Future<void> send(
    String postId, {
    required String text,
    required String author,
  }) async {
    final optimistic = Comment(author: author, text: text);
    _add(postId, optimistic);

    if (!isBackendPostId(postId)) return; // local-only post: nothing to sync

    try {
      final created = await _repo.addComment(postId: postId, text: text);
      final list = _byPost[postId];
      final i = list?.indexOf(optimistic) ?? -1;
      if (list != null && i >= 0) list[i] = Comment.fromApi(created);
      notifyListeners();
    } catch (e) {
      _byPost[postId]?.remove(optimistic);
      notifyListeners();
      rethrow;
    }
  }

  /// Toggles the caller's like on a comment via
  /// `POST /api/posts/comments/:commentId/likes`. Flips immediately and reverts
  /// if the server rejects it. Throws so the caller can show the reason.
  Future<void> toggleLike(Comment c) async {
    final id = c.id;
    if (id == null) return; // still posting — no server id to like yet

    final wasLiked = c.likedByMe;
    final wasCount = c.likeCount;
    c.likedByMe = !wasLiked;
    c.likeCount = wasCount + (wasLiked ? -1 : 1);
    notifyListeners();

    try {
      final res = await _repo.likeComment(id);
      c.likedByMe = res['liked'] == true;
      c.likeCount = (res['likeCount'] as num?)?.toInt() ?? c.likeCount;
      notifyListeners();
    } catch (e) {
      c.likedByMe = wasLiked;
      c.likeCount = wasCount;
      notifyListeners();
      rethrow;
    }
  }

  void _add(String postId, Comment c) {
    (_byPost[postId] ??= <Comment>[]).add(c);
    notifyListeners();
  }
}
