import 'package:flutter/foundation.dart';

import 'repository.dart';

/// A post/reel the user created this session.
///
/// Shown immediately from its local file while the upload runs, so the feed
/// reacts instantly. Once `POST /api/posts` returns, [remoteId] holds the real
/// Mongo id — that's what likes and comments are keyed on, and what dedupes
/// this card against the same post arriving from the backend feed.
class UserPost {
  UserPost({
    required this.id,
    required this.author,
    required this.subtitle,
    required this.mediaPath,
    required this.caption,
    required this.isReel,
    this.remoteId,
    this.uploading = false,
    this.failed = false,
  });

  final String id; // local id, stable for the session
  final String author;
  final String subtitle;
  final String mediaPath; // local file path (image, or video when isReel)
  final String caption;
  final bool isReel; // true → a video reel; false → a photo post

  String? remoteId; // Mongo _id once the upload succeeds
  bool uploading;
  bool failed;

  /// The id to use for like/comment calls — the server id when we have it.
  String get feedId => remoteId ?? id;
}

/// Global, app-wide store of user-created feed items. The Dashboard listens to
/// it so a new post/reel appears the moment it's picked, and updates again when
/// the upload lands.
class FeedStore extends ChangeNotifier {
  FeedStore._();
  static final FeedStore instance = FeedStore._();

  final _repo = Repository.instance;
  final List<UserPost> _posts = <UserPost>[];
  int _seq = 0;
  List<UserPost> get posts => List.unmodifiable(_posts);

  /// Server ids of posts already shown from this store, so the dashboard can
  /// drop the duplicate copy that comes back in the backend feed.
  Set<String> get remoteIds =>
      _posts.map((p) => p.remoteId).whereType<String>().toSet();

  /// Next stable id for a new upload (e.g. "user-1").
  String nextId() => 'user-${++_seq}';

  void add(UserPost post) {
    _posts.insert(0, post); // newest first
    notifyListeners();
  }

  /// Uploads to `POST /api/posts` (multipart: the media file + caption).
  /// The card appears straight away and flips out of its "Uploading…" state
  /// when the server responds. Throws on failure so the caller can show the
  /// reason; the card stays put, marked failed, so nothing is silently lost.
  Future<void> upload({
    required String mediaPath,
    required String caption,
    required bool isReel,
    required String author,
    required String subtitle,
    List<String> hashtags = const [],
    List<String> taggedUsers = const [],
  }) async {
    final post = UserPost(
      id: nextId(),
      author: author,
      subtitle: subtitle,
      mediaPath: mediaPath,
      caption: caption,
      isReel: isReel,
      uploading: true,
    );
    add(post);

    try {
      final created = await _repo.createPost(
        filePath: mediaPath,
        caption: caption,
        hashtags: hashtags,
        taggedUsers: taggedUsers,
      );
      post.remoteId = (created['_id'] ?? created['id'])?.toString();
      post.uploading = false;
      post.failed = false;
      notifyListeners();
    } catch (e) {
      post.uploading = false;
      post.failed = true;
      notifyListeners();
      rethrow;
    }
  }

  /// Retries a failed upload in place.
  Future<void> retry(UserPost post) async {
    post.failed = false;
    post.uploading = true;
    notifyListeners();
    try {
      final created = await _repo.createPost(
        filePath: post.mediaPath,
        caption: post.caption,
      );
      post.remoteId = (created['_id'] ?? created['id'])?.toString();
      post.uploading = false;
      notifyListeners();
    } catch (e) {
      post.uploading = false;
      post.failed = true;
      notifyListeners();
      rethrow;
    }
  }

  void remove(UserPost post) {
    _posts.remove(post);
    notifyListeners();
  }
}
