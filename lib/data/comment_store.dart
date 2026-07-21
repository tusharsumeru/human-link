import 'package:flutter/foundation.dart';

/// A single comment on a post. Mentions are written inline as "@Name" tokens.
class Comment {
  Comment({required this.author, required this.text, this.time = 'Just now'});
  final String author;
  final String text;
  final String time;
}

/// App-wide, in-memory store of comments keyed by post id. Comments the user
/// adds are appended live (newest last, Instagram-style). No demo seed data.
class CommentStore extends ChangeNotifier {
  CommentStore._();
  static final CommentStore instance = CommentStore._();

  final Map<String, List<Comment>> _byPost = {};

  List<Comment> commentsFor(String postId) =>
      List.unmodifiable(_byPost[postId] ?? const <Comment>[]);

  int countFor(String postId) => _byPost[postId]?.length ?? 0;

  void add(String postId, Comment c) {
    (_byPost[postId] ??= <Comment>[]).add(c);
    notifyListeners();
  }
}
