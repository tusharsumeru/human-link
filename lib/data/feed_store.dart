import 'package:flutter/foundation.dart';

/// A post/reel the user created this session. Held in memory only — there is no
/// feed backend yet, so uploads live until the app is restarted.
class UserPost {
  UserPost({
    required this.id,
    required this.author,
    required this.subtitle,
    required this.mediaPath,
    required this.caption,
    required this.isReel,
  });

  final String id; // stable id used to key comments
  final String author;
  final String subtitle;
  final String mediaPath; // local file path (image, or video when isReel)
  final String caption;
  final bool isReel; // true → a video reel; false → a photo post
}

/// Global, app-wide store of user-created feed items. The Dashboard listens to
/// it so a new post/reel appears the moment it's uploaded from the bottom bar.
class FeedStore extends ChangeNotifier {
  FeedStore._();
  static final FeedStore instance = FeedStore._();

  final List<UserPost> _posts = <UserPost>[];
  int _seq = 0;
  List<UserPost> get posts => List.unmodifiable(_posts);

  /// Next stable id for a new upload (e.g. "user-1").
  String nextId() => 'user-${++_seq}';

  void add(UserPost post) {
    _posts.insert(0, post); // newest first
    notifyListeners();
  }
}
